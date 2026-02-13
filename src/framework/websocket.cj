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
 * WebSocket message type enumeration
 */
public enum JoyWebSocketMsgType {
    WsText | WsBinary | WsPing
}

/**
 * WebSocket close status codes defined in RFC 6455 7.4.2
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
 * WebSocket handler interface for processing WebSocket messages
 */
public interface JoyWebSocketHandler {
    /**
     * Get supported sub-protocols
     * Default is empty, indicating not supported.
     * If configured, the top one in the upgrade request will be selected
     *
     * @return list of supported sub-protocol names
     */
    func supportedSubProtocols(): ArrayList<String> {
        ArrayList()
    }

    /**
     * Get whitelist of origins for handshake agreement
     * If not configured, all handshakes from any origin will be agreed upon
     * If configured, only handshakes from configured origins will be accepted
     *
     * @return list of allowed origin strings
     */
    func supportedOrigins(): ArrayList<String> {
        ArrayList()
    }

    /**
     * Check if frames should be merged
     * Accumulates data when receiving non-end frames, then calls onMessage when receiving end frame
     *
     * @return true to merge frames, false to handle each frame separately
     */
    func mergeFrames(): Bool {
        true
    }

    /**
     * Called after handshake is successful
     *
     * @param session WebSocket session instance
     */
    func onOpen(session: JoyWebSocketSession): Unit

    /**
     * Called when receiving a text or binary message
     *
     * @param session WebSocket session instance
     * @param message received WebSocket message
     */
    func onMessage(session: JoyWebSocketSession, message: JoyWebSocketMessage): Unit

    /**
     * Called when receiving a close message
     *
     * @param session WebSocket session instance
     * @param closeStatus close status code
     */
    func onClose(session: JoyWebSocketSession, closeStatus: UInt16): Unit

    /**
     * Called when receiving invalid message or an exception occurs
     *
     * @param session WebSocket session instance
     * @param ex exception that occurred
     */
    func onError(session: JoyWebSocketSession, ex: Exception): Unit
}

/**
 * WebSocket message wrapper
 */
public class JoyWebSocketMessage {
    private let _msgType: JoyWebSocketMsgType
    private let _isLast: Bool
    private let _data: Array<Byte>

    /**
     * Create WebSocket message
     *
     * @param msgType message type
     * @param isLast whether this is the last frame
     * @param data message payload bytes
     */
    init(msgType: JoyWebSocketMsgType, isLast: Bool, data: Array<Byte>) {
        _msgType = msgType
        _isLast = isLast
        _data = data
    }

    /**
     * Get whether this is the last message frame
     *
     * @return true if this is the last frame
     */
    public prop isLast: Bool {
        get() {
            _isLast
        }
    }

    /**
     * Get message type
     *
     * @return message type enumeration
     */
    public prop msgType: JoyWebSocketMsgType {
        get() {
            _msgType
        }
    }

    /**
     * Convert message data to text
     *
     * @return text string
     * @throws IllegalArgumentException if not a text message
     */
    public func asText(): String {
        match (_msgType) {
            case WsText => String.fromUtf8(_data)
            case _ => throw IllegalArgumentException("not is text message")
        }
    }

    /**
     * Convert message data to JSON deserialized object
     *
     * @return JSON object of type T, or None if deserialization fails
     * @throws IllegalArgumentException if not a text message
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
     * Convert message data to binary
     *
     * @return array of bytes
     * @throws IllegalArgumentException if not a binary message
     */
    public func asBinary(): Array<Byte> {
        match (_msgType) {
            case WsBinary => _data
            case _ => throw IllegalArgumentException("not is binary message")
        }
    }

    /**
     * Get raw message data bytes
     *
     * @return array of bytes
     */
    func data(): Array<Byte> {
        _data
    }

    /**
     * Create text message
     *
     * @param payload message text payload
     * @return WebSocket message instance
     */
    public static func createText(payload: String): JoyWebSocketMessage {
        JoyWebSocketMessage(WsText, true, payload.toArray())
    }

    /**
     * Create text message from JSON serializable object
     *
     * @param payload message payload which can be JSON serializable
     * @return WebSocket message instance
     */
    public static func createText<T>(payload: T): JoyWebSocketMessage where T <: JsonSerializable {
        let buffer = ByteBuffer()
        let writer = JsonWriter(buffer)
        writer.writeValue(payload)
        writer.flush()
        JoyWebSocketMessage(WsText, true, buffer.bytes())
    }

    /**
     * Create binary message
     *
     * @param payload message binary payload
     * @return WebSocket message instance
     */
    public static func createBinary(payload: Array<Byte>): JoyWebSocketMessage {
        JoyWebSocketMessage(WsBinary, true, payload)
    }

    /**
     * Create ping message
     *
     * @return WebSocket message instance with empty payload
     */
    public static func createPing(): JoyWebSocketMessage {
        JoyWebSocketMessage(WsPing, true, Array<UInt8>(5, repeat: 0))
    }
}

/**
 * WebSocket session representing a WebSocket connection
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
     * Create WebSocket session
     *
     * @param ws underlying WebSocket connection
     * @param config Joy configuration
     * @param headers handshake HTTP headers
     * @param query URL query parameters
     * @param paramMap URL path parameters
     * @param ctxParamMap context parameters
     * @param services service container
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
     * Get negotiated sub-protocol with the other party
     *
     * @return sub-protocol string
     */
    public prop subProtocol: String {
        get() {
            _ws.subProtocol
        }
    }

    /**
     * Get handshake header value
     *
     * @param name header name
     * @return header value, or None if not found
     */
    public func getHeader(name: String): ?String {
        _headers.getFirst(name)
    }

    /**
     * Get all handshake header values
     *
     * @param name header name
     * @return collection of header values
     */
    public func getHeaderList(name: String): Collection<String> {
        _headers.get(name)
    }

    /**
     * Get handshake URL path parameter
     *
     * @param name parameter name
     * @return parameter value, or None if not found
     */
    public func getParam(name: String): ?String {
        _paramMap.get(name)
    }

    /**
     * Get handshake context parameter
     *
     * @param key parameter key name
     * @return parameter value, or None if not found
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
     * Get handshake URL query parameter
     *
     * @param name query parameter name
     * @return parameter value, or None if not found
     */
    public func getQuery(name: String): ?String {
        _query.get(name)
    }

    /**
     * Get all handshake URL query parameters
     *
     * @param name query parameter name
     * @return list of query parameter values
     */
    public func getQueryList(name: String): ArrayList<String> {
        _query.getAll(name)
    }

    /**
     * Send close frame with default status (1000) and close connection
     */
    public func close(): Unit {
        _ws.writeCloseFrame(status: JoyWebSocketCloseStatus.NORMAL, reason: "")
        _ws.closeConn()
    }

    /**
     * Send close frame with specified status and close connection
     *
     * @param closeStatus close status code
     * @param reason close reason string
     */
    public func close(closeStatus: UInt16, reason: String): Unit {
        _ws.writeCloseFrame(status: closeStatus, reason: reason)
        _ws.closeConn()
    }

    /**
     * Send WebSocket message
     *
     * @param message WebSocket message to send
     */
    public func send(message: JoyWebSocketMessage): Unit {
        match (message.msgType) {
            case WsText => _ws.write(WebSocketFrameType.TextWebFrame, message.data())
            case WsBinary => _ws.write(WebSocketFrameType.BinaryWebFrame, message.data())
            case WsPing => _ws.writePingFrame(message.data())
        }
    }

    /**
     * Send text message to WebSocket
     *
     * @param text text message to send
     */
    public func send(text: String): Unit {
        send(JoyWebSocketMessage.createText(text))
    }

    /**
     * Send binary message to WebSocket
     *
     * @param data binary message bytes to send
     */
    public func send(data: Array<Byte>): Unit {
        send(JoyWebSocketMessage.createBinary(data))
    }

    /**
     * Send JSON message to WebSocket
     *
     * @param json JSON serializable object to send
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

        if (isOpen) {
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
