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
import cjoy.mcp.schema.*
import cjoy.mcp.common.*
import cjoy.log.LogTool
import cjoy.framework.JoyContext

class McpServerSessionState {
    private let _counter: SyncCounter = SyncCounter(1)

    public McpServerSessionState(let sessionId: String) {}

    public func waitEnd() {
        _counter.waitUntilZero()
        LogTool.info("[MCP]server sesion is end, sessionId:${sessionId}")
    }

    public func compete(): Unit {
        _counter.dec()
    }
}

public class DefaultMcpServerSession <: McpServerSession & McpRequestHandler & McpNotificationHandler {
    private let _state: McpServerSessionState
    private let _transport: McpTransport
    private var _isClosed: Bool = false
    private let _notificationConsumer: ConcurrentHashMap<String, (Array<Byte>) -> Unit> = ConcurrentHashMap()

    init(state: McpServerSessionState, transport: McpTransport) {
        this._state = state
        this._transport = transport
    }

    public func handle(ctx: JoyContext, message: JSONRPCMessage): Unit {
        match (message) {
            case m: JSONRPCRequest => onRequest(ctx, m)
            case m: JSONRPCNotification => onNotification(m)
            case _ => LogTool.info("[MCP]server recv unknown message, sessionId:${_state.sessionId}")
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
        LogTool.info("[MCP]send notification, method:${method}, sessionId:${_state.sessionId}")
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

    public func onRequest(ctx: JoyContext, message: JSONRPCRequest): Unit {
        let resp = match (message.method) {
            case "ping" =>
                LogTool.info("[MCP]recv `ping` request")
                JSONRPCResponse(id: message.id, result: message.params)
            case "initialize" =>
                let request: InitializeRequest = RPCJsonTool.deserializeParams(message.params)
                LogTool.info("[MCP]recv `initialize` request: ${request}, sessionId: ${_state.sessionId}")
                let result = onRecvInitRequest(request)
                JSONRPCResponse(id: message.id, result: result)
            case "tools/list" =>
                let page: PaginatedRequest = RPCJsonTool.deserializeParams(message.params)
                LogTool.info("[MCP]recv `tools/list` request: ${page}, sessionId: ${_state.sessionId}")
                let result = McpServer.listTools(page)
                JSONRPCResponse(id: message.id, result: result)
            case "tools/call" =>
                let req: CallToolRequest = RPCJsonTool.deserializeParams(message.params)
                LogTool.debug("[MCP]recv `tools/call` request: ${req}, sessionId: ${_state.sessionId}")
                let result = McpServer.callTool(ctx, req)
                JSONRPCResponse(id: message.id, result: result)
            case _ =>
                LogTool.error("[MCP]recv unknown `${message.method}` request, sessionId: ${_state.sessionId}")
                let error = JSONRPCError(code: McpConsts.ERR_METHOD_NOT_FOUND, message: "not found method")
                JSONRPCResponse(id: message.id, error: error)
        }
        let data = RPCJsonTool.serialize(resp)
        LogTool.debug("[MCP]send reponse: ${String.fromUtf8(data.bytes())}, sessionId: ${_state.sessionId}")
        _transport.send(data)
    }

    private func onRecvInitRequest(request: InitializeRequest): InitializeResult {
        // TODO check the request params
        McpServer.exchangeInit()      
    }

    public func close() {
        if (_isClosed) {
            return
        }
        _state.compete()
        _isClosed = true
    }

    public func isClosed(): Bool {
        _isClosed
    }
}