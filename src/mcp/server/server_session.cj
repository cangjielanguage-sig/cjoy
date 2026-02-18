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
 * MCP 服务器的会话状态管理器
 *
 * 跟踪 MCP 会话的状态，管理会话生命周期和 SSE 传输与会话关闭之间的同步。
 */
class McpServerSessionState {
    private let _counter: SyncCounter = SyncCounter(1)
    private var _streamCompleted: Bool = false
    private let _streamCompletionHandlers: ArrayList<() -> Unit> = ArrayList()

    /**
     * 初始化新的 McpServerSessionState
     *
     * @param sessionId 唯一的会话标识符
     * @param sseEmitter 此会话的 SSE 发射器
     */
    public McpServerSessionState(let sessionId: String, let sseEmitter: JoySseEmitter) {}

    /**
     * 等待会话结束并关闭 SSE 连接
     */
    public func waitEnd(): Unit {
        @JoyLogInfo("[MCP] waiting sse transport end, sessionId=${sessionId}")
        _counter.waitUntilZero()
        @JoyLogInfo("[MCP] server SSE transport is end, sessionId: ${sessionId}")
        sseEmitter.end()
    }

    /**
     * 通过递减计数器完成会话
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
     * 将流标记为已完成
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
     * 检查流是否已完成
     */
    public func isStreamCompleted(): Bool {
        // 这里可以添加检查流是否已完成的逻辑
        // 如果使用 McpServerSessionState，可以在这里调用其方法
        // 例如：_state.isStreamCompleted()
        _isClosed
    }

    /**
     * 添加流完成处理程序
     */
    public func addStreamCompletionHandler(handler: () -> Unit): Unit {
        // 这里可以添加流完成处理程序的逻辑
        // 如果使用 McpServerSessionState，可以在这里调用其方法
        // 例如：_state.addStreamCompletionHandler(handler)
    }

    /**
     * 初始化新的 DefaultMcpServerSession
     *
     * @param sessionId 唯一的会话标识符
     * @param transport 要使用的 MCP 传输
     * @param isJsonResp 是否直接发送 JSON 响应而不是通过传输
     * @param streamable 这是否是可流式传输的会话
     * @param eventStore 用于持久化事件的可选事件存储（默认：None）
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
     * 创建一个虚拟的 JoyContext 实例，用于没有真实上下文时
     *
     * @return 虚拟的 JoyContext 实例
     */
    private func _dummyContext(): JoyContext {
        // 在实际代码中，我们应该使用一个更简单的方法来获取或创建上下文
        // 这里我们抛出异常，因为我们不应该在没有上下文的情况下调用event store方法
        throw Exception("No JoyContext available")
    }

    /**
     * 存储事件以供检索
     *
     * @param data 要存储的事件数据
     * @return 唯一的事件标识符
     */
    /**
     * 使用 <streamID>_<index> 格式格式化事件 ID
     *
     * @param streamId 流标识符
     * @param index 流中的事件索引
     * @return 格式化后的事件 ID 字符串
     */
    private func formatEventId(streamId: String, index: Int64): String {
        "${streamId}_${index}"
    }

    /**
     * 解析 <streamID>_<index> 格式的事件 ID
     *
     * @param eventId 要解析的事件 ID
     * @return 如果解析成功返回包含 (streamId, index) 的元组，否则返回 (None, None)
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
     * 存储事件以供检索
     *
     * @param data 要存储的事件数据
     * @return <streamID>_<index> 格式的唯一事件标识符
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
     * 检索特定事件 ID 之后的所有事件
     *
     * @param lastEventId 用作起点的最后一个事件 ID
     * @return 包含事件 ID 和数据的列表
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
     * 清理旧事件以防止内存溢出
     *
     * @param maxEvents 要保留的最大事件数量
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
     * 更新此会话的传输
     *
     * @param transport 要使用的新传输
     */
    func updateTransport(transport: McpTransport): Unit {
        _transport.close()
        _transport = transport
        @JoyLogInfo("[MCP] update SSE transport, sessionId=${_sessionId}")
    }

    /**
     * 关闭当前传输
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
     * 处理传入的 JSON-RPC 消息
     *
     * @param ctx 请求的 JoyContext
     * @param message 要处理的 JSON-RPC 消息
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
     * 发送 JSON-RPC 请求（服务器会话不支持）
     *
     * @param method 方法名称
     * @param requestParams 请求参数
     * @return 类型 T 的响应
     * @throws UnsupportedException 始终抛出，因为服务器会话不支持传出请求
     */
    public func sendRequest<T>(_: String, _: JsonSerializable): T where T <: JsonDeserializable<T> {
        throw UnsupportedException("unsupported this method")
    }

    /**
     * 发送 JSON-RPC 通知
     *
     * @param method 通知方法名称
     * @param params 通知参数（可选）
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
     * 为特定方法添加通知消费者
     *
     * @param method 通知方法名称
     * @param consumer 处理通知字节的消费者函数
     */
    public func addNotificationConsumer(method: String, consumer: (Array<Byte>) -> Unit): Unit {
        _notificationConsumer.add(method, consumer)
    }

    /**
     * 处理传入的 JSON-RPC 通知
     *
     * @param message 要处理的 JSON-RPC 通知
     */
    public func onNotification(message: JSONRPCNotification): Unit {
        _notificationConsumer.get(message.method).map({
            consumer: (Array<Byte>) -> Unit => consumer((message.params as Array<Byte>) ?? Array<Byte>())
        })
    }

    /**
     * 处理传入的 JSON-RPC 响应（默认实现不执行任何操作）
     *
     * @param message 要处理的 JSON-RPC 响应
     */
    public func onResponse(_: JSONRPCResponse): Unit {
    }

    /**
     * 处理传入的 JSON-RPC 请求
     *
     * @param ctx 请求的 JoyContext
     * @param message 要处理的 JSON-RPC 请求
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
     * 发送 JSON-RPC 响应
     *
     * @param ctx 响应的 JoyContext
     * @param resp 要发送的 JSON-RPC 响应
     * @param jsonResp 是直接作为 JSON 发送响应还是通过传输发送
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
     * 处理初始化请求
     *
     * @param request 初始化请求
     * @return 初始化结果
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
     * 根据客户端请求和服务器支持协商协议版本
     *
     * @param clientVersion 客户端请求的协议版本
     * @return 协商后的协议版本
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
     * 关闭会话
     */
    public func close(): Unit {
        if (_isClosed) {
            return
        }
        _transport.close()
        _isClosed = true
    }

    /**
     * 检查会话是否已关闭
     *
     * @return 如果会话已关闭返回 true，否则返回 false
     */
    public func isClosed(): Bool {
        _isClosed
    }
}
