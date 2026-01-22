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

/**
 * the builder for server-sent event
 */
public class JoyServerEventBuilder {
    private let _sb: StringBuilder = StringBuilder()

    /**
     * set the event name
     *
     * @param event: the event name
     * @return the JoyServerEventBuilder
     */
    public func event(event: String): JoyServerEventBuilder {
        _sb.append("event: ")
        _sb.append(event)
        _sb.append("\n")
        this
    }

    /**
     * set the event id
     *
     * @param id: the event id
     * @return the JoyServerEventBuilder
     */
    public func id(id: String): JoyServerEventBuilder {
        _sb.append("id: ")
        _sb.append(id)
        _sb.append("\n")
        this
    }

    /**
     * set the event data
     *
     * @param data: the event data
     * @return the JoyServerEventBuilder
     */
    public func data(data: String): JoyServerEventBuilder {
        _sb.append("data: ")
        _sb.append(data)
        _sb.append("\n")
        this
    }

    /**
     * set the retry time
     *
     * @param retry: the retry time in milliseconds
     * @return the JoyServerEventBuilder
     */
    public func retry(retry: UInt): JoyServerEventBuilder {
        _sb.append("retry: ")
        _sb.append(retry)
        _sb.append("\n")
        this
    }

    /**
     * add a comment to the event
     *
     * @param comment: the comment string
     * @return the JoyServerEventBuilder
     */
    public func comment(comment: String): JoyServerEventBuilder {
        _sb.append(": ")
        _sb.append(comment)
        _sb.append("\n")
        this
    }

    /**
     * build the server-sent event string
     *
     * @return the SSE formatted string
     */
    public func build(): String {
        if (_sb.size > 0) {
            _sb.append("\n")
        }
        _sb.toString()
    }
}

/**
 * the writer for chunked http response
 */
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

    /**
     * add a header to response
     *
     * @param name: the header name
     * @param value: the header value
     */
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

    /**
     * end the chunked response
     */
    public func end(): Unit {
        _end = true
    }
}

/**
 * the writer for chunked http response
 */
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

/**
 * the writer for server-sent events
 */
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
