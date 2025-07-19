/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.mcp.server

import std.collection.concurrent.ConcurrentHashMap
import std.sync.SyncCounter
import std.io.ByteBuffer
import stdx.encoding.json.stream.{JsonDeserializable, JsonSerializable, JsonReader}
import cjoy.mcp.api.*
import cjoy.log.LogTool
import cjoy.json.JsonTool
import cjoy.framework.{JoyContext, JoySseEmitter}

class McpServerSessionState {
    private let _counter: SyncCounter = SyncCounter(1)

    public McpServerSessionState(let sessionId: String, let sseEmitter: JoySseEmitter) {}

    public func waitEnd() {
        LogTool.info("[MCP] waiting sse transport end, sessionId=${sessionId}")
        _counter.waitUntilZero()
        LogTool.info("[MCP] server SSE transport is end, sessionId: ${sessionId}")
        sseEmitter.end()
    }

    public func compete(): Unit {
        _counter.dec()
    }
}

class DefaultMcpServerSession <: McpServerSession & McpRequestHandler & McpResponseHandler & McpNotificationHandler {
    let _sessionId: String
    var _transport: McpTransport
    private var _isClosed: Bool = false
    private var _isJsonResp: Bool = false
    private let _streamable: Bool
    private let _notificationConsumer: ConcurrentHashMap<String, (Array<Byte>) -> Unit> = ConcurrentHashMap()

    init(sessionId: String, transport: McpTransport, isJsonResp: Bool, streamable: Bool) {
        _sessionId = sessionId
        _transport = transport
        _isJsonResp = isJsonResp
        _streamable = streamable
    }

    func updateTransport(transport: McpTransport): Unit {
        _transport.close()
        _transport = transport
        LogTool.info("[MCP] update SSE transport, sessionId=${_sessionId}")
    }

    func closeTransport(): Unit {
        LogTool.info("[MCP] close SSE transport, sessionId=${_sessionId}")
        _transport.close()
    }

    public func handle(ctx: JoyContext, message: JSONRPCMessage): Unit {
        match (message) {
            case m: JSONRPCRequest => onRequest(ctx, m)
            case m: JSONRPCNotification => onNotification(m)
            case m: JSONRPCResponse => onResponse(m)
            case _ => LogTool.info("[MCP] server recv unknown message, sessionId: ${_sessionId}")
        }
    }

    public func sendRequest<T>(method: String, requestParams: JsonSerializable): T where T <: JsonDeserializable<T> {
        throw UnsupportedException("unsupported this method")
    }

    public func sendNotification(method: String, params: ?JsonSerializable): Unit {
        let message = if (let Some(v) <- params) {
            JSONRPCNotification(method: method, params: params)
        } else {
            JSONRPCNotification(method: method)
        }
        _transport.send(RPCJsonTool.serialize(message))
        LogTool.info("[MCP] send notification, method: ${method}, sessionId: ${_sessionId}")
    }

    public func addNotificationConsumer(method: String, consumer: (Array<Byte>) -> Unit): Unit {
        _notificationConsumer.add(method, consumer)
    }

    public func onNotification(message: JSONRPCNotification): Unit {
        _notificationConsumer
            .get(message.method)
            .map({
                consumer: (Array<Byte>) -> Unit => consumer((message.params as Array<Byte>) ?? Array<Byte>())
            })
    }

    public func onResponse(message: JSONRPCResponse): Unit {
    }

    public func onRequest(ctx: JoyContext, message: JSONRPCRequest): Unit {
        var jsonResp: Bool = false
        let result = match (message.method) {
            case "ping" =>
                LogTool.info("[MCP] recv `ping` request")
                message.params
            case "initialize" =>
                let request: InitializeRequest = RPCJsonTool.deserializeParams(message.params)
                LogTool.info("[MCP] recv `initialize` request: ${request}, sessionId: ${_sessionId}")
                jsonResp = _streamable
                onRecvInitRequest(request)
            case "tools/list" =>
                let page: PaginatedRequest = RPCJsonTool.deserializeParams(message.params)
                LogTool.info("[MCP] recv `tools/list` request: ${page}, sessionId: ${_sessionId}")
                McpServer.tools.listTools(page)
            case "tools/call" =>
                let req: CallToolRequest = RPCJsonTool.deserializeParams(message.params)
                LogTool.debug("[MCP] recv `tools/call` request: ${req}, sessionId: ${_sessionId}")
                McpServer.tools.callTool(ctx, req)
            case "resources/list" =>
                let page: PaginatedRequest = RPCJsonTool.deserializeParams(message.params)
                LogTool.info("[MCP] recv `resources/list` request: ${page}, sessionId: ${_sessionId}")
                McpServer.resources.listResources(page)
            case "resources/templates/list" =>
                let page: PaginatedRequest = RPCJsonTool.deserializeParams(message.params)
                LogTool.info("[MCP] recv `resources/templates/list` request: ${page}, sessionId: ${_sessionId}")
                McpServer.resources.listResourceTemplates(page)
            case "resources/read" =>
                let req: ReadResourceRequest = RPCJsonTool.deserializeParams(message.params)
                LogTool.debug("[MCP] recv `resources/read` request: ${req}, sessionId: ${_sessionId}")
                McpServer.resources.readResource(ctx, req)
            case "prompts/list" =>
                let page: PaginatedRequest = RPCJsonTool.deserializeParams(message.params)
                LogTool.info("[MCP] recv `prompts/list` request: ${page}, sessionId: ${_sessionId}")
                McpServer.prompts.listPrompt(page)
            case "prompts/get" =>
                let req: GetPromptRequest = RPCJsonTool.deserializeParams(message.params)
                LogTool.debug("[MCP] recv `prompts/get` request: ${req}, sessionId: ${_sessionId}")
                McpServer.prompts.getPrompt(ctx, req)
            case _ =>
                LogTool.error("[MCP] recv unknown `${message.method}` request, sessionId: ${_sessionId}")
                let error = JSONRPCError(code: McpConsts.ERR_METHOD_NOT_FOUND, message: "not found method")
                let resp = JSONRPCResponse(id: message.id, error: error)
                return sendResp(ctx, resp, false)
        }
        let resp = JSONRPCResponse(id: message.id, result: result)
        sendResp(ctx, resp, jsonResp)
    }

    private func sendResp(ctx: JoyContext, resp: JSONRPCResponse, jsonResp: Bool): Unit {
        if (_isJsonResp || jsonResp) {
            ctx.header(McpConsts.HEADER_MCP_SESSION_ID, _sessionId).json(resp)
            LogTool.debug("[MCP] send json reponse: ${JsonTool.toJson(resp)}, sessionId: ${_sessionId}")
        } else {
            let data = RPCJsonTool.serialize(resp)
            _transport.send(data)
        }
    }

    private func onRecvInitRequest(request: InitializeRequest): InitializeResult {
        // TODO check the request params
        McpServer.exchangeInit()
    }

    public func close() {
        if (_isClosed) {
            return
        }
        _transport.close()
        _isClosed = true
    }

    public func isClosed(): Bool {
        _isClosed
    }
}
