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
 * 用于服务器发送事件（SSE）通信的 MCP 服务器传输
 *
 * 处理传入的 SSE 连接和 MCP 服务器与客户端之间的消息交换，
 * 使用 SSE 协议进行实时通信。
 */
class McpSseServerTransport <: McpServerTransport {
    /**
     * 用于存储活动服务器会话的 ConcurrentHashMap
     */
    private let _sessions: ConcurrentHashMap<String, SessionInfo> = ConcurrentHashMap()

    /**
     * 消息交换的端点
     */
    private let _messageEndpoint: String

    /**
     * 指示是否禁用 localhost 的 DNS 重绑定保护的标志
     */
    private let _disableLocalhostProtection: Bool

    /**
     * 初始化新的 McpSseServerTransport
     *
     * @param messageEndpoint 消息交换的端点
     * @param disableLocalhostProtection 是否禁用 localhost 的 DNS 重绑定保护（默认：false）
     */
    init(messageEndpoint: String, disableLocalhostProtection!: Bool = false) {
        this._messageEndpoint = messageEndpoint
        this._disableLocalhostProtection = disableLocalhostProtection
    }

    /**
     * 处理传入的 SSE 请求
     *
     * @param ctx 请求的 JoyContext
     */
    public func handleSseRequest(ctx: JoyContext): Unit {
        if (!validateLocalhostProtection(ctx, _disableLocalhostProtection)) {
            return
        }

        @JoyLogInfo("[MCP] recv sse request from ${ctx.getClientIP()}")
        let emitter = ctx.eventEmitter()
        // create session
        let sessionId = secureRandStr(16)
        let state = McpServerSessionState(sessionId, emitter)
        let transport = McpSseServerSessionTransport(emitter, state, _sessions)
        let session = DefaultMcpServerSession(sessionId, transport, false, false)
        _sessions.add(sessionId, SessionInfo(session, getUserIDFromContext(ctx)))

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
     * 处理传入的 POST 请求进行消息交换
     *
     * @param ctx 请求的 JoyContext
     */
    public func handlePostRequest(ctx: JoyContext): Unit {
        if (!validateLocalhostProtection(ctx, _disableLocalhostProtection)) {
            return
        }

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
                sess.session.handle(ctx, message)
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
     * 通过此传输发送消息（SSE 未实现）
     *
     * @param message 要发送的消息
     */
    public func send(_: ByteBuffer): Unit {
        // nothing
    }

    /**
     * 关闭传输
     */
    public func close(): Unit {
    }

    /**
     * 检查传输是否已关闭
     *
     * @return SSE 传输始终返回 false
     */
    public func isClosed(): Bool {
        false
    }
}

/**
 * 用于服务器发送事件（SSE）通信的 MCP 服务器会话传输
 *
 * 管理特定会话中服务器与客户端通过 SSE 连接的通信。
 */
class McpSseServerSessionTransport <: McpTransport {
    /**
     * 用于向客户端发送事件的 SSE 发射器
     */
    let _emitter: JoySseEmitter

    /**
     * 会话状态管理器
     */
    let _state: McpServerSessionState

    /**
     * 对所有活动会话的引用
     */
    let _sessions: ConcurrentHashMap<String, SessionInfo>

    /**
     * 最后发送消息的时间
     */
    private var _lastMsgTime: DateTime = DateTime.now()

    /**
     * 指示传输是否正在运行的标志
     */
    private var _running: Bool = true

    /**
     * 指示传输是否已关闭的标志
     */
    private var _isClosed: Bool = false

    /**
     * 指示发生错误时是否应移除会话的标志
     */
    private let _removeOnErr: Bool

    /**
     * 初始化新的 McpSseServerSessionTransport
     *
     * @param emitter 此会话的 SSE 发射器
     * @param state 会话状态管理器
     * @param sessions 对所有活动会话的引用
     * @param removeOnErr 发生错误时是否移除会话（默认：true）
     */
    init(emitter: JoySseEmitter, state: McpServerSessionState, sessions: ConcurrentHashMap<String, SessionInfo>,
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
     * 关闭会话传输
     */
    public func close(): Unit {
        if (_isClosed) {
            return
        }
        _state.compete()
        _isClosed = true
    }

    /**
     * 检查传输是否已关闭
     *
     * @return 如果传输已关闭返回 true，否则返回 false
     */
    public func isClosed(): Bool {
        _isClosed
    }

    /**
     * 发送 ping 事件以保持 SSE 连接活跃
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
     * 通过 SSE 传输发送消息
     *
     * @param message 要发送的消息，类型为 ByteBuffer
     */
    public func send(message: ByteBuffer): Unit {
        let data = String.fromUtf8(message.bytes())
        send(data)
    }

    /**
     * 通过 SSE 传输发送消息
     *
     * @param data 要发送的消息，类型为字符串
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
 * 发送 SSE 事件的辅助函数
 *
 * @param emitter 要使用的 SSE 发射器
 * @param eventType 事件类型
 * @param data 事件数据
 */
func sendEvent(emitter: JoySseEmitter, eventType: String, data: String) {
    emitter.sendEvent(JoySseBuilder().event(eventType).data(data))
}
