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

    public static func of(path: String): JoyHttpRequest {
        JoyHttpRequest(path)
    }

    public func method(method: String): JoyHttpRequest {
        _method = method
        this
    }

    public func get(): JoyHttpRequest {
        method(JoyHttpConsts.METHOD_GET)
    }

    public func post(): JoyHttpRequest {
        method(JoyHttpConsts.METHOD_POST)
    }

    public func put(): JoyHttpRequest {
        method(JoyHttpConsts.METHOD_PUT)
    }

    public func delete(): JoyHttpRequest {
        method(JoyHttpConsts.METHOD_DELETE)
    }

    public func patch(): JoyHttpRequest {
        method(JoyHttpConsts.METHOD_PATCH)
    }

    public func timeout(timeout: Duration): JoyHttpRequest {
        _timeout = timeout
        this
    }

    public func query(name: String, value: String): JoyHttpRequest {
        _queries.add(name, value)
        this
    }

    public func queries(queries: Map<String, ToString>): JoyHttpRequest {
        _queries.add(all: queries)
        this
    }

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

    public func header(name: String, value: String): JoyHttpRequest {
        _headers.add(name, value)
        this
    }

    public func body(body: Any): JoyHttpRequest {
        _body = body
        this
    }

    public func json<T>(body: T): JoyHttpRequest where T <: JsonSerializable {
        let buffer = ByteBuffer()
        let writer = JsonWriter(buffer)
        writer.writeValue(body)
        writer.flush()
        _body = buffer
        _headers.set(JoyHttpConsts.HEADER_CONTENT_TYPE, JoyHttpConsts.MIME_APP_JSON_UTF8)
        this
    }

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

/*
 * the http json request
 */
public class JsonRequest {
    public JsonRequest(let body: Any) {
    }

    /**
     * @throws IllegalArgumentException if the request body is not json serializable object
     */
    public func write(buidler: HttpRequestBuilder): Unit {
        match (body) {
            case x: String => buidler
                .header(JoyHttpConsts.HEADER_CONTENT_TYPE, JoyHttpConsts.MIME_APP_JSON_UTF8)
                .body(x)
            case x: JsonSerializable =>
                let buffer = ByteBuffer()
                let writer = JsonWriter(buffer)
                writer.writeValue(x)
                writer.flush()
                buidler.header(JoyHttpConsts.HEADER_CONTENT_TYPE, JoyHttpConsts.MIME_APP_JSON_UTF8).body(buffer)
            case _ => throw IllegalArgumentException("the request body can not serialize to JSON")
        }
    }
}
