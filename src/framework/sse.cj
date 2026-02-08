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
