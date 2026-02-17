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
import std.io.ByteBuffer
import std.time.DateTime
import stdx.net.http.HttpStatusCode
import cjoy.framework.{JoyContext, JoySseEmitter, JoySseBuilder}
import cjoy.utils.secureRandStr
import cjoy.mcp.api.*
import cjoy.jsonrpc.{JSONRPCError, JSONRPCConsts, JSONRPCTool}
import cjoy.log.macros.*

/**
 * MCP server transport for Server-Sent Events (SSE) communication
 *
 * Handles incoming SSE connections and message exchange between MCP server and clients
 * using SSE protocol for real-time communication.
 */
class McpSseServerTransport <: McpServerTransport {
    /**
     * ConcurrentHashMap for storing active server sessions
     */
    private let _sessions: ConcurrentHashMap<String, McpServerSession> = ConcurrentHashMap()

    /**
     * The endpoint for message exchange
     */
    private let _messageEndpoint: String

    /**
     * Initializes a new McpSseServerTransport
     *
     * @param messageEndpoint The endpoint for message exchange
     */
    init(messageEndpoint: String) {
        this._messageEndpoint = messageEndpoint
    }

    /**
     * Handles incoming SSE requests
     *
     * @param ctx The JoyContext for the request
     */
    public func handleSseRequest(ctx: JoyContext): Unit {
        @JoyLogInfo("[MCP] recv sse request from ${ctx.getClientIP()}")
        let emitter = ctx.eventEmitter()
        // create session
        let sessionId = secureRandStr(16)
        let state = McpServerSessionState(sessionId, emitter)
        let transport = McpSseServerSessionTransport(emitter, state, _sessions)
        let session = DefaultMcpServerSession(sessionId, transport, false, false)
        _sessions.add(sessionId, session)

        // notify endpoint
        try {
            let data = "${_messageEndpoint}?sessionId=${sessionId}"
            sendEvent(emitter, McpConsts.EVENT_ENDPOINT, data)
            @JoyLogInfo("[MCP] send sse endpoint ${data} to session: ${sessionId}")
        } catch (ex: Exception) {
            _sessions.remove(sessionId)
            @JoyLogError("[MCP] failed to sse message to session: ${sessionId}, error: ${ex.message}")
            let err = JSONRPCError(code: JSONRPCConsts.ERR_INTERNAL_ERROR, message: ex.message)
            ctx.status(HttpStatusCode.STATUS_INTERNAL_SERVER_ERROR).json(err)
            return
        }

        // blocking
        state.waitEnd()
        _sessions.remove(sessionId)
    }

    /**
     * Handles incoming POST requests for message exchange
     *
     * @param ctx The JoyContext for the request
     */
    public func handlePostRequest(ctx: JoyContext): Unit {
        let sessionId = ctx.getQuery("sessionId", "")
        if (sessionId == "") {
            let err = JSONRPCError(code: JSONRPCConsts.ERR_INVALID_PARAMS, message: "sessionId missing in url")
            ctx.status(HttpStatusCode.STATUS_BAD_REQUEST).json(err)
            return
        }

        // find session by id
        let session = _sessions.get(sessionId)
        if (let Some(sess) <- session) {
            // call method handle
            let data = ctx.readRawData()
            let message = JSONRPCTool.deserialize(data)
            try {
                sess.handle(ctx, message)
                ctx.ok()
            } catch (ex: Exception) {
                @JoyLogError("[MCP] handle message faild, session: ${sessionId}, error: ${ex.message}")
                let err = JSONRPCError(code: JSONRPCConsts.ERR_INTERNAL_ERROR, message: ex.message)
                ctx.status(HttpStatusCode.STATUS_INTERNAL_SERVER_ERROR).json(err)
            }
        } else {
            @JoyLogError("[MCP] not found sesson, session: ${sessionId}")
            let err = JSONRPCError(code: JSONRPCConsts.ERR_INVALID_PARAMS, message: "session not found")
            ctx.status(HttpStatusCode.STATUS_NOT_FOUND).json(err)
        }
    }

    /**
     * Sends a message through this transport (not implemented for SSE)
     *
     * @param message The message to send
     */
    public func send(_: ByteBuffer): Unit {
        // nothing
    }

    /**
     * Closes the transport
     */
    public func close(): Unit {
    }

    /**
     * Checks if the transport is closed
     *
     * @return Always false for SSE transport
     */
    public func isClosed(): Bool {
        false
    }
}

/**
 * MCP server session transport for Server-Sent Events (SSE) communication
 *
 * Manages communication between server and client over an SSE connection for a specific session.
 */
class McpSseServerSessionTransport <: McpTransport {
    /**
     * The SSE emitter for sending events to client
     */
    let _emitter: JoySseEmitter

    /**
     * The session state manager
     */
    let _state: McpServerSessionState

    /**
     * Reference to all active sessions
     */
    let _sessions: ConcurrentHashMap<String, McpServerSession>

    /**
     * Time of last message sent
     */
    private var _lastMsgTime: DateTime = DateTime.now()

    /**
     * Flag indicating if transport is running
     */
    private var _running: Bool = true

    /**
     * Flag indicating if transport is closed
     */
    private var _isClosed: Bool = false

    /**
     * Flag indicating if session should be removed on error
     */
    private let _removeOnErr: Bool

    /**
     * Initializes a new McpSseServerSessionTransport
     *
     * @param emitter The SSE emitter for this session
     * @param state The session state manager
     * @param sessions Reference to all active sessions
     * @param removeOnErr Whether to remove session on error (default: true)
     */
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

    /**
     * Closes the session transport
     */
    public func close(): Unit {
        if (_isClosed) {
            return
        }
        _state.compete()
        _isClosed = true
    }

    /**
     * Checks if the transport is closed
     *
     * @return True if transport is closed, false otherwise
     */
    public func isClosed(): Bool {
        _isClosed
    }

    /**
     * Sends a ping event to keep the SSE connection alive
     */
    private func sendPing(): Unit {
        try {
            _emitter.sendEvent(JoySseBuilder().comment("ping"))
        } catch (ex: Exception) {
            _running = false
            if (_removeOnErr) {
                _sessions.remove(_state.sessionId)
            }
            _state.compete()
        }
    }

    /**
     * Sends a message through the SSE transport
     *
     * @param message The message to send as ByteBuffer
     */
    public func send(message: ByteBuffer): Unit {
        let data = String.fromUtf8(message.bytes())
        send(data)
    }

    /**
     * Sends a message through the SSE transport
     *
     * @param data The message to send as string
     */
    public func send(data: String): Unit {
        try {
            sendEvent(_emitter, McpConsts.EVENT_MESSAGE, data)
            @JoyLogDebug("[MCP] send sse message ${data} to session: ${_state.sessionId}")
            _lastMsgTime = DateTime.now()
        } catch (ex: Exception) {
            @JoyLogError("[MCP] failed to sse message to session: ${_state.sessionId}, error: ${ex.message}")
            _running = false
            if (_removeOnErr) {
                _sessions.remove(_state.sessionId)
            }
            _state.compete()
        }
    }
}

/**
 * Helper function to send an SSE event
 *
 * @param emitter The SSE emitter to use
 * @param eventType The type of event
 * @param data The event data
 */
func sendEvent(emitter: JoySseEmitter, eventType: String, data: String) {
    emitter.sendEvent(JoySseBuilder().event(eventType).data(data))
}
