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

import std.io.ByteBuffer
import stdx.net.http.{HttpContext, HttpResponseWriter, HttpStatusCode}
import stdx.encoding.json.stream.{JsonSerializable, JsonWriter}

public class JoyServerEventBuilder {
    private let _sb: StringBuilder = StringBuilder()

    public func event(event: String): JoyServerEventBuilder {
        _sb.append("event: ")
        _sb.append(event)
        _sb.append("\n")
        this
    }

    public func id(id: String): JoyServerEventBuilder {
        _sb.append("id: ")
        _sb.append(id)
        _sb.append("\n")
        this
    }

    public func data(data: String): JoyServerEventBuilder {
        _sb.append("data: ")
        _sb.append(data)
        _sb.append("\n")
        this
    }

    public func retry(retry: UInt): JoyServerEventBuilder {
        _sb.append("retry: ")
        _sb.append(retry)
        _sb.append("\n")
        this
    }

    public func comment(comment: String): JoyServerEventBuilder {
        _sb.append(": ")
        _sb.append(comment)
        _sb.append("\n")
        this
    }

    public func build(): String {
        if (_sb.size > 0) {
            _sb.append("\n")
        }
        _sb.toString()
    }
}

public open class ChunkedWriter {
    protected let _httpContext: HttpContext
    protected let _httpResponseWriter: HttpResponseWriter
    protected var _end: Bool = false

    init(httpContext: HttpContext) {
        _httpContext = httpContext
        let responseBuilder = httpContext.responseBuilder
        responseBuilder.status(HttpStatusCode.STATUS_OK)
        responseBuilder.header(JoyHttpConsts.HEADER_TRANSFER_ENCODING, "chunked")
        responseBuilder.header(JoyHttpConsts.HEADER_CONNECTION, "keep-alive")
        _httpResponseWriter = HttpResponseWriter(httpContext)
    }

    public func header(name: String, value: String): Unit {
        _httpContext.responseBuilder.header(name, value)
    }

    /**
     * @throws IllegalStateException if send data on end state
     */
    protected func checkEnd() {
        if (_end) {
            throw IllegalStateException("already end")
        }
    }

    public func end(): Unit {
        _end = true
    }
}

public class JoyChunkedWriter <: ChunkedWriter {
    init(httpContext: HttpContext) {
        super(httpContext)
    }

    /**
     * write string data then send it
     *
     * @param data: the chunked data
     * @return the JoyChunkedWriter
     */
    public func write(data: String): JoyChunkedWriter {
        checkEnd()
        _httpResponseWriter.write(data.toArray())
        this
    }

    /**
     * write bytes data then send it
     *
     * @param data: the chunked data
     * @return the JoyChunkedWriter
     */
    public func write(data: Array<Byte>): JoyChunkedWriter {
        checkEnd()
        _httpResponseWriter.write(data)
        this
    }

    /**
     * write data which be serializabled to json then send it
     *
     * @param data: the chunked data
     * @return the JoyChunkedWriter
     */
    public func writeJson<T>(data: T): JoyChunkedWriter where T <: JsonSerializable {
        let buffer = ByteBuffer()
        let writer = JsonWriter(buffer)
        writer.writeValue(data)
        writer.flush()
        write(buffer.bytes())
    }
}

public class JoySseEmitter <: ChunkedWriter {
    init(httpContext: HttpContext) {
        super(httpContext)
        let responseBuilder = httpContext.responseBuilder
        responseBuilder.header(JoyHttpConsts.HEADER_CONTENT_TYPE, JoyHttpConsts.MIME_TEXT_EVENT_STREAM)
        responseBuilder.header(JoyHttpConsts.HEADER_CACHE_CONTROL, "no-cache")
    }

    /**
     * write data which be encoded to SSE
     *
     * @param data: the event
     * @return the JoySseEmitter
     */
    public func sendEvent(data: JoyServerEventBuilder): JoySseEmitter {
        checkEnd()
        _httpResponseWriter.write(data.build().toArray())
        this
    }
}
