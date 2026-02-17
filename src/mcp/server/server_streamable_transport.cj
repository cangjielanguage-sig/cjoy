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
import cjoy.framework.{JoyContext, JoyHttpConsts, JoyServerEventBuilder}
import cjoy.utils.secureRandStr
import cjoy.mcp.api.*
import cjoy.jsonrpc.api.{JSONRPCRequest, JSONRPCResponse, JSONRPCMessage, JSONRPCTool, JSONRPCError, JSONRPCConsts, 
    JSONRPCException}
import cjoy.log.macros.*

/**
 * MCP server transport for streaming with JSON response
 *
 * Provides streamable communication between MCP server and clients using SSE
 * (Server-Sent Events) with support for JSON responses and session resumability.
 */
class McpStreamableServerTransport <: McpServerTransport {
    /**
     * ConcurrentHashMap for storing active server sessions
     */
    private let _sessions: ConcurrentHashMap<String, McpServerSession> = ConcurrentHashMap()

    /**
     * Map for tracking session timestamps: sessionId -> last activity time
     */
    private let _sessionTimestamps: ConcurrentHashMap<String, Int64> = ConcurrentHashMap()

    /**
     * Session timeout duration in milliseconds, default 30 minutes
     */
    private let _sessionTimeoutMs: Int64

    /**
     * Time interval for checking and cleaning up timeout sessions in milliseconds, default 5 minutes
     */
    private let _sessionCheckIntervalMs: Int64

    /**
     * Flag indicating if session timeout management is enabled
     */
    private let _sessionTimeoutEnabled: Bool

    /**
     * Flag indicating if responses should be sent as JSON instead of SSE
     */
    private let _isJsonResp: Bool

    /**
     * Event store for persisting and replaying events
     */
    private let _eventStore: ?EventStore

    /**
     * Flag indicating if session timeout task is running
     */
    private var _sessionTimeoutTaskRunning: Bool = false

    /**
     * Flag indicating if stateless mode is enabled
     */
    private let _statelessMode: Bool

    /**
     * Initializes a new McpStreamableServerTransport
     *
     * @param isJsonResp Whether to return JSON responses instead of SSE streams
     * @param eventStore Optional event store for persisting events (default: None)
     * @param sessionTimeoutMs Session timeout duration in milliseconds (default: 30 minutes)
     * @param sessionCheckIntervalMs Time interval for checking and cleaning up timeout sessions (default: 5 minutes)
     * @param statelessMode Whether to enable stateless mode (default: false)
     */
    public init(isJsonResp: Bool, eventStore!: ?EventStore = None, sessionTimeoutMs!: Int64 = 30 * 60 * 1000,
        sessionCheckIntervalMs!: Int64 = 5 * 60 * 1000, statelessMode!: Bool = false) {
        _isJsonResp = isJsonResp
        _eventStore = eventStore
        _sessionTimeoutMs = sessionTimeoutMs
        _sessionCheckIntervalMs = sessionCheckIntervalMs
        _sessionTimeoutEnabled = (sessionTimeoutMs > 0 && sessionCheckIntervalMs > 0)
        _statelessMode = statelessMode

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
    }

    /**
     * Handles incoming GET requests for SSE connections
     *
     * @param ctx The JoyContext for the request
     */
    public func handleGetRequest(ctx: JoyContext): Unit {
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
     * Handles incoming POST requests for message exchange
     *
     * @param ctx The JoyContext for the request
     */
    public func handlePostRequest(ctx: JoyContext): Unit {
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
     * Handles incoming DELETE requests for terminating sessions
     *
     * @param ctx The JoyContext for the request
     */
    public func handleDelRequest(ctx: JoyContext): Unit {
        let session = validateSession(ctx)
        if (let Some(s) <- session) {
            terminateSession(s)
            ctx.ok()
        }
    }

    /**
     * Starts the session timeout check task
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
     * Checks and cleans up timeout sessions
     */
    private func checkTimeoutSessions(): Unit {
        let currentTime = DateTime.now().toUnixTimeStamp().toMilliseconds() // Convert to milliseconds
        let timeoutThreshold = _sessionTimeoutMs

        @JoyLogDebug("[MCP] checking for timeout sessions, current time: ${currentTime}, timeout threshold: ${timeoutThreshold}ms")

        let sessionIter = _sessions.iterator()
        while (let Some((sessionId, session)) <- sessionIter.next()) {
            // Get session's last activity time
            let lastActivityTime = _sessionTimestamps.get(sessionId)

            if (let Some(activityTime) <- lastActivityTime) {
                let elapsedTime = currentTime - activityTime
                if (elapsedTime > timeoutThreshold) {
                    @JoyLogInfo("[MCP] session timeout, sessionId: ${sessionId}, elapsed: ${elapsedTime}ms, threshold: ${timeoutThreshold}ms")
                    // Cleanup session
                    _sessions.remove(sessionId)
                    _sessionTimestamps.remove(sessionId)
                    terminateSession(session)
                }
            } else {
                // Session without timestamp, consider it as timeout and clean up
                @JoyLogInfo("[MCP] session without timestamp, consider as timeout: ${sessionId}")
                terminateSession(session)
            }
        }
    }

    /**
     * Updates a session's last activity time
     *
     * @param sessionId The session identifier
     */
    private func updateSessionActivity(sessionId: String): Unit {
        _sessionTimestamps.add(sessionId, DateTime.now().toUnixTimeStamp().toMilliseconds()) // Convert to milliseconds
    }

    /**
     * Tracks session creation time
     *
     * @param sessionId The session identifier
     */
    private func sessionCreated(sessionId: String): Unit {
        _sessionTimestamps.add(sessionId, DateTime.now().toUnixTimeStamp().toMilliseconds()) // Convert to milliseconds
    }

    /**
     * Sends a message through this transport (not implemented for streamable)
     *
     * @param message The message to send
     */
    public func send(message: ByteBuffer): Unit {
        // nothing
    }

    /**
     * Validates the session from the request
     *
     * @param ctx The JoyContext for the request
     * @param mustExist Whether the session must exist (default: true)
     * @return Optional McpServerSession if valid
     */
    private func validateSession(ctx: JoyContext, mustExist!: Bool = true): ?McpServerSession {
        let sessionId = ctx.getHeader(McpConsts.HEADER_MCP_SESSION_ID)
        if (let Some(id) <- sessionId) {
            let session = _sessions.get(id)
            if (let Some(s) <- session) {
                return s
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
     * Terminates a session
     *
     * @param session The session to terminate
     */
    private func terminateSession(session: McpServerSession): Unit {
        session.close()
        _sessions.remove(session.sessionId)
    }

    /**
     * Creates a JSONRPCResponse with an error message
     *
     * @param msg The error message
     * @param code The error code (default: JSONRPCConsts.ERR_INVALID_REQUEST)
     * @return The JSONRPCResponse with error information
     */
    private func createErrorMsg(msg: String, code!: Int = JSONRPCConsts.ERR_INVALID_REQUEST): JSONRPCResponse {
        let err = JSONRPCError(code: code, message: msg)
        JSONRPCResponse(id: "server-error", error: err)
    }

    /**
     * Checks if the request accepts JSON and/or SSE responses
     *
     * @param ctx The JoyContext for the request
     * @return Tuple indicating if JSON and SSE are accepted
     */
    private func checkAcceptHeader(ctx: JoyContext): (Bool, Bool) {
        let accept = ctx.getHeader("accept") ?? ""
        let types = accept.split(",") |> map {s => s.trimAscii()} |> collectArrayList
        let hasJson = types |> any {s => s.startsWith(JoyHttpConsts.MIME_APP_JSON)}
        let hasSse = types |> any {s => s.startsWith(JoyHttpConsts.MIME_TEXT_EVENT_STREAM)}
        (hasJson, hasSse)
    }

    /**
     * Checks if the request content type is JSON
     *
     * @param ctx The JoyContext for the request
     * @return True if content type is JSON, false otherwise
     */
    private func checkContentType(ctx: JoyContext): Bool {
        let contentType = ctx.getHeader("Content-Type") ?? ""
        let parts = contentType.split(";")[0].split(",") |> map {s => s.trimAscii()} |> collectArrayList
        parts |> any {s => s == JoyHttpConsts.MIME_APP_JSON}
    }

    /**
     * Handles incoming JSONRPC messages
     *
     * @param ctx The JoyContext for the request
     * @param message The JSONRPCMessage to handle
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
     * Creates a new SSE session transport
     *
     * @param ctx The JoyContext for the request
     * @param sessionId The session identifier
     * @return McpSseServerSessionTransport instance
     */
    private func createTransport(ctx: JoyContext, sessionId: String): McpSseServerSessionTransport {
        let emitter = ctx.eventEmitter()
        let state = McpServerSessionState(sessionId, emitter)
        McpSseServerSessionTransport(emitter, state, _sessions, removeOnErr: false)
    }

    /**
     * Creates a new DefaultMcpServerSession
     *
     * @param ctx The JoyContext for the request
     * @param sessionId The session identifier
     * @return DefaultMcpServerSession instance
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
     * Closes the transport for a session
     *
     * @param session The session to close transport for
     */
    private func closeTransport(session: ?McpServerSession): Unit {
        if (let Some(s) <- session) {
            if (let Some(sess) <- (s as DefaultMcpServerSession)) {
                sess.closeTransport()
            }
        }
    }

    /**
     * Updates the transport for a session
     *
     * @param ctx The JoyContext for the request
     * @param session The session to update transport for
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
     * Waits for a session to end
     *
     * @param session The session to wait for
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
     * Handles incoming JSONRPCRequest messages
     *
     * @param ctx The JoyContext for the request
     * @param m The JSONRPCRequest to handle
     */
    private func handleRequest(ctx: JoyContext, m: JSONRPCRequest): Unit {
        var session: ?McpServerSession = None
        if (m.method == McpConsts.METHOD_INITIALIZE) {
            session = validateSession(ctx, mustExist: !_statelessMode)
            if (session.isNone()) {
                let sessionId = secureRandStr(16)
                let sess = createSession(ctx, sessionId)
                if (_statelessMode) {
                    @JoyLogInfo("[MCP] create stateless session, sessionId: ${sessionId}")
                } else {
                    @JoyLogInfo("[MCP] create streamable session, sessionId: ${sessionId}")
                }
                session = sess
                _sessions.add(sessionId, sess)
                sessionCreated(sessionId) // 记录会话创建时间
            } else {
                // 更新已存在会话的活动时间
                if (let Some(s) <- session) {
                    updateSessionActivity(s.sessionId)
                }
            }
            session?.handle(ctx, m)
            if (!_isJsonResp) {
                closeTransport(session)
            }

            // 无状态模式下，处理完请求后立即关闭会话
            if (_statelessMode) {
                session?.close()
                if (let Some(s) <- session) {
                    _sessions.remove(s.sessionId)
                    _sessionTimestamps.remove(s.sessionId)
                }
            }
        } else {
            // 无状态模式下，对于非初始化请求也创建临时会话
            if (_statelessMode) {
                let sessionId = secureRandStr(16)
                let sess = createSession(ctx, sessionId)
                @JoyLogInfo("[MCP] create stateless session for non-initialize request, sessionId: ${sessionId}")
                session = sess
                _sessions.add(sessionId, sess)
                sessionCreated(sessionId) // 记录会话创建时间
            } else {
                session = validateSession(ctx)
                if (let Some(s) <- session) {
                    updateSessionActivity(s.sessionId) // 更新会话活动时间
                }
            }

            if (!_isJsonResp) {
                updateTransport(ctx, session)
            }
            session?.handle(ctx, m)

            // 无状态模式下，处理完请求后立即关闭会话
            if (_statelessMode) {
                session?.close()
                if (let Some(s) <- session) {
                    _sessions.remove(s.sessionId)
                    _sessionTimestamps.remove(s.sessionId)
                }
            }
        }
    }

    /**
     * Relays events to a client from a specific event ID
     *
     * @param ctx The JoyContext for the request
     * @param lastEventId The last event ID received by the client
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
     * Sends an event to the client
     *
     * @param ctx The JoyContext for the request
     * @param eventId The event ID
     * @param data The event data as ByteBuffer
     */
    private func sendEvent(ctx: JoyContext, eventId: String, data: ByteBuffer): Unit {
        let emitter = ctx.eventEmitter()
        let eventBuilder = JoyServerEventBuilder()
        eventBuilder.id(eventId)
        eventBuilder.data(String.fromUtf8(data.bytes()))
        emitter.sendEvent(eventBuilder)
    }

    /**
     * Closes the transport
     */
    public func close(): Unit {
    }

    /**
     * Checks if the transport is closed
     *
     * @return Always false for streamable transport
     */
    public func isClosed(): Bool {
        false
    }
}
