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
import stdx.net.http.{HttpContext, HttpResponseWriter}

/**
 * Builder for server-sent event (SSE)
 */
public class JoySseBuilder {
    private var _name: ?String = None
    private var _id: ?String = None
    private var _data: ?String = None
    private var _retry: ?UInt = None
    private var _comment: ?String = None

    /**
     * Sets the event name
     *
     * @param event The event name
     * @return This JoySseBuilder instance for method chaining
     */
    public func event(event: String): JoySseBuilder {
        _name = event
        this
    }

    /**
     * Sets the event id
     *
     * @param id The event id
     * @return This JoySseBuilder instance for method chaining
     */
    public func id(id: String): JoySseBuilder {
        _id = id
        this
    }

    /**
     * Sets the event data
     *
     * @param data The event data
     * @return This JoySseBuilder instance for method chaining
     */
    public func data(data: String): JoySseBuilder {
        _data = data
        this
    }

    /**
     * Sets the retry time
     *
     * @param retry The retry time in milliseconds
     * @return This JoySseBuilder instance for method chaining
     */
    public func retry(retry: UInt): JoySseBuilder {
        _retry = retry
        this
    }

    /**
     * Adds a comment to the event
     *
     * @param comment The comment string
     * @return This JoySseBuilder instance for method chaining
     */
    public func comment(comment: String): JoySseBuilder {
        _comment = comment
        this
    }

    /**
     * Builds the server-sent event string
     *
     * @return The SSE formatted string
     */
    public func build(): Array<Byte> {
        let buffer: ByteBuffer = ByteBuffer()
        if (let Some(event) <- _name) {
            buffer.write("event: ".toArray())
            buffer.write(event.toArray())
            buffer.writeByte(b'\n')
        }

        if (let Some(id) <- _id) {
            buffer.write("id: ".toArray())
            buffer.write(id.toArray())
            buffer.writeByte(b'\n')
        }

        if (let Some(data) <- _data) {
            buffer.write("data: ".toArray())
            buffer.write(data.toArray())
            buffer.writeByte(b'\n')
        }

        if (let Some(retry) <- _retry) {
            buffer.write("retry: ".toArray())
            buffer.write(retry.toString().toArray())
            buffer.writeByte(b'\n')
        }

        if (let Some(comment) <- _comment) {
            buffer.write(": ".toArray())
            buffer.write(comment.toArray())
            buffer.writeByte(b'\n')
        }

        if (buffer.length > 0) {
            buffer.writeByte(b'\n')
        }
        buffer.bytes()
    }
}

/**
 * Writer for server-sent events (SSE)
 */
public class JoySseEmitter <: ChunkedWriter {
    init(httpContext: HttpContext) {
        super(httpContext)
        let responseBuilder = httpContext.responseBuilder
        responseBuilder.header(JoyHttpConsts.HEADER_CONTENT_TYPE, JoyHttpConsts.MIME_TEXT_EVENT_STREAM)
        responseBuilder.header(JoyHttpConsts.HEADER_CACHE_CONTROL, "no-cache")
    }

    /**
     * Writes data which is encoded to SSE
     *
     * @param data The event
     * @return This JoySseEmitter instance for method chaining
     */
    public func sendEvent(data: JoySseBuilder): JoySseEmitter {
        checkEnd()
        _httpResponseWriter.write(data.build())
        this
    }
}
