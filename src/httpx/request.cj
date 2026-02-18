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
 * HTTP 请求构建器
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
     * 使用给定路径创建新的 HTTP 请求
     *
     * @param path 请求路径
     * @return 新的 HTTP 请求实例
     */
    public static func of(path: String): JoyHttpRequest {
        JoyHttpRequest(path)
    }

    /**
     * 设置 HTTP 方法
     *
     * @param method HTTP 方法 (GET, POST, PUT, DELETE, PATCH)
     * @return 此请求，用于链式调用
     */
    public func method(method: String): JoyHttpRequest {
        _method = method
        this
    }

    /**
     * 设置 HTTP 方法为 GET
     *
     * @return 此请求，用于链式调用
     */
    public func get(): JoyHttpRequest {
        method(JoyHttpConsts.METHOD_GET)
    }

    /**
     * 设置 HTTP 方法为 POST
     *
     * @return 此请求，用于链式调用
     */
    public func post(): JoyHttpRequest {
        method(JoyHttpConsts.METHOD_POST)
    }

    /**
     * 设置 HTTP 方法为 PUT
     *
     * @return 此请求，用于链式调用
     */
    public func put(): JoyHttpRequest {
        method(JoyHttpConsts.METHOD_PUT)
    }

    /**
     * 设置 HTTP 方法为 DELETE
     *
     * @return 此请求，用于链式调用
     */
    public func delete(): JoyHttpRequest {
        method(JoyHttpConsts.METHOD_DELETE)
    }

    /**
     * 设置 HTTP 方法为 PATCH
     *
     * @return 此请求，用于链式调用
     */
    public func patch(): JoyHttpRequest {
        method(JoyHttpConsts.METHOD_PATCH)
    }

    /**
     * 设置请求超时时间
     *
     * @param timeout 超时持续时间
     * @return 此请求，用于链式调用
     */
    public func timeout(timeout: Duration): JoyHttpRequest {
        _timeout = timeout
        this
    }

    /**
     * 添加查询参数
     *
     * @param name 查询参数名称
     * @param value 查询参数值
     * @return 此请求，用于链式调用
     */
    public func query(name: String, value: String): JoyHttpRequest {
        _queries.add(name, value)
        this
    }

    /**
     * 添加多个查询参数
     *
     * @param queries 查询参数映射
     * @return 此请求，用于链式调用
     */
    public func queries(queries: Map<String, ToString>): JoyHttpRequest {
        _queries.add(all: queries)
        this
    }

    /**
     * 添加多个请求头
     *
     * @param headers 要添加的 HTTP 请求头
     * @return 此请求，用于链式调用
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
     * 添加请求头
     *
     * @param name 请求头名称
     * @param value 请求头值
     * @return 此请求，用于链式调用
     */
    public func header(name: String, value: String): JoyHttpRequest {
        _headers.add(name, value)
        this
    }

    /**
     * 设置请求体
     *
     * @param body 请求体 (String, Array<Byte>, JsonSerializable, InputStream)
     * @return 此请求，用于链式调用
     */
    public func body(body: Any): JoyHttpRequest {
        _body = body
        this
    }

    /**
     * 设置请求体为 JSON
     *
     * @param body 可序列化为 JSON 的请求体
     * @return 此请求，用于链式调用
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
     * 设置请求体为多部分表单数据
     *
     * @param fn 写入多部分数据的函数
     * @return 此请求，用于链式调用
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
     * 添加表单字段
     *
     * @param name 表单字段名称
     * @param value 表单字段值
     * @return 此请求，用于链式调用
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
 * JSON HTTP 请求体
 */
public class JsonRequest {
    public JsonRequest(let body: Any) {
    }

    /**
     * 将此请求写入请求构建器
     *
     * @param builder HTTP 请求构建器
     * @throws IllegalArgumentException 如果请求体不是可序列化为 JSON 的对象
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
