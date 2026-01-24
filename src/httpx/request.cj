/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.httpx

import std.collection.{Map, HashMap}
import std.io.ByteBuffer
import stdx.encoding.json.stream.{JsonSerializable, JsonWriter}
import stdx.encoding.url.Form
import stdx.net.http.{HttpRequestBuilder, HttpHeaders}
import cjoy.framework.JoyHttpConsts
import cjoy.multipart.JoyMultiPartWriter

/**
 * HTTP request builder
 */
public class JoyHttpRequest {
    let _path: String
    var _method: String = JoyHttpConsts.METHOD_GET
    let _queries: Map<String, ToString> = HashMap()
    let _headers: HttpHeaders = HttpHeaders()
    var _body: Any = Option<Any>.None
    var _timeout: ?Duration = None
    var _form: ?Form = None

    init(path: String) {
        _path = path
    }

    /**
     * Create a new HTTP request with given path
     *
     * @param path request path
     * @return new HTTP request instance
     */
    public static func of(path: String): JoyHttpRequest {
        JoyHttpRequest(path)
    }

    /**
     * Set HTTP method
     *
     * @param method HTTP method (GET, POST, PUT, DELETE, PATCH)
     * @return this request for chaining
     */
    public func method(method: String): JoyHttpRequest {
        _method = method
        this
    }

    /**
     * Set HTTP method to GET
     *
     * @return this request for chaining
     */
    public func get(): JoyHttpRequest {
        method(JoyHttpConsts.METHOD_GET)
    }

    /**
     * Set HTTP method to POST
     *
     * @return this request for chaining
     */
    public func post(): JoyHttpRequest {
        method(JoyHttpConsts.METHOD_POST)
    }

    /**
     * Set HTTP method to PUT
     *
     * @return this request for chaining
     */
    public func put(): JoyHttpRequest {
        method(JoyHttpConsts.METHOD_PUT)
    }

    /**
     * Set HTTP method to DELETE
     *
     * @return this request for chaining
     */
    public func delete(): JoyHttpRequest {
        method(JoyHttpConsts.METHOD_DELETE)
    }

    /**
     * Set HTTP method to PATCH
     *
     * @return this request for chaining
     */
    public func patch(): JoyHttpRequest {
        method(JoyHttpConsts.METHOD_PATCH)
    }

    /**
     * Set request timeout
     *
     * @param timeout timeout duration
     * @return this request for chaining
     */
    public func timeout(timeout: Duration): JoyHttpRequest {
        _timeout = timeout
        this
    }

    /**
     * Add a query parameter
     *
     * @param name query parameter name
     * @param value query parameter value
     * @return this request for chaining
     */
    public func query(name: String, value: String): JoyHttpRequest {
        _queries.add(name, value)
        this
    }

    /**
     * Add multiple query parameters
     *
     * @param queries map of query parameters
     * @return this request for chaining
     */
    public func queries(queries: Map<String, ToString>): JoyHttpRequest {
        _queries.add(all: queries)
        this
    }

    /**
     * Add multiple headers
     *
     * @param headers HTTP headers to add
     * @return this request for chaining
     */
    public func headers(headers: HttpHeaders): JoyHttpRequest {
        for (h in headers) {
            let n = h[0]
            let vs = h[1]
            for (v in vs) {
                _headers.add(n, v)
            }
        }
        this
    }

    /**
     * Add a header
     *
     * @param name header name
     * @param value header value
     * @return this request for chaining
     */
    public func header(name: String, value: String): JoyHttpRequest {
        _headers.add(name, value)
        this
    }

    /**
     * Set request body
     *
     * @param body request body (String, Array<Byte>, JsonSerializable, InputStream)
     * @return this request for chaining
     */
    public func body(body: Any): JoyHttpRequest {
        _body = body
        this
    }

    /**
     * Set request body as JSON
     *
     * @param body JSON-serializable body
     * @return this request for chaining
     */
    public func json<T>(body: T): JoyHttpRequest where T <: JsonSerializable {
        let buffer = ByteBuffer()
        let writer = JsonWriter(buffer)
        writer.writeValue(body)
        writer.flush()
        _body = buffer
        _headers.set(JoyHttpConsts.HEADER_CONTENT_TYPE, JoyHttpConsts.MIME_APP_JSON_UTF8)
        this
    }

    /**
     * Set request body as multipart form data
     *
     * @param fn function to write multipart data
     * @return this request for chaining
     */
    public func multiPart(fn: (writer: JoyMultiPartWriter) -> Unit): JoyHttpRequest {
        post()
        let buffer = ByteBuffer()
        try (writer = JoyMultiPartWriter(buffer)) {
            fn(writer)
            _headers.set(JoyHttpConsts.HEADER_CONTENT_TYPE, writer.formDataContentType)
        }
        _body = buffer
        this
    }

    /**
     * Add a form field
     *
     * @param name form field name
     * @param value form field value
     * @return this request for chaining
     */
    public func postform(name: String, value: String): JoyHttpRequest {
        if (let Some(f) <- _form) {
            f.add(name, value)
        } else {
            let f = Form()
            f.add(name, value)
            _form = f
        }
        this
    }
}

/**
 * JSON HTTP request body
 */
public class JsonRequest {
    public JsonRequest(let body: Any) {
    }

    /**
     * Write this request to request builder
     *
     * @param builder HTTP request builder
     * @throws IllegalArgumentException if request body is not json serializable object
     */
    public func write(builder: HttpRequestBuilder): Unit {
        match (body) {
            case x: String => builder
                .header(JoyHttpConsts.HEADER_CONTENT_TYPE, JoyHttpConsts.MIME_APP_JSON_UTF8)
                .body(x)
            case x: JsonSerializable =>
                let buffer = ByteBuffer()
                let writer = JsonWriter(buffer)
                writer.writeValue(x)
                writer.flush()
                builder.header(JoyHttpConsts.HEADER_CONTENT_TYPE, JoyHttpConsts.MIME_APP_JSON_UTF8).body(buffer)
            case _ => throw IllegalArgumentException("the request body can not serialize to JSON")
        }
    }
}
