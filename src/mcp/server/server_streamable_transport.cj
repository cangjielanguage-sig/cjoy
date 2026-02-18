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
import std.collection.{any, map, collectArrayList}
import std.io.ByteBuffer
import std.time.DateTime
import stdx.net.http.HttpStatusCode
import cjoy.framework.{JoyContext, JoyHttpConsts, JoySseBuilder}
import cjoy.utils.secureRandStr
import cjoy.mcp.api.*
import cjoy.jsonrpc.api.{JSONRPCRequest, JSONRPCResponse, JSONRPCMessage, JSONRPCTool, JSONRPCError, JSONRPCConsts, 
    JSONRPCException}
import cjoy.log.macros.*

/**
 * 用于流式传输和 JSON 响应的 MCP 服务器传输
 *
 * 提供 MCP 服务器与客户端之间使用 SSE（Server-Sent Events）的流式通信，
 * 支持 JSON 响应和会话可恢复性。
 */
class McpStreamableServerTransport <: McpServerTransport {
    /**
     * 用于存储活动服务器会话及用户信息的 ConcurrentHashMap
     */
    private let _sessions: ConcurrentHashMap<String, SessionInfo> = ConcurrentHashMap()

    /**
     * 用于跟踪会话时间戳的映射：sessionId -> 最后活动时间
     */
    private let _sessionTimestamps: ConcurrentHashMap<String, Int64> = ConcurrentHashMap()

    /**
     * 会话超时持续时间（毫秒），默认 30 分钟
     */
    private let _sessionTimeoutMs: Int64

    /**
     * 检查和清理超时会话的时间间隔（毫秒），默认 5 分钟
     */
    private let _sessionCheckIntervalMs: Int64

    /**
     * 标志位，指示是否启用会话超时管理
     */
    private let _sessionTimeoutEnabled: Bool

    /**
     * 标志位，指示是否将响应作为 JSON 而不是 SSE 发送
     */
    private let _isJsonResp: Bool

    /**
     * 用于持久化和重放事件的事件存储
     */
    private let _eventStore: ?EventStore

    /**
     * 标志位，指示会话超时任务是否正在运行
     */
    private var _sessionTimeoutTaskRunning: Bool = false

    /**
     * 标志位，指示是否启用无状态模式
     */
    private let _statelessMode: Bool

    /**
     * 标志位，指示是否禁用 localhost 的 DNS 重绑定保护
     */
    private let _disableLocalhostProtection: Bool

    /**
     * 初始化新的 McpStreamableServerTransport
     *
     * @param isJsonResp 是否返回 JSON 响应而不是 SSE 流
     * @param eventStore 用于持久化事件的事件存储（默认：None）
     * @param sessionTimeoutMs 会话超时持续时间（毫秒）（默认：30 分钟）
     * @param sessionCheckIntervalMs 检查和清理超时会话的时间间隔（毫秒）（默认：5 分钟）
     * @param statelessMode 是否启用无状态模式（默认：false）
     * @param disableLocalhostProtection 是否禁用 localhost 的 DNS 重绑定保护（默认：false）
     */
    public init(isJsonResp: Bool, eventStore!: ?EventStore = None, sessionTimeoutMs!: Int64 = 30 * 60 * 1000,
        sessionCheckIntervalMs!: Int64 = 5 * 60 * 1000, statelessMode!: Bool = false,
        disableLocalhostProtection!: Bool = false) {
        _isJsonResp = isJsonResp
        _eventStore = eventStore
        _sessionTimeoutMs = sessionTimeoutMs
        _sessionCheckIntervalMs = sessionCheckIntervalMs
        _sessionTimeoutEnabled = (sessionTimeoutMs > 0 && sessionCheckIntervalMs > 0)
        _statelessMode = statelessMode
        _disableLocalhostProtection = disableLocalhostProtection

        if (_statelessMode) {
            @JoyLogInfo("[MCP] started streamable transport with stateless mode enabled")
        }

        if (isJsonResp) {
            @JoyLogInfo("[MCP] started streamable transport, return JSON response for requests instead of SSE streams")
        }
        if (eventStore.isSome()) {
            @JoyLogInfo("[MCP] started streamable transport with event store support")
        }
        if (_sessionTimeoutEnabled) {
            @JoyLogInfo("[MCP] started streamable transport with session timeout management, timeout: ${_sessionTimeoutMs}ms, check interval: ${_sessionCheckIntervalMs}ms")
            startSessionTimeoutTask()
        } else {
            @JoyLogInfo("[MCP] started streamable transport with session timeout management disabled")
        }

        if (_disableLocalhostProtection) {
            @JoyLogInfo("[MCP] DNS protection disabled")
        } else {
            @JoyLogInfo("[MCP] DNS protection enabled")
        }
    }

    /**
     * 处理传入的 GET 请求以建立 SSE 连接
     *
     * @param ctx 请求的 JoyContext
     */
    public func handleGetRequest(ctx: JoyContext): Unit {
        if (!validateProtocolVersion(ctx) || !validateLocalhostProtection(ctx, _disableLocalhostProtection)) {
            return
        }

        let (_, hasSse) = checkAcceptHeader(ctx)
        if (!hasSse) {
            @JoyLogError("[MCP] handle get request faild, Not Acceptable")
            let err = createErrorMsg("Not Acceptable: client must accept ${JoyHttpConsts.MIME_TEXT_EVENT_STREAM}")
            ctx.status(HttpStatusCode.STATUS_NOT_ACCEPTABLE).json(err)
            return
        }

        let session = validateSession(ctx)
        if (session.isNone()) {
            return
        }

        // Handle resumability: check Last-Event-ID
        if (let Some(id) <- ctx.getHeader(McpConsts.HEADER_LAST_EVENT_ID)) {
            relayEvents(ctx, id)
            return
        }

        updateTransport(ctx, session)
        waitEnd(session)
    }

    /**
     * 处理传入的 POST 请求以进行消息交换
     *
     * @param ctx 请求的 JoyContext
     */
    public func handlePostRequest(ctx: JoyContext): Unit {
        if (!validateProtocolVersion(ctx) || !validateLocalhostProtection(ctx, _disableLocalhostProtection)) {
            return
        }

        let (hasJson, hasSse) = checkAcceptHeader(ctx)
        if (!(hasJson && hasSse)) {
            @JoyLogError("[MCP] handle post request faild, Not Acceptable")
            let err = createErrorMsg(
                "Not Acceptable: Client both ${JoyHttpConsts.MIME_APP_JSON} and ${JoyHttpConsts.MIME_TEXT_EVENT_STREAM}")
            ctx
                .status(HttpStatusCode.STATUS_NOT_ACCEPTABLE)
                .header("content-type", JoyHttpConsts.MIME_TEXT_EVENT_STREAM)
                .json(err)
            return
        }

        if (!checkContentType(ctx)) {
            @JoyLogError("[MCP] handle post request faild, Unsupported Media Type")
            let err = createErrorMsg("Unsupported Media Type: Content-Type must be ${JoyHttpConsts.MIME_APP_JSON}")
            ctx.status(HttpStatusCode.STATUS_UNSUPPORTED_MEDIA_TYPE).json(err)
            return
        }

        // read body
        let data = ctx.readRawData()
        try {
            let message = JSONRPCTool.deserialize(data)
            handleMessage(ctx, message)
        } catch (ex: JSONRPCException) {
            @JoyLogError("[MCP] handle post request faild, error: ${ex.message}")
            let resp = JSONRPCResponse(id: "server-error", error: ex.error)
            ctx.status(HttpStatusCode.STATUS_BAD_REQUEST).json(resp)
            return
        }
    }

    /**
     * 处理传入的 DELETE 请求以终止会话
     *
     * @param ctx 请求的 JoyContext
     */
    public func handleDelRequest(ctx: JoyContext): Unit {
        if (!validateProtocolVersion(ctx) || !validateLocalhostProtection(ctx, _disableLocalhostProtection)) {
            return
        }

        let session = validateSession(ctx)
        if (let Some(s) <- session) {
            terminateSession(s)
            ctx.ok()
        }
    }

    /**
     * 启动会话超时检查任务
     */
    private func startSessionTimeoutTask(): Unit {
        _sessionTimeoutTaskRunning = true
        spawn {
            while (_sessionTimeoutTaskRunning) {
                sleep(_sessionCheckIntervalMs * Duration.millisecond)
                checkTimeoutSessions()
            }
        }
    }

    /**
     * 检查和清理超时会话
     */
    private func checkTimeoutSessions(): Unit {
        let currentTime = DateTime.now().toUnixTimeStamp().toMilliseconds() // Convert to milliseconds
        let timeoutThreshold = _sessionTimeoutMs

        @JoyLogDebug("[MCP] checking for timeout sessions, current time: ${currentTime}, timeout threshold: ${timeoutThreshold}ms")

        let sessionIter = _sessions.iterator()
        while (let Some((sessionId, sessionInfo)) <- sessionIter.next()) {
            // Get session's last activity time
            let lastActivityTime = _sessionTimestamps.get(sessionId)

            if (let Some(activityTime) <- lastActivityTime) {
                let elapsedTime = currentTime - activityTime
                if (elapsedTime > timeoutThreshold) {
                    @JoyLogInfo("[MCP] session timeout, sessionId: ${sessionId}, elapsed: ${elapsedTime}ms, threshold: ${timeoutThreshold}ms")
                    // Cleanup session
                    _sessions.remove(sessionId)
                    _sessionTimestamps.remove(sessionId)
                    terminateSession(sessionInfo.session)
                }
            } else {
                // Session without timestamp, consider it as timeout and clean up
                @JoyLogInfo("[MCP] session without timestamp, consider as timeout: ${sessionId}")
                terminateSession(sessionInfo.session)
            }
        }
    }

    /**
     * 更新会话的最后活动时间
     *
     * @param sessionId 会话标识符
     */
    private func updateSessionActivity(sessionId: String): Unit {
        _sessionTimestamps.add(sessionId, DateTime.now().toUnixTimeStamp().toMilliseconds()) // Convert to milliseconds
    }

    /**
     * 跟踪会话创建时间
     *
     * @param sessionId 会话标识符
     */
    private func sessionCreated(sessionId: String): Unit {
        _sessionTimestamps.add(sessionId, DateTime.now().toUnixTimeStamp().toMilliseconds()) // Convert to milliseconds
    }

    /**
     * 通过此传输发送消息（流式传输未实现）
     *
     * @param message 要发送的消息
     */
    public func send(message: ByteBuffer): Unit {
        // nothing
    }

    /**
     * 验证请求中的协议版本
     *
     * @param ctx 请求的 JoyContext
     * @return 如果协议版本有效且支持返回 true
     */
    private func validateProtocolVersion(ctx: JoyContext): Bool {
        let protocolVersion = ctx.getHeader(McpConsts.HEADER_PROTOCOL_VERSION) ?? McpConsts.PROTOCOL_VERSION_20250326

        if (!McpConsts.supportedProtocolVersions().contains(protocolVersion)) {
            @JoyLogError("[MCP] unsupported protocol version")
            let err = createErrorMsg("Bad Request: Unsupported protocol version")
            ctx.status(HttpStatusCode.STATUS_BAD_REQUEST).json(err)
            return false
        }

        @JoyLogDebug("[MCP] protocol version validated")
        return true
    }

    /**
     * 验证请求中的会话并防止会话劫持
     *
     * @param ctx 请求的 JoyContext
     * @param mustExist 会话是否必须存在（默认：true）
     * @return 如果有效返回可选的 McpServerSession
     */
    private func validateSession(ctx: JoyContext, mustExist!: Bool = true): ?McpServerSession {
        let sessionId = ctx.getHeader(McpConsts.HEADER_MCP_SESSION_ID)
        if (let Some(id) <- sessionId) {
            let sessionInfo = _sessions.get(id)
            if (let Some(info) <- sessionInfo) {
                // 防止会话劫持：检查用户身份是否匹配
                let requestUserID = getUserIDFromContext(ctx)
                if (info.userID != "" && requestUserID != info.userID) {
                    @JoyLogError("[MCP] session user mismatch")
                    let err = createErrorMsg("Forbidden: Session user mismatch")
                    ctx.status(HttpStatusCode.STATUS_FORBIDDEN).json(err)
                    return None
                }
                return info.session
            } else {
                @JoyLogError("[MCP] not found streamable session, sessionId: ${id}")
                let err = createErrorMsg("Not Found: Invalid or expired session id")
                ctx.status(HttpStatusCode.STATUS_NOT_FOUND).json(err)
            }
        } else {
            if (mustExist) {
                @JoyLogError("[MCP] not found `${McpConsts.HEADER_MCP_SESSION_ID}` in header")
                let err = createErrorMsg("Bad Request: Missing session id")
                ctx.status(HttpStatusCode.STATUS_BAD_REQUEST).json(err)
            }
        }

        return None
    }

    /**
     * 终止会话
     *
     * @param session 要终止的会话
     */
    private func terminateSession(session: McpServerSession): Unit {
        session.close()
        _sessions.remove(session.sessionId)
    }

    /**
     * 检查请求是否接受 JSON 和/或 SSE 响应
     *
     * @param ctx 请求的 JoyContext
     * @return 指示是否接受 JSON 和 SSE 的元组
     */
    private func checkAcceptHeader(ctx: JoyContext): (Bool, Bool) {
        let accept = ctx.getHeader("accept") ?? ""
        let types = accept.split(",") |> map {s => s.trimAscii()} |> collectArrayList
        let hasJson = types |> any {s => s.startsWith(JoyHttpConsts.MIME_APP_JSON)}
        let hasSse = types |> any {s => s.startsWith(JoyHttpConsts.MIME_TEXT_EVENT_STREAM)}
        (hasJson, hasSse)
    }

    /**
     * 检查请求内容类型是否为 JSON
     *
     * @param ctx 请求的 JoyContext
     * @return 如果内容类型是 JSON 返回 true，否则返回 false
     */
    private func checkContentType(ctx: JoyContext): Bool {
        let contentType = ctx.getHeader("Content-Type") ?? ""
        let parts = contentType.split(";")[0].split(",") |> map {s => s.trimAscii()} |> collectArrayList
        parts |> any {s => s == JoyHttpConsts.MIME_APP_JSON}
    }

    /**
     * 处理传入的 JSONRPC 消息
     *
     * @param ctx 请求的 JoyContext
     * @param message 要处理的 JSONRPCMessage
     */
    private func handleMessage(ctx: JoyContext, message: JSONRPCMessage): Unit {
        match (message) {
            case m: JSONRPCRequest => handleRequest(ctx, m)
            case _ =>
                let session = validateSession(ctx)
                ctx.status(HttpStatusCode.STATUS_ACCEPTED)
                session?.handle(ctx, message)
        }
    }

    /**
     * 创建新的 SSE 会话传输
     *
     * @param ctx 请求的 JoyContext
     * @param sessionId 会话标识符
     * @return McpSseServerSessionTransport 实例
     */
    private func createTransport(ctx: JoyContext, sessionId: String): McpSseServerSessionTransport {
        let emitter = ctx.eventEmitter()
        let state = McpServerSessionState(sessionId, emitter)
        McpSseServerSessionTransport(emitter, state, _sessions,
            removeOnErr: false)
    }

    /**
     * 创建新的 DefaultMcpServerSession
     *
     * @param ctx 请求的 JoyContext
     * @param sessionId 会话标识符
     * @return DefaultMcpServerSession 实例
     */
    private func createSession(ctx: JoyContext, sessionId: String): DefaultMcpServerSession {
        if (_isJsonResp) {
            DefaultMcpServerSession(sessionId, this, _isJsonResp, true, eventStore: _eventStore)
        } else {
            let transport = createTransport(ctx, sessionId)
            DefaultMcpServerSession(sessionId, transport, _isJsonResp, true, eventStore: _eventStore)
        }
    }

    /**
     * 关闭会话的传输
     *
     * @param session 要关闭传输的会话
     */
    private func closeTransport(session: ?McpServerSession): Unit {
        if (let Some(s) <- session) {
            if (let Some(sess) <- (s as DefaultMcpServerSession)) {
                sess.closeTransport()
            }
        }
    }

    /**
     * 更新会话的传输
     *
     * @param ctx 请求的 JoyContext
     * @param session 要更新传输的会话
     */
    private func updateTransport(ctx: JoyContext, session: ?McpServerSession): Unit {
        if (let Some(s) <- session) {
            if (let Some(sess) <- (s as DefaultMcpServerSession)) {
                // update emitter for transport
                sess.updateTransport(createTransport(ctx, sess._sessionId))
            }
        }
    }

    /**
     * 等待会话结束
     *
     * @param session 要等待的会话
     */
    private func waitEnd(session: ?McpServerSession): Unit {
        if (let Some(s) <- session) {
            if (let Some(sess) <- (s as DefaultMcpServerSession)) {
                if (let Some(t) <- (sess._transport as McpSseServerSessionTransport)) {
                    t._state.waitEnd()
                }
            }
        }
    }

    /**
     * 处理传入的 JSONRPCRequest 消息
     *
     * @param ctx 请求的 JoyContext
     * @param m 要处理的 JSONRPCRequest
     */
    private func handleRequest(ctx: JoyContext, m: JSONRPCRequest): Unit {
        var session: ?McpServerSession = None
        let isInitializeRequest = m.method == McpConsts.METHOD_INITIALIZE

        // 统一会话创建和验证逻辑
        session = if (isInitializeRequest) {
            initializeSession(ctx)
        } else if (_statelessMode) {
            createTemporarySession(ctx, "non-initialize")
        } else {
            validateAndUpdateSession(ctx)
        }

        // 处理请求
        if (let Some(s) <- session) {
            if (!_isJsonResp && !isInitializeRequest) {
                updateTransport(ctx, session)
            }

            s.handle(ctx, m)

            if (!_isJsonResp && isInitializeRequest) {
                closeTransport(session)
            }

            // 无状态模式下，处理完请求后立即关闭会话
            if (_statelessMode) {
                s.close()
                _sessions.remove(s.sessionId)
                _sessionTimestamps.remove(s.sessionId)
            }
        }
    }

    /**
     * 处理初始化请求的会话创建和验证
     */
    private func initializeSession(ctx: JoyContext): ?McpServerSession {
        let session = validateSession(ctx, mustExist: false)

        if (session.isNone()) {
            let sessionId = secureRandStr(16)
            let sess = createSession(ctx, sessionId)
            @JoyLogInfo("[MCP] create ${if (_statelessMode) {"stateless" }else {"streamable"}} session, sessionId: ${sessionId}")

            let userID = getUserIDFromContext(ctx)
            let sessionInfo = SessionInfo(sess, userID)
            _sessions.add(sessionId, sessionInfo)
            sessionCreated(sessionId)

            return sess
        }

        // 更新已存在会话的活动时间
        if (let Some(s) <- session) {
            updateSessionActivity(s.sessionId)
        }

        return session
    }

    /**
     * 创建临时会话
     */
    private func createTemporarySession(ctx: JoyContext, requestType: String): ?McpServerSession {
        let sessionId = secureRandStr(16)
        let sess = createSession(ctx, sessionId)
        @JoyLogInfo("[MCP] create stateless session for ${requestType} request, sessionId: ${sessionId}")

        let userID = getUserIDFromContext(ctx)
        let sessionInfo = SessionInfo(sess, userID)
        _sessions.add(sessionId, sessionInfo)
        sessionCreated(sessionId)

        return sess
    }

    /**
     * 验证并更新会话
     */
    private func validateAndUpdateSession(ctx: JoyContext): ?McpServerSession {
        let session = validateSession(ctx)
        if (let Some(s) <- session) {
            updateSessionActivity(s.sessionId)
        }
        return session
    }

    /**
     * 从特定事件 ID 向客户端中继事件
     *
     * @param ctx 请求的 JoyContext
     * @param lastEventId 客户端接收的最后一个事件 ID
     */
    private func relayEvents(ctx: JoyContext, lastEventId: String): Unit {
        let session = validateSession(ctx)
        if (session.isNone()) {
            return
        }

        if (let Some(sess) <- (session as DefaultMcpServerSession)) {
            let events = sess.retrieveEvents(lastEventId)
            if (events.isEmpty()) {
                @JoyLogDebug("[MCP] No events to relay after eventId: ${lastEventId}, sessionId: ${sess._sessionId}")
                return
            }

            // Send events
            var i = 0
            while (i < events.size) {
                let (eventId, data) = events[i]
                try {
                    sendEvent(ctx, eventId, data)
                } catch (ex: Exception) {
                    @JoyLogError("[MCP] Failed to send relayed event, eventId: ${eventId}, sessionId: ${sess._sessionId}, error: ${ex.message}")
                }
                i += 1
            }
        }
    }

    /**
     * 向客户端发送事件
     *
     * @param ctx 请求的 JoyContext
     * @param eventId 事件 ID
     * @param data 事件数据，类型为 ByteBuffer
     */
    private func sendEvent(ctx: JoyContext, eventId: String, data: ByteBuffer): Unit {
        let emitter = ctx.eventEmitter()
        let eventBuilder = JoySseBuilder()
        eventBuilder.id(eventId)
        eventBuilder.data(String.fromUtf8(data.bytes()))
        emitter.sendEvent(eventBuilder)
    }

    /**
     * 关闭传输
     */
    public func close(): Unit {
    }

    /**
     * 检查传输是否已关闭
     *
     * @return 对于可流式传输始终返回 false
     */
    public func isClosed(): Bool {
        false
    }
}
