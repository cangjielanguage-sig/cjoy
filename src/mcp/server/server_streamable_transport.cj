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
import stdx.net.http.HttpStatusCode
import cjoy.framework.{JoyContext, JoyHttpConsts, JoyServerEventBuilder}
import cjoy.utils.secureRandStr
import cjoy.mcp.api.*
import cjoy.jsonrpc.api.{JSONRPCRequest, JSONRPCResponse, JSONRPCMessage, JSONRPCTool, JSONRPCError, JSONRPCConsts, JSONRPCException}
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
     * Flag indicating if responses should be sent as JSON instead of SSE
     */
    private let _isJsonResp: Bool

    /**
     * Initializes a new McpStreamableServerTransport
     *
     * @param isJsonResp Whether to return JSON responses instead of SSE streams
     */
    public init(isJsonResp: Bool) {
        _isJsonResp = isJsonResp
        if (isJsonResp) {
            @JoyLogInfo("[MCP] started streamable transport, return JSON response for requests instead of SSE streams")
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
            DefaultMcpServerSession(sessionId, this, _isJsonResp, true)
        } else {
            let transport = createTransport(ctx, sessionId)
            DefaultMcpServerSession(sessionId, transport, _isJsonResp, true)
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
            session = validateSession(ctx, mustExist: false)
            if (session.isNone()) {
                let sessionId = secureRandStr(16)
                let sess = createSession(ctx, sessionId)
                @JoyLogInfo("[MCP] create streamable session, sessionId: ${sessionId}")
                session = sess
                _sessions.add(sessionId, sess)
            }
            session?.handle(ctx, m)
            if (!_isJsonResp) {
                closeTransport(session)
            }
        } else {
            session = validateSession(ctx)
            if (!_isJsonResp) {
                updateTransport(ctx, session)
            }
            session?.handle(ctx, m)
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
