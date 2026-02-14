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
 * Base class for chunked HTTP response writers
 *
 * Provides functionality for writing chunked responses with proper HTTP headers
 * and end state management.
 */
public open class ChunkedWriter {
    protected let _httpContext: HttpContext
    protected let _httpResponseWriter: HttpResponseWriter
    protected var _end: Bool = false

    /**
     * Creates a new ChunkedWriter instance
     *
     * @param httpContext The HTTP context for the response
     */
    init(httpContext: HttpContext) {
        _httpContext = httpContext
        let responseBuilder = httpContext.responseBuilder
        responseBuilder.status(HttpStatusCode.STATUS_OK)
        responseBuilder.header(JoyHttpConsts.HEADER_TRANSFER_ENCODING, "chunked")
        responseBuilder.header(JoyHttpConsts.HEADER_CONNECTION, "keep-alive")
        _httpResponseWriter = HttpResponseWriter(httpContext)
    }

    /**
     * Adds a header to the response
     *
     * @param name The header name
     * @param value The header value
     */
    public func header(name: String, value: String): Unit {
        _httpContext.responseBuilder.header(name, value)
    }

    /**
     * Checks if the response has already ended
     *
     * @throws IllegalStateException if trying to send data after ending the response
     */
    protected func checkEnd() {
        if (_end) {
            throw IllegalStateException("already end")
        }
    }

    /**
     * Ends the chunked response
     */
    public func end(): Unit {
        _end = true
    }
}

/**
 * Concrete implementation of ChunkedWriter for writing chunked HTTP responses
 */
public class JoyChunkedWriter <: ChunkedWriter {
    /**
     * Creates a new JoyChunkedWriter instance
     *
     * @param httpContext The HTTP context for the response
     */
    init(httpContext: HttpContext) {
        super(httpContext)
    }

    /**
     * Writes string data to the chunked response and sends it immediately
     *
     * @param data The string data to write
     * @return This JoyChunkedWriter instance for method chaining
     */
    public func write(data: String): JoyChunkedWriter {
        checkEnd()
        _httpResponseWriter.write(data.toArray())
        this
    }

    /**
     * Writes binary data to the chunked response and sends it immediately
     *
     * @param data The binary data to write
     * @return This JoyChunkedWriter instance for method chaining
     */
    public func write(data: Array<Byte>): JoyChunkedWriter {
        checkEnd()
        _httpResponseWriter.write(data)
        this
    }

    /**
     * Writes JSON-serializable data to the chunked response and sends it immediately
     *
     * @param data The JSON-serializable data to write
     * @return This JoyChunkedWriter instance for method chaining
     */
    public func writeJson<T>(data: T): JoyChunkedWriter where T <: JsonSerializable {
        let buffer = ByteBuffer()
        let writer = JsonWriter(buffer)
        writer.writeValue(data)
        writer.flush()
        write(buffer.bytes())
    }
}

