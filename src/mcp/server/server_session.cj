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
 * 会话信息结构，用于防止会话劫持
 */
class SessionInfo {
    let session: McpServerSession
    let userID: String

    /**
     * 初始化会话信息
     */
    init(session: McpServerSession, userID: String) {
        this.session = session
        this.userID = userID
    }
}

/**
 * Session state manager for MCP server
 *
 * Tracks the state of an MCP session, managing session lifecycle and
 * synchronization between SSE transport and session closure.
 */
class McpServerSessionState {
    private let _counter: SyncCounter = SyncCounter(1)
    private var _streamCompleted: Bool = false
    private let _streamCompletionHandlers: ArrayList<() -> Unit> = ArrayList()

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

    /**
     * Marks the stream as completed
     */
    public func markStreamCompleted(): Unit {
        _streamCompleted = true
        @JoyLogDebug("[MCP] stream completed, sessionId: ${sessionId}")
        // 通知所有流完成处理程序
        var i = 0
        while (i < _streamCompletionHandlers.size) {
            let handler = _streamCompletionHandlers[i]
            handler()
            i += 1
        }
    }

    /**
     * Checks if the stream is completed
     */
    public func isStreamCompleted(): Bool {
        _streamCompleted
    }

    /**
     * Adds a stream completion handler
     */
    public func addStreamCompletionHandler(handler: () -> Unit): Unit {
        _streamCompletionHandlers.add(handler)
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
    private let _eventStore: ?EventStore

    /**
     * Keepalive interval in milliseconds
     */
    private var _keepaliveIntervalMs: Int64 = 0

    /**
     * Keepalive timeout in milliseconds
     */
    private var _keepaliveTimeoutMs: Int64 = 0

    /**
     * Last time a ping was sent
     */
    private var _lastPingTime: Int64 = 0

    /**
     * Flag indicating if a ping response was received
     */
    private var _pingResponseReceived: Bool = true

    /**
     * Timer for sending ping messages
     */
    private var _keepaliveTimer: ?Any = None

    public prop sessionId: String {
        get() {
            return _sessionId
        }
    }

    /**
     * Marks the stream as completed
     */
    public func markStreamCompleted(): Unit {
        // 这里可以添加流完成时的逻辑，例如清理资源、关闭连接等
        @JoyLogInfo("[MCP] Stream completed, sessionId: ${_sessionId}")
        // 标记会话状态为流完成
        // 如果使用 McpServerSessionState，可以在这里调用其方法
        // 例如：_state.markStreamCompleted()
        // 同时，可以通知所有流完成处理程序
        close()
    }

    /**
     * Checks if the stream is completed
     */
    public func isStreamCompleted(): Bool {
        // 这里可以添加检查流是否已完成的逻辑
        // 如果使用 McpServerSessionState，可以在这里调用其方法
        // 例如：_state.isStreamCompleted() 
        _isClosed
    }

    /**
     * Adds a stream completion handler
     */
    public func addStreamCompletionHandler(handler: () -> Unit): Unit {
        // 这里可以添加流完成处理程序的逻辑
        // 如果使用 McpServerSessionState，可以在这里调用其方法
        // 例如：_state.addStreamCompletionHandler(handler)
    }

    /**
     * Initializes a new DefaultMcpServerSession
     *
     * @param sessionId The unique session identifier
     * @param transport The MCP transport to use
     * @param isJsonResp Whether to send JSON responses directly instead of via transport
     * @param streamable Whether this is a streamable session
     * @param eventStore Optional event store for persisting events (default: None)
     */
    init(sessionId: String, transport: McpTransport, isJsonResp: Bool, streamable: Bool, eventStore!: ?EventStore = None) {
        _sessionId = sessionId
        _transport = transport
        _isJsonResp = isJsonResp
        _streamable = streamable
        _eventStore = eventStore

        // Open default event stream when event store is available
        if (let Some(store) <- eventStore) {
            let streamId = "default" // TODO: support multiple streams per session
            store.open(_sessionId, streamId)
            @JoyLogDebug("[MCP] opened event stream, streamId: ${streamId}, sessionId: ${_sessionId}")
        }
    }

    /**
     * Creates a dummy JoyContext instance for use when no real context is available
     *
     * @return A dummy JoyContext instance
     */
    private func _dummyContext(): JoyContext {
        // 在实际代码中，我们应该使用一个更简单的方法来获取或创建上下文
        // 这里我们抛出异常，因为我们不应该在没有上下文的情况下调用event store方法
        throw Exception("No JoyContext available")
    }

    /**
     * Stores an event for retrieval
     *
     * @param data The event data to store
     * @return The unique event identifier
     */
    /**
     * Formats an event ID using <streamID>_<index> format
     *
     * @param streamId The stream identifier
     * @param index The event index in the stream
     * @return Formatted event ID string
     */
    private func formatEventId(streamId: String, index: Int64): String {
        "${streamId}_${index}"
    }

    /**
     * Parses an event ID in <streamID>_<index> format
     *
     * @param eventId The event ID to parse
     * @return Tuple containing (streamId, index) if parsing succeeds, otherwise (None, None)
     */
    private func parseEventId(eventId: String): (?String, ?Int64) {
        let parts = eventId.split("_")
        if (parts.size != 2) {
            @JoyLogDebug("[MCP] invalid eventId format: ${eventId}")
            return (None, None)
        }
        let streamId = parts[0]
        let indexStr = parts[1]
        let parsedIndex = Int64.tryParse(indexStr)
        if (let Some(index) <- parsedIndex) {
            if (index >= 0) {
                (Some(streamId), Some(index))
            } else {
                @JoyLogDebug("[MCP] invalid eventId index: ${indexStr}")
                (None, None)
            }
        } else {
            @JoyLogDebug("[MCP] invalid eventId index: ${indexStr}")
            (None, None)
        }
    }

    /**
     * Stores an event for retrieval
     *
     * @param data The event data to store
     * @return The unique event identifier in <streamID>_<index> format
     */
    public func storeEvent(data: ByteBuffer, ctx!: ?JoyContext = None): String {
        let streamId = "default" // TODO: support multiple streams per session
        let eventId = match (_eventStore) {
            case Some(eventStore) =>
                // Get current event count to determine index
                let currentCount = eventStore.getEventCount(_sessionId, streamId)
                let newIndex = currentCount
                eventStore.append(_sessionId, streamId, data)
                formatEventId(streamId, newIndex)
            case None =>
                _eventIdCounter += 1
                let newIndex = _eventIdCounter - 1
                let formattedId = formatEventId(streamId, newIndex)
                _events.add((formattedId, data))
                formattedId
        }

        @JoyLogDebug("[MCP] stored event, eventId: ${eventId}, sessionId: ${_sessionId}")
        return eventId
    }

    /**
     * Retrieves all events after a specific event ID
     *
     * @param lastEventId The last event ID to use as a starting point
     * @return List of events with their IDs and data
     */
    public func retrieveEvents(lastEventId: String, ctx!: ?JoyContext = None): ArrayList<(String, ByteBuffer)> {
        // If event store is available, use it for event retrieval
        if (let Some(eventStore) <- _eventStore) {
            let streamId = "default" // TODO: support multiple streams per session

            // Parse event ID to get last index
            let (_, lastIndex) = parseEventId(lastEventId)
            let index = lastIndex ?? -1
            var events = ArrayList<(String, ByteBuffer)>()

            let iterator = eventStore.after(_sessionId, streamId, index)
            while (let Some(next) <- iterator.next()) {
                let event = (formatEventId(streamId, next[0]), next[1])
                events.add(event)
            }

            @JoyLogDebug("[MCP] retrieved ${events.size} events from event store after eventId: ${lastEventId}, sessionId: ${_sessionId}")
            return events
        }

        // Fallback to in-memory storage
        let events = ArrayList<(String, ByteBuffer)>()
        let (_, lastIndex) = parseEventId(lastEventId)
        let id = lastIndex ?? -1
        var i = 0
        while (i < _events.size) {
            let (eventId, data) = _events[i]
            let (_, eventIntId) = parseEventId(eventId)
            if (let Some(intId) <- eventIntId && intId > id) {
                events.add((eventId, data))
            }
            i += 1
        }
        @JoyLogDebug("[MCP] retrieved ${events.size} events from memory after eventId: ${lastEventId}, sessionId: ${_sessionId}")
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
        if (let Some(store) <- _eventStore) {
            let streamId = "default"
            store.sessionClosed(_sessionId)
            @JoyLogDebug("[MCP] close event stream, streamId: ${streamId}, sessionId: ${_sessionId}")
        }
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
        let data = JSONRPCTool.serialize(message)
        storeEvent(data)
        _transport.send(data)
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
        _notificationConsumer.get(message.method).map({
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
        try {
            let result: Any = match (message.method) {
                case "ping" =>
                    @JoyLogInfo("[MCP] recv `ping` request")
                    "pong"
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
        } catch (e: JSONRPCException) {
            let resp = JSONRPCResponse(id: message.id, error: e.error)
            sendResp(ctx, resp, jsonResp)
        } catch (e: Exception) {
            let error = JSONRPCError(code: JSONRPCConsts.ERR_INTERNAL_ERROR, message: e.message)
            let resp = JSONRPCResponse(id: message.id, error: error)
            sendResp(ctx, resp, jsonResp)
        }
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
            storeEvent(data)
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
        // Protocol version negotiation
        let negotiatedVersion = negotiateProtocolVersion(request.protocolVersion)
        let result = McpServer.exchangeInit()
        result.protocolVersion = negotiatedVersion
        @JoyLogInfo("[MCP] protocol version negotiated")
        result
    }

    /**
     * Negotiates the protocol version based on client request and server support
     *
     * @param clientVersion The protocol version requested by the client
     * @return The negotiated protocol version
     */
    private func negotiateProtocolVersion(clientVersion: String): String {
        // Check if client version is supported
        if (McpConsts.supportedProtocolVersions().contains(clientVersion)) {
            return clientVersion
        }

        // If client version is not supported, return latest supported version
        @JoyLogWarn("[MCP] client requested unsupported protocol version")
        return McpConsts.LASTEST_PROTOCOL_VERSION
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
