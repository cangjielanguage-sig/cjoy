/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.framework

import std.collection.{ArrayList, HashMap}
import std.io.ByteBuffer
import stdx.net.http.{WebSocket, WebSocketException, WebSocketFrame, WebSocketFrameType, HttpHeaders}
import stdx.encoding.url.Form
import stdx.encoding.json.stream.{JsonDeserializable, JsonSerializable, JsonReader, JsonWriter}
import cjoy.context.{Context, ServiceContainer}
import cjoy.log.macros.*

/**
 * WebSocket 消息类型枚举
 */
public enum JoyWebSocketMsgType {
    WsText | WsBinary | WsPing
}

/**
 * RFC 6455 7.4.2 定义的 WebSocket 关闭状态码
 */
public struct JoyWebSocketCloseStatus {
    public static const NORMAL: UInt16 = 1000
    public static const GOING_AWAY: UInt16 = 1001
    public static const PROTOCOL_ERROR: UInt16 = 1002
    public static const NOT_ACCEPTABLE: UInt16 = 1003
    public static const NO_BAD_DATA: UInt16 = 1007
    public static const POLICY_VIOLATION: UInt16 = 1008
    public static const TOO_BIG_TO_PROCESS: UInt16 = 1009
    public static const REQUIRED_EXTENSION: UInt16 = 1010
    public static const SERVER_ERROR: UInt16 = 1011
    public static const SERVICE_RESTARTED: UInt16 = 1012
    public static const SERVICE_OVERLOAD: UInt16 = 1013
    public static const SESSION_NOT_RELIABLE: UInt16 = 4500
}

/**
 * 用于处理 WebSocket 消息的 WebSocket 处理器接口
 */
public interface JoyWebSocketHandler {
    /**
     * 获取支持的子协议
     * 默认为空，表示不支持。
     * 如果配置，升级请求中的第一个将被选择
     *
     * @return 支持的子协议名称列表
     */
    func supportedSubProtocols(): ArrayList<String> {
        ArrayList()
    }

    /**
     * 获取握手协议的来源白名单
     * 如果未配置，将接受来自任何来源的握手
     * 如果配置，仅接受来自配置来源的握手
     *
     * @return 允许的来源字符串列表
     */
    func supportedOrigins(): ArrayList<String> {
        ArrayList()
    }

    /**
     * 检查是否应该合并帧
     * 在接收非结束帧时累积数据，在接收到结束帧时调用 onMessage
     *
     * @return true 合并帧，false 分别处理每个帧
     */
    func mergeFrames(): Bool {
        true
    }

    /**
     * 握手成功后调用
     *
     * @param session WebSocket 会话实例
     */
    func onOpen(session: JoyWebSocketSession): Unit

    /**
     * 接收到文本或二进制消息时调用
     *
     * @param session WebSocket 会话实例
     * @param message 接收到的 WebSocket 消息
     */
    func onMessage(session: JoyWebSocketSession, message: JoyWebSocketMessage): Unit

    /**
     * 接收到关闭消息时调用
     *
     * @param session WebSocket 会话实例
     * @param closeStatus 关闭状态码
     */
    func onClose(session: JoyWebSocketSession, closeStatus: UInt16): Unit

    /**
     * 接收到无效消息或发生异常时调用
     *
     * @param session WebSocket 会话实例
     * @param ex 发生的异常
     */
    func onError(session: JoyWebSocketSession, ex: Exception): Unit
}

/**
 * WebSocket 消息包装器
 */
public class JoyWebSocketMessage {
    private let _msgType: JoyWebSocketMsgType
    private let _isLast: Bool
    private let _data: Array<Byte>

    /**
     * 创建 WebSocket 消息
     *
     * @param msgType 消息类型
     * @param isLast 是否为最后一帧
     * @param data 消息负载字节
     */
    init(msgType: JoyWebSocketMsgType, isLast: Bool, data: Array<Byte>) {
        _msgType = msgType
        _isLast = isLast
        _data = data
    }

    /**
     * 获取是否为最后一帧消息
     *
     * @return 如果为最后一帧返回 true
     */
    public prop isLast: Bool {
        get() {
            _isLast
        }
    }

    /**
     * 获取消息类型
     *
     * @return 消息类型枚举
     */
    public prop msgType: JoyWebSocketMsgType {
        get() {
            _msgType
        }
    }

    /**
     * 将消息数据转换为文本
     *
     * @return 文本字符串
     * @throws IllegalArgumentException 如果不是文本消息
     */
    public func asText(): String {
        match (_msgType) {
            case WsText => String.fromUtf8(_data)
            case _ => throw IllegalArgumentException("not is text message")
        }
    }

    /**
     * 将消息数据转换为 JSON 反序列化对象
     *
     * @return 类型为 T 的 JSON 对象，若反序列化失败返回 None
     * @throws IllegalArgumentException 如果不是文本消息
     */
    public func asJsonToObj<T>(): ?T where T <: JsonDeserializable<T> {
        match (_msgType) {
            case WsText =>
                let stream = ByteBuffer()
                stream.write(_data)
                let reader = JsonReader(stream)
                T.fromJson(reader)
            case _ => throw IllegalArgumentException("not is text message")
        }
    }

    /**
     * 将消息数据转换为二进制
     *
     * @return 字节数组
     * @throws IllegalArgumentException 如果不是二进制消息
     */
    public func asBinary(): Array<Byte> {
        match (_msgType) {
            case WsBinary => _data
            case _ => throw IllegalArgumentException("not is binary message")
        }
    }

    /**
     * 获取原始消息数据字节
     *
     * @return 字节数组
     */
    func data(): Array<Byte> {
        _data
    }

    /**
     * 创建文本消息
     *
     * @param payload 文本消息负载
     * @return WebSocket 消息实例
     */
    public static func createText(payload: String): JoyWebSocketMessage {
        JoyWebSocketMessage(WsText, true, payload.toArray())
    }

    /**
     * 从 JSON 序列化对象创建文本消息
     *
     * @param payload 可以序列化为 JSON 的对象
     * @return WebSocket 消息实例
     */
    public static func createText<T>(payload: T): JoyWebSocketMessage where T <: JsonSerializable {
        let buffer = ByteBuffer()
        let writer = JsonWriter(buffer)
        writer.writeValue(payload)
        writer.flush()
        JoyWebSocketMessage(WsText, true, buffer.bytes())
    }

    /**
     * 创建二进制消息
     *
     * @param payload 二进制消息负载
     * @return WebSocket 消息实例
     */
    public static func createBinary(payload: Array<Byte>): JoyWebSocketMessage {
        JoyWebSocketMessage(WsBinary, true, payload)
    }

    /**
     * 创建 Ping 消息
     *
     * @return 具有空载荷的 WebSocket 消息实例
     */
    public static func createPing(): JoyWebSocketMessage {
        JoyWebSocketMessage(WsPing, true, Array<UInt8>(5, repeat: 0))
    }
}

    /**
     * 表示一个 WebSocket 连接的会话
     */
public class JoyWebSocketSession <: Context {
    private let _ws: WebSocket
    private let _config: JoyConfig
    private let _headers: HttpHeaders
    private let _paramMap: HashMap<String, String>
    private let _ctxParamMap: HashMap<String, Any>
    private let _query: Form
    private let _services: ServiceContainer

    /**
     * 创建 WebSocket 会话
     *
     * @param ws 底层 WebSocket 连接
     * @param config Joy 配置
     * @param headers 握手 HTTP 头
     * @param query URL 查询参数
     * @param paramMap URL 路径参数
     * @param ctxParamMap 上下文参数
     * @param services 服务容器
     */
    init(ws: WebSocket, config: JoyConfig, headers: HttpHeaders, query: Form, paramMap: HashMap<String, String>,
        ctxParamMap: HashMap<String, Any>, services: ServiceContainer) {
        _ws = ws
        _config = config
        _headers = headers
        _query = query
        _paramMap = paramMap
        _ctxParamMap = ctxParamMap
        _services = services
    }

    /**
     * 获取与对端协商的子协议
     *
     * @return 子协议字符串
     */
    public prop subProtocol: String {
        get() {
            _ws.subProtocol
        }
    }

    /**
     * 获取握手头部值
     *
     * @param name 头字段名
     * @return 头字段值，若未找到则返回 None
     */
    public func getHeader(name: String): ?String {
        _headers.getFirst(name)
    }

    /**
     * 获取所有握手头部值
     *
     * @param name 头字段名
     * @return 头字段值集合
     */
    public func getHeaderList(name: String): Collection<String> {
        _headers.get(name)
    }

    /**
     * 获取握手 URL 路径参数
     *
     * @param name 参数名
     * @return 参数值，若未找到则返回 None
     */
    public func getParam(name: String): ?String {
        _paramMap.get(name)
    }

    /**
     * 获取握手上下文参数
     *
     * @param key 键名
     * @return 参数值，若未找到则返回 None
     */
    public func getCtxParam<T>(key: String): ?T {
        get<T>(key)
    }

    public func set(key: String, value: Any): Unit {
        _ctxParamMap.add(key, value)
    }

    public func get<T>(key: String): ?T {
        (_ctxParamMap.get(key) ?? Option<Any>.None) as T
    }

    public func remove(key: String): Unit {
        _ctxParamMap.remove(key)
    }

    public func getService<T>(name: String): ?T {
        _services.getService<T>(name)
    }

    /**
     * 获取握手 URL 查询参数
     *
     * @param name 查询参数名
     * @return 参数值，若未找到则返回 None
     */
    public func getQuery(name: String): ?String {
        _query.get(name)
    }

    /**
     * 获取所有握手 URL 查询参数
     *
     * @param name 查询参数名
     * @return 查询参数值列表
     */
    public func getQueryList(name: String): ArrayList<String> {
        _query.getAll(name)
    }

    /**
     * 发送带默认状态码（1000）的关闭帧并关闭连接
     */
    public func close(): Unit {
        _ws.writeCloseFrame(status: JoyWebSocketCloseStatus.NORMAL, reason: "")
        _ws.closeConn()
    }

    /**
     * 发送带指定状态码的关闭帧并关闭连接
     *
     * @param closeStatus 关闭状态码
     * @param reason 关闭原因字符串
     */
    public func close(closeStatus: UInt16, reason: String): Unit {
        _ws.writeCloseFrame(status: closeStatus, reason: reason)
        _ws.closeConn()
    }

    /**
     * 发送 WebSocket 消息
     *
     * @param message 要发送的 WebSocket 消息
     */
    public func send(message: JoyWebSocketMessage): Unit {
        match (message.msgType) {
            case WsText => _ws.write(WebSocketFrameType.TextWebFrame, message.data())
            case WsBinary => _ws.write(WebSocketFrameType.BinaryWebFrame, message.data())
            case WsPing => _ws.writePingFrame(message.data())
        }
    }

    /**
     * 向 WebSocket 发送文本消息
     *
     * @param text 要发送的文本消息
     */
    public func send(text: String): Unit {
        send(JoyWebSocketMessage.createText(text))
    }

    /**
     * 向 WebSocket 发送二进制消息
     *
     * @param data 要发送的二进制字节
     */
    public func send(data: Array<Byte>): Unit {
        send(JoyWebSocketMessage.createBinary(data))
    }

    /**
     * 向 WebSocket 发送 JSON 消息
     *
     * @param json 要发送的 JSON 可序列化对象
     */
    public func send<T>(json: T): Unit where T <: JsonSerializable {
        send(JoyWebSocketMessage.createText(json))
    }
}

class JoyWebSocketUpgradeHandler <: JoyRequestHandler {
    public JoyWebSocketUpgradeHandler(let handler: JoyWebSocketHandler) {}

    public func handle(ctx: JoyContext): Unit {
        let websocket = WebSocket.upgradeFromServer(
            ctx.httpContext,
            subProtocols: handler.supportedSubProtocols(),
            origins: handler.supportedOrigins()
        )

        @JoyLogDebug("[WebSocket] upgrade websocket success from ${ctx.getClientIP()}")

        let ctxHttp = (ctx as JoyHttpContext).getOrThrow()
        let req = ctx.httpContext.request
        let session = JoyWebSocketSession(websocket, ctx.config, req.headers, req.url.queryForm.clone(),
            ctxHttp.copyParams(), ctxHttp.copyCtxParams(), ctxHttp._services)

        // release context and http framework thread
        spawn {
            handleReceive(session, websocket)
        }
    }

    private func handleReceive(session: JoyWebSocketSession, websocket: WebSocket) {
        var isOpen = true
        var closedByPeer = false
        let buffer = ByteBuffer()

        handler.onOpen(session)

        var msgType = JoyWebSocketMsgType.WsPing
        while (isOpen) {
            try {
                var frame = websocket.read()
                match (frame.frameType) {
                    case ContinuationWebFrame => handleContinuationWebFrame(session, buffer, msgType, frame)
                    case TextWebFrame | BinaryWebFrame => msgType = handleTextAndBinaryWebFrame(session, buffer, frame)
                    case CloseWebFrame =>
                        handleCloseWebFrame(session, frame)
                        closedByPeer = true
                        isOpen = false
                    case PingWebFrame => websocket.writePongFrame(frame.payload)
                    case _ => ()
                }
            } catch (ex: Exception) {
                @JoyLogWarn("[WebSocket] read frame from websocket occurs an error, message=${ex.message}")
                handler.onError(session, ex)
                isOpen = false
            }
        }

        if (closedByPeer) {
            // 对端发起关闭，回复关闭帧后关闭连接
            session.close()
        } else {
            websocket.closeConn()
        }
    }

    private func handleContinuationWebFrame(session: JoyWebSocketSession, buffer: ByteBuffer,
        msgType: JoyWebSocketMsgType, frame: WebSocketFrame): Unit {
        if (handler.mergeFrames()) {
            buffer.write(frame.payload)
            if (frame.fin) {
                handler.onMessage(session, JoyWebSocketMessage(msgType, true, buffer.bytes()))
                buffer.clear()
            }
        } else {
            handler.onMessage(session, JoyWebSocketMessage(msgType, frame.fin, frame.payload))
        }
    }

    private func handleTextAndBinaryWebFrame(session: JoyWebSocketSession, buffer: ByteBuffer, frame: WebSocketFrame): JoyWebSocketMsgType {
        let msgType = if (frame.frameType == TextWebFrame) {
            JoyWebSocketMsgType.WsText
        } else {
            JoyWebSocketMsgType.WsBinary
        }

        buffer.clear()
        if (handler.mergeFrames()) {
            if (frame.fin) {
                handler.onMessage(session, JoyWebSocketMessage(msgType, true, frame.payload))
            } else {
                buffer.write(frame.payload)
            }
        } else {
            handler.onMessage(session, JoyWebSocketMessage(msgType, frame.fin, frame.payload))
        }
        msgType
    }

    private func handleCloseWebFrame(session: JoyWebSocketSession, frame: WebSocketFrame): Unit {
        match {
            case frame.payload.size == 0 =>
                @JoyLogDebug("[WebSocket] receive empty close status")
                handler.onClose(session, JoyWebSocketCloseStatus.NORMAL)
            case frame.payload.size <= 125 && frame.payload.size > 1 =>
                let statusCode = toUInt16(frame.payload[0..2])
                @JoyLogDebug("[WebSocket] receive close status code, ${statusCode}")
                handler.onClose(session, statusCode)
            case _ =>
                @JoyLogWarn("[WebSocket] receive invalid close status code")
                handler.onError(session, WebSocketException("invalid close status code"))
        }
    }

    private static func toUInt16(bytes: Array<Byte>): UInt16 {
        var val: UInt16 = 0
        for (byte in bytes) {
            val = val << 8
            val = val | UInt16(byte)
        }
        val
    }
}
