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
import std.collection.{any, map, collectArrayList}
import std.io.ByteBuffer
import stdx.net.http.HttpStatusCode
import cjoy.framework.{JoyContext, JoyHttpConsts}
import cjoy.utils.secureRandStr
import cjoy.mcp.api.*
import cjoy.log.*

class McpStreamableServerTransport <: McpServerTransport {
    private let _sessions: ConcurrentHashMap<String, McpServerSession> = ConcurrentHashMap()
    private let _isJsonResp: Bool

    public init(isJsonResp: Bool) {
        _isJsonResp = isJsonResp
        if (isJsonResp) {
            @LogInfo("[MCP] started streamable transport, return JSON response for requests instead of SSE streams")
        }
    }

    public func handleGetRequest(ctx: JoyContext): Unit {
        let (_, hasSse) = checkAcceptHeader(ctx)
        if (!hasSse) {
            @LogError("[MCP] handle get request faild, Not Acceptable")
            let err = createErrorMsg("Not Acceptable: client must accept ${JoyHttpConsts.MIME_TEXT_EVENT_STREAM}")
            ctx.status(HttpStatusCode.STATUS_NOT_ACCEPTABLE).json(err)
            return
        }

        let session = validateSession(ctx)
        if (session.isNone()) {
            return
        }

        // Handle resumabiltiy: check Last-Event-ID 
        if (let Some(id) <- ctx.getHeader(McpConsts.HEADER_LAST_EVENT_ID)) {
            relayEvents(ctx, id)
            return
        }

        updateTransport(ctx, session)
        waitEnd(session)
    }

    public func handlePostRequest(ctx: JoyContext): Unit {
        let (hasJson, hasSse) = checkAcceptHeader(ctx)
        if (!(hasJson && hasSse)) {
            @LogError("[MCP] handle post request faild, Not Acceptable")
            let err = createErrorMsg(
                "Not Acceptable: Client both ${JoyHttpConsts.MIME_APP_JSON} and ${JoyHttpConsts.MIME_TEXT_EVENT_STREAM}")
            ctx
                .status(HttpStatusCode.STATUS_NOT_ACCEPTABLE)
                .header("content-type", JoyHttpConsts.MIME_TEXT_EVENT_STREAM)
                .json(err)
            return
        }

        if (!checkContentType(ctx)) {
            @LogError("[MCP] handle post request faild, Unsupported Media Type")
            let err = createErrorMsg("Unsupported Media Type: Content-Type must be ${JoyHttpConsts.MIME_APP_JSON}")
            ctx.status(HttpStatusCode.STATUS_UNSUPPORTED_MEDIA_TYPE).json(err)
            return
        }

        // read body
        let data = ctx.readRawData()
        try {
            let message = RPCJsonTool.deserialize(data)
            handleMessage(ctx, message)
        } catch (ex: McpException) {
            @LogError("[MCP] handle post request faild, error: ${ex.message}")
            let resp = JSONRPCResponse(id: "server-error", error: ex.error)
            ctx.status(HttpStatusCode.STATUS_BAD_REQUEST).json(resp)
            return
        }
    }

    public func handleDelRequest(ctx: JoyContext): Unit {
        let session = validateSession(ctx)
        if (let Some(s) <- session) {
            terminateSession(s)
            ctx.ok()
        }
    }

    public func send(message: ByteBuffer): Unit {
        // nothing
    }

    private func validateSession(ctx: JoyContext, mustExist!: Bool = true): ?McpServerSession {
        let sessionId = ctx.getHeader(McpConsts.HEADER_MCP_SESSION_ID)
        if (let Some(id) <- sessionId) {
            let session = _sessions.get(id)
            if (let Some(s) <- session) {
                return s
            } else {
                @LogError("[MCP] not found streamable session, sessionId: ${id}")
                let err = createErrorMsg("Not Found: Invalid or expired session id")
                ctx.status(HttpStatusCode.STATUS_NOT_FOUND).json(err)
            }
        } else {
            if (mustExist) {
                @LogError("[MCP] not found `${McpConsts.HEADER_MCP_SESSION_ID}` in header")
                let err = createErrorMsg("Bad Request: Missing session id")
                ctx.status(HttpStatusCode.STATUS_BAD_REQUEST).json(err)
            }
        }

        return None
    }

    private func terminateSession(session: McpServerSession): Unit {
        session.close()
    }

    private func createErrorMsg(msg: String, code!: Int = McpConsts.ERR_INVALID_REQUEST): JSONRPCResponse {
        let err = JSONRPCError(code: code, message: msg)
        JSONRPCResponse(id: "server-error", error: err)
    }

    private func checkAcceptHeader(ctx: JoyContext): (Bool, Bool) {
        let accept = ctx.getHeader("accept") ?? ""
        let types = accept.split(",") |> map {s => s.trimAscii()} |> collectArrayList
        let hasJson = types |> any {s => s.startsWith(JoyHttpConsts.MIME_APP_JSON)}
        let hasSse = types |> any {s => s.startsWith(JoyHttpConsts.MIME_TEXT_EVENT_STREAM)}
        (hasJson, hasSse)
    }

    private func checkContentType(ctx: JoyContext): Bool {
        let contentType = ctx.getHeader("Content-Type") ?? ""
        let parts = contentType.split(";")[0].split(",") |> map {s => s.trimAscii()} |> collectArrayList
        parts |> any {s => s == JoyHttpConsts.MIME_APP_JSON}
    }

    private func handleMessage(ctx: JoyContext, message: JSONRPCMessage): Unit {
        match (message) {
            case m: JSONRPCRequest => handleRequest(ctx, m)
            case _ =>
                let session = validateSession(ctx)
                ctx.status(HttpStatusCode.STATUS_ACCEPTED)
                session?.handle(ctx, message)
        }
    }

    private func createTransport(ctx: JoyContext, sessionId: String): McpSseServerSessionTransport {
        let emitter = ctx.eventEmitter()
        let state = McpServerSessionState(sessionId, emitter)
        McpSseServerSessionTransport(emitter, state, _sessions, removeOnErr: false)
    }

    private func createSession(ctx: JoyContext, sessionId: String): DefaultMcpServerSession {
        if (_isJsonResp) {
            DefaultMcpServerSession(sessionId, this, _isJsonResp, true)
        } else {
            let transport = createTransport(ctx, sessionId)
            DefaultMcpServerSession(sessionId, transport, _isJsonResp, true)
        }
    }

    private func closeTransport(session: ?McpServerSession): Unit {
        if (let Some(s) <- session) {
            if (let Some(sess) <- (s as DefaultMcpServerSession)) {
                sess.closeTransport()
            }
        }
    }

    private func updateTransport(ctx: JoyContext, session: ?McpServerSession): Unit {
        if (let Some(s) <- session) {
            if (let Some(sess) <- (s as DefaultMcpServerSession)) {
                // update emitter for transport
                sess.updateTransport(createTransport(ctx, sess._sessionId))
            }
        }
    }

    private func waitEnd(session: ?McpServerSession): Unit {
        if (let Some(s) <- session) {
            if (let Some(sess) <- (s as DefaultMcpServerSession)) {
                if (let Some(t) <- (sess._transport as McpSseServerSessionTransport)) {
                    t._state.waitEnd()
                }
            }
        }
    }

    private func handleRequest(ctx: JoyContext, m: JSONRPCRequest): Unit {
        var session: ?McpServerSession = None
        if (m.method == McpConsts.METHOD_INITIALIZE) {
            session = validateSession(ctx, mustExist: false)
            if (session.isNone()) {
                let sessionId = secureRandStr(16)
                let sess = createSession(ctx, sessionId)
                @LogInfo("[MCP] create streamable session, sessionId: ${sessionId}")
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

    private func relayEvents(ctx: JoyContext, lastEventId: String): Unit {
        // TODO 
    }

    public func close() {
    }

    public func isClosed(): Bool {
        false
    }
}
