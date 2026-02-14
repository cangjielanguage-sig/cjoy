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

import stdx.net.http.{HttpContext, HttpResponseWriter}

/**
 * Builder for server-sent event (SSE)
 */
public class JoyServerEventBuilder {
    private let _sb: StringBuilder = StringBuilder()

    /**
     * Sets the event name
     *
     * @param event The event name
     * @return This JoyServerEventBuilder instance for method chaining
     */
    public func event(event: String): JoyServerEventBuilder {
        _sb.append("event: ")
        _sb.append(event)
        _sb.append("\n")
        this
    }

    /**
     * Sets the event id
     *
     * @param id The event id
     * @return This JoyServerEventBuilder instance for method chaining
     */
    public func id(id: String): JoyServerEventBuilder {
        _sb.append("id: ")
        _sb.append(id)
        _sb.append("\n")
        this
    }

    /**
     * Sets the event data
     *
     * @param data The event data
     * @return This JoyServerEventBuilder instance for method chaining
     */
    public func data(data: String): JoyServerEventBuilder {
        _sb.append("data: ")
        _sb.append(data)
        _sb.append("\n")
        this
    }

    /**
     * Sets the retry time
     *
     * @param retry The retry time in milliseconds
     * @return This JoyServerEventBuilder instance for method chaining
     */
    public func retry(retry: UInt): JoyServerEventBuilder {
        _sb.append("retry: ")
        _sb.append(retry)
        _sb.append("\n")
        this
    }

    /**
     * Adds a comment to the event
     *
     * @param comment The comment string
     * @return This JoyServerEventBuilder instance for method chaining
     */
    public func comment(comment: String): JoyServerEventBuilder {
        _sb.append(": ")
        _sb.append(comment)
        _sb.append("\n")
        this
    }

    /**
     * Builds the server-sent event string
     *
     * @return The SSE formatted string
     */
    public func build(): String {
        if (_sb.size > 0) {
            _sb.append("\n")
        }
        _sb.toString()
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
    public func sendEvent(data: JoyServerEventBuilder): JoySseEmitter {
        checkEnd()
        _httpResponseWriter.write(data.build().toArray())
        this
    }
}
