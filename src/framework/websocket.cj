/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
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
import stdx.net.http.{WebSocket, WebSocketException, WebSocketFrameType, HttpHeaders}
import stdx.encoding.url.Form
import stdx.encoding.json.stream.{JsonDeserializable, JsonSerializable, JsonReader, JsonWriter}
import cjoy.log.*

/**
 * the websocket message type.
 */
public enum JoyWebSocketMsgType {
    WsText | WsBinary | WsPing
}

/**
 * some status code define in RFC 6455 7.4.2
 */
public struct JoyWebSocketCloseStatus {
    public static const NORMAL: UInt16 = 1000
    public static const GOING_AWAY: UInt16 = 1001
    public static const PROTOCAL_ERROR: UInt16 = 1002
    public static const NOT_ACCEPTABLE: UInt16 = 1003
    public static const NO_BAD_DATA: UInt16 = 1007
    public static const POLICY_VIOLATION: UInt16 = 1008
    public static const TO_BIG_TO_PROCESS: UInt16 = 1009
    public static const REQUIRED_EXTENSION: UInt16 = 1010
    public static const SERVER_ERROR: UInt16 = 1011
    public static const SERVICE_RESTARTED: UInt16 = 1012
    public static const SERVICE_OVERLOAD: UInt16 = 1013
    public static const SESSION_NOT_RELIABLE: UInt16 = 4500
}

/**
 * implementate the interface to processes websocket messages.
 */
public interface JoyWebSocketHandler {
    /*
     * the sub protocol list configured by the user has a default value of empty,
     * indicating that it is not supported. If the user has configured it,
     * the top one in the upgrade request will be selected as the sub protocol of the upgraded WebSocket.
     */
    func supportedSubProtocols(): ArrayList<String> {
        ArrayList()
    }

    /**
     * the whitelist of the origin of the user configured agreement handshake.
     * If not configured, all handshakes from the origin will be agreed upon.
     * If configured, only handshakes from the configured origin will be accepted.
     */
    func supportedOrigins(): ArrayList<String> {
        ArrayList()
    }

    /**
     * accumulated the data when receive non end frame, then call onMessage when receive end frame
     */
    func mergeFrames(): Bool {
        true
    }

    /**
     * called after the handshake is successful.
     */
    func onOpen(session: JoyWebSocketSession): Unit

    /**
     * call when receiving a text or binary message.
     */
    func onMessage(session: JoyWebSocketSession, message: JoyWebSocketMessage): Unit

    /**
     * call when receiving a close message.
     */
    func onClose(session: JoyWebSocketSession, closeStatus: UInt16): Unit

    /**
     * call when receiving invalid message or occur exception.
     */
    func onError(session: JoyWebSocketSession, ex: Exception): Unit
}

/**
 * the websocket message.
 */
public class JoyWebSocketMessage {
    private let _msgType: JoyWebSocketMsgType
    private let _isLast: Bool
    private let _data: Array<Byte>

    init(msgType: JoyWebSocketMsgType, isLast: Bool, data: Array<Byte>) {
        _msgType = msgType
        _isLast = isLast
        _data = data
    }

    /*
     * return is it the last message frame
     */
    public prop isLast: Bool {
        get() {
            _isLast
        }
    }

    /*
     * return the message type
     */
    public prop msgType: JoyWebSocketMsgType {
        get() {
            _msgType
        }
    }

    /*
     * convert to text
     */
    public func asText(): String {
        match (_msgType) {
            case WsText => String.fromUtf8(_data)
            case _ => throw IllegalArgumentException("not is text message")
        }
    }

    /*
     * convert to json deseriabled object
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

    /*
     * convert to binary
     */
    public func asBinary(): Array<Byte> {
        match (_msgType) {
            case WsBinary => _data
            case _ => throw IllegalArgumentException("not is binary message")
        }
    }

    func data(): Array<Byte> {
        _data
    }

    /**
     * create text message
     *
     * @param playload: message playload
     */
    public static func createText(playload: String): JoyWebSocketMessage {
        JoyWebSocketMessage(WsText, true, playload.toArray())
    }

    /**
     * create text message
     *
     * @param playload: message playload which can be json seriablizable
     */
    public static func createText<T>(playload: T): JoyWebSocketMessage where T <: JsonSerializable {
        let buffer = ByteBuffer()
        let writer = JsonWriter(buffer)
        writer.writeValue(playload)
        writer.flush()
        JoyWebSocketMessage(WsText, true, buffer.bytes())
    }

    /**
     * create binay message
     *
     * @param playload: message playload
     */
    public static func createBinary(playload: Array<Byte>): JoyWebSocketMessage {
        JoyWebSocketMessage(WsBinary, true, playload)
    }

    /**
     * create ping message
     *
     * @param playload: message playload
     */
    public static func createPing(): JoyWebSocketMessage {
        JoyWebSocketMessage(WsPing, true, Array<UInt8>(5, repeat: 0))
    }
}

/**
 * the websocket session.
 */
public class JoyWebSocketSession {
    private let _ws: WebSocket
    private let _config: JoyConfig
    private let _headers: HttpHeaders
    private let _paramMap: HashMap<String, String>
    private let _ctxParamMap: HashMap<String, Any>
    private let _query: Form

    init(ws: WebSocket, config: JoyConfig, headers: HttpHeaders, query: Form, paramMap: HashMap<String, String>,
        ctxParamMap: HashMap<String, Any>) {
        _ws = ws
        _config = config
        _headers = headers
        _query = query
        _paramMap = paramMap
        _ctxParamMap = ctxParamMap
    }

    /*
     * obtain the sub protocol negotiated with the other party
     */
    public prop subProtocol: String {
        get() {
            _ws.subProtocol
        }
    }

    /*
     * obtain the handleshake header
     */
    public func getHeader(name: String): ?String {
        _headers.getFirst(name)
    }

    /*
     * obtain the handleshake headers
     */
    public func getHeaderList(name: String): Collection<String> {
        _headers.get(name)
    }

    /*
     * obtain the handleshake url path parameter
     */
    public func getParam(name: String): ?String {
        _paramMap.get(name)
    }

    /*
     * obtain the handleshake context param
     */
    public func getCtxParam<T>(key: String): ?T {
        let val = _ctxParamMap.get(key)
        match (val) {
            case Some(v) => v as T
            case _ => None
        }
    }

    /*
     * obtain the handleshake url query parameter
     */
    public func getQuery(name: String): ?String {
        _query.get(name)
    }

    /*
     * obtain the handleshake url query parameters
     */
    public func getQueryList(name: String): ArrayList<String> {
        _query.getAll(name)
    }

    /**
     * send close frame with satus(1000) and close the connnection
     */
    public func close(): Unit {
        _ws.writeCloseFrame(status: JoyWebSocketCloseStatus.NORMAL, reason: "")
        _ws.closeConn()
    }

    /**
     * send close frame with satus and close the connnection
     *
     * @param closeStatus: the close status
     * @param reason: the close reason
     */
    public func close(closeStatus: UInt16, reason: String): Unit {
        _ws.writeCloseFrame(status: closeStatus, reason: reason)
        _ws.closeConn()
    }

    /**
     * send websocket message
     *
     * @param message: the message
     */
    public func send(message: JoyWebSocketMessage): Unit {
        match (message.msgType) {
            case WsText => _ws.write(WebSocketFrameType.TextWebFrame, message.data())
            case WsBinary => _ws.write(WebSocketFrameType.BinaryWebFrame, message.data())
            case WsPing => _ws.writePingFrame(message.data())
        }
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

        @LogDebug("upgrade websocket success from ${ctx.getClientIP()}")

        let ctxHttp = (ctx as JoyHttpContext).getOrThrow()
        let req = ctx.httpContext.request
        let session = JoyWebSocketSession(websocket, ctx.config, req.headers, req.url.queryForm.clone(),
            ctxHttp.copyParams(), ctxHttp.copyCtxParams())

        // release the context and http framework thread
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
                    case ContinuationWebFrame =>
                        if (handler.mergeFrames()) {
                            buffer.write(frame.payload)
                            if (frame.fin) {
                                handler.onMessage(session, JoyWebSocketMessage(msgType, true, buffer.bytes()))
                                buffer.clear()
                            }
                        } else {
                            handler.onMessage(session, JoyWebSocketMessage(msgType, frame.fin, frame.payload))
                        }
                    case TextWebFrame | BinaryWebFrame =>
                        msgType = if (frame.frameType == TextWebFrame) {
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
                    case CloseWebFrame =>
                        match {
                            case frame.payload.size == 0 =>
                                @LogDebug("revceive empty close status")
                                handler.onClose(session, JoyWebSocketCloseStatus.NORMAL)
                            case frame.payload.size <= 125 && frame.payload.size > 1 =>
                                let statusCode = toUInt16(frame.payload[0..2])
                                @LogDebug("revceive close status code, ${statusCode}")
                                handler.onClose(session, statusCode)
                            case _ =>
                                @LogWarn("revceive invalid close status code")
                                handler.onError(session, WebSocketException("invalid close status code"))
                        }
                        isOpen = false
                    case PingWebFrame => websocket.writePongFrame(frame.payload)
                    case _ => ()
                }
            } catch (ex: Exception) {
                @LogWarn("read frame from websocket occurs an error, message=${ex.message}")
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

    private static func toUInt16(bytes: Array<Byte>): UInt16 {
        var val: UInt16 = 0
        for (byte in bytes) {
            val = val << 8
            val = val | UInt16(byte)
        }
        val
    }
}
