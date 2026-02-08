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

