/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.mcp.server

import std.collection.concurrent.ConcurrentHashMap
import std.collection.ArrayList
import std.io.ByteBuffer
import std.sync.SyncCounter
import std.convert.Parsable
import stdx.encoding.json.stream.{JsonDeserializable, JsonSerializable}
import cjoy.mcp.api.*
import cjoy.jsonrpc.{JSONRPCRequest, JSONRPCResponse, JSONRPCMessage, JSONRPCTool, JSONRPCError, JSONRPCConsts,
    JSONRPCException, JSONRPCNotification}
import cjoy.log.macros.*
import cjoy.json.JsonTool
import cjoy.framework.{JoyContext, JoySseEmitter}

/**
 * Session state manager for MCP server
 *
 * Tracks the state of an MCP session, managing session lifecycle and
 * synchronization between SSE transport and session closure.
 */
class McpServerSessionState {
    private let _counter: SyncCounter = SyncCounter(1)

    /**
     * Initializes a new McpServerSessionState
     *
     * @param sessionId The unique session identifier
     * @param sseEmitter The SSE emitter for this session
     */
    public McpServerSessionState(let sessionId: String, let sseEmitter: JoySseEmitter) {}

    /**
     * Waits for the session to end and closes the SSE connection
     */
    public func waitEnd(): Unit {
        @JoyLogInfo("[MCP] waiting sse transport end, sessionId=${sessionId}")
        _counter.waitUntilZero()
        @JoyLogInfo("[MCP] server SSE transport is end, sessionId: ${sessionId}")
        sseEmitter.end()
    }

    /**
     * Completes a session by decrementing the counter
     */
    public func compete(): Unit {
        _counter.dec()
    }
}

/**
 * Default implementation of MCP server session
 *
 * Handles all MCP session operations including request handling,
 * response sending, notification processing, and event management.
 */
class DefaultMcpServerSession <: McpServerSession & McpRequestHandler & McpResponseHandler & McpNotificationHandler {
    let _sessionId: String
    var _transport: McpTransport
    private var _isClosed: Bool = false
    private var _isJsonResp: Bool = false
    private let _streamable: Bool
    private let _notificationConsumer: ConcurrentHashMap<String, (Array<Byte>) -> Unit> = ConcurrentHashMap()
    private var _events: ArrayList<(String, ByteBuffer)> = ArrayList()
    private var _eventIdCounter: Int64 = 0

    /**
     * Initializes a new DefaultMcpServerSession
     *
     * @param sessionId The unique session identifier
     * @param transport The MCP transport to use
     * @param isJsonResp Whether to send JSON responses directly instead of via transport
     * @param streamable Whether this is a streamable session
     */
    init(sessionId: String, transport: McpTransport, isJsonResp: Bool, streamable: Bool) {
        _sessionId = sessionId
        _transport = transport
        _isJsonResp = isJsonResp
        _streamable = streamable
    }

    /**
     * Stores an event for retrieval
     *
     * @param data The event data to store
     * @return The unique event identifier
     */
    public func storeEvent(data: ByteBuffer): String {
        _eventIdCounter += 1
        let eventId = "${_eventIdCounter}"
        _events.add((eventId, data))
        @JoyLogDebug("[MCP] stored event, eventId: ${eventId}, sessionId: ${_sessionId}")
        return eventId
    }

    /**
     * Retrieves all events after a specific event ID
     *
     * @param lastEventId The last event ID to use as a starting point
     * @return List of events with their IDs and data
     */
    public func retrieveEvents(lastEventId: String): ArrayList<(String, ByteBuffer)> {
        let events = ArrayList<(String, ByteBuffer)>()
        let id = Int.tryParse(lastEventId) ?? 0
        var i = 0
        while (i < _events.size) {
            let (eventId, data) = _events[i]
            let eventIntId = Int.tryParse(eventId) ?? 0
            if (eventIntId > id) {
                events.add((eventId, data))
            }
            i += 1
        }
        @JoyLogDebug("[MCP] retrieved ${events.size} events after eventId: ${lastEventId}, sessionId: ${_sessionId}")
        return events
    }

    /**
     * Cleans up old events to prevent memory overflow
     *
     * @param maxEvents Maximum number of events to keep
     */
    public func cleanUpEvents(maxEvents!: Int): Unit {
        if (_events.size > maxEvents) {
            let keepCount = maxEvents
            let newEvents = ArrayList<(String, ByteBuffer)>()
            var i = _events.size - keepCount
            while (i < _events.size) {
                newEvents.add(_events[i])
                i += 1
            }
            _events = newEvents
            @JoyLogDebug("[MCP] cleaned up events, sessionId: ${_sessionId}")
        }
    }

    /**
     * Updates the transport for this session
     *
     * @param transport The new transport to use
     */
    func updateTransport(transport: McpTransport): Unit {
        _transport.close()
        _transport = transport
        @JoyLogInfo("[MCP] update SSE transport, sessionId=${_sessionId}")
    }

    /**
     * Closes the current transport
     */
    func closeTransport(): Unit {
        @JoyLogInfo("[MCP] close SSE transport, sessionId=${_sessionId}")
        _transport.close()
    }

    /**
     * Handles incoming JSON-RPC messages
     *
     * @param ctx The JoyContext for the request
     * @param message The JSON-RPC message to handle
     */
    public func handle(ctx: JoyContext, message: JSONRPCMessage): Unit {
        match (message) {
            case m: JSONRPCRequest => onRequest(ctx, m)
            case m: JSONRPCNotification => onNotification(m)
            case m: JSONRPCResponse => onResponse(m)
            case _ => @JoyLogInfo("[MCP] server recv unknown message, sessionId: ${_sessionId}")
        }
    }

    /**
     * Sends a JSON-RPC request (not supported by server sessions)
     *
     * @param method The method name
     * @param requestParams The request parameters
     * @return The response of type T
     * @throws UnsupportedException Always thrown as server sessions don't support outgoing requests
     */
    public func sendRequest<T>(_: String, _: JsonSerializable): T where T <: JsonDeserializable<T> {
        throw UnsupportedException("unsupported this method")
    }

    /**
     * Sends a JSON-RPC notification
     *
     * @param method The notification method name
     * @param params The notification parameters (optional)
     */
    public func sendNotification(method: String, params: ?JsonSerializable): Unit {
        let message = if (let Some(v) <- params) {
            JSONRPCNotification(method: method, params: params)
        } else {
            JSONRPCNotification(method: method)
        }
        _transport.send(JSONRPCTool.serialize(message))
        @JoyLogInfo("[MCP] send notification, method: ${method}, sessionId: ${_sessionId}")
    }

    /**
     * Adds a notification consumer for a specific method
     *
     * @param method The notification method name
     * @param consumer The consumer function to handle notification bytes
     */
    public func addNotificationConsumer(method: String, consumer: (Array<Byte>) -> Unit): Unit {
        _notificationConsumer.add(method, consumer)
    }

    /**
     * Handles incoming JSON-RPC notifications
     *
     * @param message The JSON-RPC notification to handle
     */
    public func onNotification(message: JSONRPCNotification): Unit {
        _notificationConsumer
            .get(message.method)
            .map({
                consumer: (Array<Byte>) -> Unit => consumer((message.params as Array<Byte>) ?? Array<Byte>())
            })
    }

    /**
     * Handles incoming JSON-RPC responses (default implementation does nothing)
     *
     * @param message The JSON-RPC response to handle
     */
    public func onResponse(_: JSONRPCResponse): Unit {
    }

    /**
     * Handles incoming JSON-RPC requests
     *
     * @param ctx The JoyContext for the request
     * @param message The JSON-RPC request to handle
     */
    public func onRequest(ctx: JoyContext, message: JSONRPCRequest): Unit {
        var jsonResp: Bool = false
        let result = match (message.method) {
            case "ping" =>
                @JoyLogInfo("[MCP] recv `ping` request")
                message.params
            case "initialize" =>
                let request: InitializeRequest = JSONRPCTool.deserializeParams(message.params)
                @JoyLogInfo("[MCP] recv `initialize` request: ${request}, sessionId: ${_sessionId}")
                jsonResp = _streamable
                onRecvInitRequest(request)
            case "tools/list" =>
                let page: PaginatedRequest = JSONRPCTool.deserializeParams(message.params)
                @JoyLogInfo("[MCP] recv `tools/list` request: ${page}, sessionId: ${_sessionId}")
                McpServer.TOOLS.listTools(page)
            case "tools/call" =>
                let req: CallToolRequest = JSONRPCTool.deserializeParams(message.params)
                @JoyLogDebug("[MCP] recv `tools/call` request: ${req}, sessionId: ${_sessionId}")
                McpServer.TOOLS.callTool(ctx, req)
            case "resources/list" =>
                let page: PaginatedRequest = JSONRPCTool.deserializeParams(message.params)
                @JoyLogInfo("[MCP] recv `resources/list` request: ${page}, sessionId: ${_sessionId}")
                McpServer.RESOURCES.listResources(page)
            case "resources/templates/list" =>
                let page: PaginatedRequest = JSONRPCTool.deserializeParams(message.params)
                @JoyLogInfo("[MCP] recv `resources/templates/list` request: ${page}, sessionId: ${_sessionId}")
                McpServer.RESOURCES.listResourceTemplates(page)
            case "resources/read" =>
                let req: ReadResourceRequest = JSONRPCTool.deserializeParams(message.params)
                @JoyLogDebug("[MCP] recv `resources/read` request: ${req}, sessionId: ${_sessionId}")
                McpServer.RESOURCES.readResource(ctx, req)
            case "prompts/list" =>
                let page: PaginatedRequest = JSONRPCTool.deserializeParams(message.params)
                @JoyLogInfo("[MCP] recv `prompts/list` request: ${page}, sessionId: ${_sessionId}")
                McpServer.PROMPTS.listPrompt(page)
            case "prompts/get" =>
                let req: GetPromptRequest = JSONRPCTool.deserializeParams(message.params)
                @JoyLogDebug("[MCP] recv `prompts/get` request: ${req}, sessionId: ${_sessionId}")
                McpServer.PROMPTS.getPrompt(ctx, req)
            case _ =>
                @JoyLogError("[MCP] recv unknown `${message.method}` request, sessionId: ${_sessionId}")
                let error = JSONRPCError(code: JSONRPCConsts.ERR_METHOD_NOT_FOUND, message: "not found method")
                let resp = JSONRPCResponse(id: message.id, error: error)
                return sendResp(ctx, resp, false)
        }
        let resp = JSONRPCResponse(id: message.id, result: result)
        sendResp(ctx, resp, jsonResp)
    }

    /**
     * Sends a JSON-RPC response
     *
     * @param ctx The JoyContext for the response
     * @param resp The JSON-RPC response to send
     * @param jsonResp Whether to send the response as JSON directly or via transport
     */
    private func sendResp(ctx: JoyContext, resp: JSONRPCResponse, jsonResp: Bool): Unit {
        if (_isJsonResp || jsonResp) {
            ctx.header(McpConsts.HEADER_MCP_SESSION_ID, _sessionId).json(resp)
            @JoyLogDebug("[MCP] send json response: ${JsonTool.toJson(resp)}, sessionId: ${_sessionId}")
        } else {
            let data = JSONRPCTool.serialize(resp)
            _transport.send(data)
        }
    }

    /**
     * Handles initialization requests
     *
     * @param request The InitializeRequest
     * @return The InitializeResult
     */
    private func onRecvInitRequest(request: InitializeRequest): InitializeResult {
        // TODO check the request params
        McpServer.exchangeInit()
    }

    /**
     * Closes the session
     */
    public func close(): Unit {
        if (_isClosed) {
            return
        }
        _transport.close()
        _isClosed = true
    }

    /**
     * Checks if the session is closed
     *
     * @return True if the session is closed, false otherwise
     */
    public func isClosed(): Bool {
        _isClosed
    }
}
