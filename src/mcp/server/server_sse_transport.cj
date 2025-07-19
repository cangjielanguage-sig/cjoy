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
import std.io.ByteBuffer
import std.time.DateTime
import std.sync.SyncCounter
import stdx.net.http.HttpStatusCode
import cjoy.framework.{JoyContext, JoySseEmitter, JoyServerEventBuilder}
import cjoy.utils.randStr
import cjoy.mcp.api.*
import cjoy.log.LogTool

class McpSseServerTransport <: McpServerTransport {
    private let _sessions: ConcurrentHashMap<String, McpServerSession> = ConcurrentHashMap()
    private let _messageEndpoint: String

    init(messageEndpoint: String) {
        this._messageEndpoint = messageEndpoint
    }

    public func handleSseRequest(ctx: JoyContext): Unit {
        LogTool.info("[MCP] recv sse request from ${ctx.getClientIP()}")
        let emitter = ctx.eventEmitter()
        // create session
        let sessionId = randStr(16)
        let state = McpServerSessionState(sessionId, emitter)
        let transport = McpSseServerSessionTransport(emitter, state, _sessions)
        let session = DefaultMcpServerSession(sessionId, transport, false, false)
        _sessions.add(sessionId, session)

        // notify endpoint
        try {
            let data = "${_messageEndpoint}?sessionId=${sessionId}"
            sendEvent(emitter, McpConsts.EVENT_ENDPOINT, data)
            LogTool.info("[MCP] send sse endpoint ${data} to session: ${sessionId}")
        } catch (ex: Exception) {
            _sessions.remove(sessionId)
            LogTool.error("[MCP] failed to sse message to session: ${sessionId}, error: ${ex.message}")
            let err = JSONRPCError(code: McpConsts.ERR_INTERNAL_ERROR, message: ex.message)
            ctx.status(HttpStatusCode.STATUS_INTERNAL_SERVER_ERROR).json(err)
            return
        }

        // blocking
        state.waitEnd()
        _sessions.remove(sessionId)
    }

    public func handlePostRequest(ctx: JoyContext): Unit {
        let sessionId = ctx.getQuery("sessionId", "")
        if (sessionId == "") {
            let err = JSONRPCError(code: McpConsts.ERR_INVALID_PARAMS, message: "sessionId missing in url")
            ctx.status(HttpStatusCode.STATUS_BAD_REQUEST).json(err)
            return
        }

        // find session by id
        let session = _sessions.get(sessionId)
        if (let Some(sess) <- session) {
            // call method handle
            let data = ctx.readRawData()
            let message = RPCJsonTool.deserialize(data)
            try {
                sess.handle(ctx, message)
                ctx.ok()
            } catch (ex: Exception) {
                LogTool.error("[MCP] handle message faild, session: ${sessionId}, error: ${ex.message}")
                let err = JSONRPCError(code: McpConsts.ERR_INTERNAL_ERROR, message: ex.message)
                ctx.status(HttpStatusCode.STATUS_INTERNAL_SERVER_ERROR).json(err)
            }
        } else {
            LogTool.error("[MCP] not found sesson, session: ${sessionId}")
            let err = JSONRPCError(code: McpConsts.ERR_INVALID_PARAMS, message: "session not found")
            ctx.status(HttpStatusCode.STATUS_NOT_FOUND).json(err)
        }
    }

    public func send(message: ByteBuffer): Unit {
        // nothing
    }

    public func close() {
    }

    public func isClosed(): Bool {
        false
    }
}

class McpSseServerSessionTransport <: McpTransport {
    let _emitter: JoySseEmitter
    let _state: McpServerSessionState
    let _sessions: ConcurrentHashMap<String, McpServerSession>
    private var _lastMsgTime: DateTime = DateTime.now()
    private var _running: Bool = true
    private var _isClosed: Bool = false
    private let _removeOnErr: Bool

    init(emitter: JoySseEmitter, state: McpServerSessionState, sessions: ConcurrentHashMap<String, McpServerSession>,
        removeOnErr!: Bool = true) {
        _emitter = emitter
        _state = state
        _sessions = sessions
        _removeOnErr = removeOnErr

        _emitter.header(McpConsts.HEADER_MCP_SESSION_ID, _state.sessionId)
        spawn {
            while (_running) {
                sleep(5 * Duration.second)
                if (_lastMsgTime.addSeconds(5) < DateTime.now()) {
                    sendPing()
                }
            }
        }
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

    private func sendPing(): Unit {
        try {
            _emitter.sendEvent(JoyServerEventBuilder().comment("ping"))
        } catch (ex: Exception) {
            _running = false
            if (_removeOnErr) {
                _sessions.remove(_state.sessionId)
            }
            _state.compete()
        }
    }

    public func send(message: ByteBuffer): Unit {
        let data = String.fromUtf8(message.bytes())
        send(data)
    }

    public func send(data: String): Unit {
        try {
            sendEvent(_emitter, McpConsts.EVENT_MESSAGE, data)
            LogTool.debug("[MCP] send sse message ${data} to session: ${_state.sessionId}")
            _lastMsgTime = DateTime.now()
        } catch (ex: Exception) {
            LogTool.error("[MCP] failed to sse message to session: ${_state.sessionId}, error: ${ex.message}")
            _running = false
            if (_removeOnErr) {
                _sessions.remove(_state.sessionId)
            }
            _state.compete()
        }
    }
}

func sendEvent(emitter: JoySseEmitter, eventType: String, data: String) {
    emitter.sendEvent(JoyServerEventBuilder().event(eventType).data(data))
}
