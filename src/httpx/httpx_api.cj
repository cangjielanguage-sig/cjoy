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

import std.collection.{Map}
import stdx.net.http.{HttpHeaders}
import stdx.encoding.url.Form
import cjoy.context.Context
import cjoy.framework.{JoyHttpConsts}

/**
 * HTTP 客户端服务接口
 */
public interface JoyHttpClient {
    /**
     * 发送 HTTP 请求并返回响应
     *
     * @param ctx: 上下文
     * @param request: HTTP 请求
     * @return HTTP 响应
     */
    func send(ctx: Context, request: JoyHttpRequest): JoyHttpResponse

    /**
     * 发送 HTTP GET 请求
     *
     * @param ctx: 上下文
     * @param path: 请求路径
     * @return HTTP 响应
     */
    func get(ctx: Context, path: String): JoyHttpResponse {
        send(ctx, JoyHttpRequest.of(path).get())
    }
    /**
     * 发送带查询参数的 HTTP GET 请求
     *
     * @param ctx: 上下文
     * @param path: 请求路径
     * @param queries: 查询参数
     * @return HTTP 响应
     */
    func get(ctx: Context, path: String, queries: Map<String, ToString>): JoyHttpResponse {
        send(ctx, JoyHttpRequest.of(path).get().queries(queries))
    }
    /**
     * 发送带头信息的 HTTP GET 请求
     *
     * @param ctx: 上下文
     * @param path: 请求路径
     * @param headers: 请求头
     * @return HTTP 响应
     */
    func get(ctx: Context, path: String, headers: HttpHeaders): JoyHttpResponse {
        send(ctx, JoyHttpRequest.of(path).get().headers(headers))
    }

    /**
     * 发送 HTTP POST 请求
     *
     * @param ctx: 上下文
     * @param path: 请求路径
     * @param body: 请求体
     * @return HTTP 响应
     */
    func post(ctx: Context, path: String, body: Any): JoyHttpResponse {
        send(ctx, JoyHttpRequest.of(path).post().body(body))
    }
    /**
     * 发送带头信息的 HTTP POST 请求
     *
     * @param ctx: 上下文
     * @param path: 请求路径
     * @param headers: 请求头
     * @param body: 请求体
     * @return HTTP 响应
     */
    func post(ctx: Context, path: String, headers: HttpHeaders, body: Any): JoyHttpResponse {
        send(ctx, JoyHttpRequest.of(path).post().headers(headers).body(body))
    }

    /**
     * 发送 HTTP PUT 请求
     *
     * @param ctx: 上下文
     * @param path: 请求路径
     * @param body: 请求体
     * @return HTTP 响应
     */
    func put(ctx: Context, path: String, body: Any): JoyHttpResponse {
        send(ctx, JoyHttpRequest.of(path).put().body(body))
    }
    /**
     * 发送 HTTP PUT 请求（带请求头）
     *
     * @param ctx: 上下文
     * @param path: 请求路径
     * @param headers: 请求头
     * @param body: 请求体
     * @return HTTP 响应
     */
    func put(ctx: Context, path: String, headers: HttpHeaders, body: Any): JoyHttpResponse {
        send(ctx, JoyHttpRequest.of(path).put().headers(headers).body(body))
    }

    /**
     * 发送 HTTP PATCH 请求
     *
     * @param ctx: 上下文
     * @param path: 请求路径
     * @param body: 请求体
     * @return HTTP 响应
     */
    func patch(ctx: Context, path: String, body: Any): JoyHttpResponse {
        send(ctx, JoyHttpRequest.of(path).patch().body(body))
    }
    /**
     * 发送 HTTP PATCH 请求（带请求头）
     *
     * @param ctx: 上下文
     * @param path: 请求路径
     * @param headers: 请求头
     * @param body: 请求体
     * @return HTTP 响应
     */
    func patch(ctx: Context, path: String, headers: HttpHeaders, body: Any): JoyHttpResponse {
        send(ctx, JoyHttpRequest.of(path).patch().headers(headers).body(body))
    }

    /**
     * 发送 HTTP DELETE 请求
     *
     * @param ctx: 上下文
     * @param path: 请求路径
     * @param body: 请求体
     * @return HTTP 响应
     */
    func delete(ctx: Context, path: String, body: Any): JoyHttpResponse {
        send(ctx, JoyHttpRequest.of(path).delete().body(body))
    }
    /**
     * 发送无请求体的 HTTP DELETE 请求
     *
     * @param ctx: 上下文
     * @param path: 请求路径
     * @return HTTP 响应
     */
    func delete(ctx: Context, path: String): JoyHttpResponse {
        send(ctx, JoyHttpRequest.of(path).delete())
    }
    /**
     * 发送 HTTP DELETE 请求（带请求头）
     *
     * @param ctx: 上下文
     * @param path: 请求路径
     * @param headers: 请求头
     * @param body: 请求体
     * @return HTTP 响应
     */
    func delete(ctx: Context, path: String, headers: HttpHeaders, body: Any): JoyHttpResponse {
        send(ctx, JoyHttpRequest.of(path).delete().headers(headers).body(body))
    }

    /**
     * 发送带表单数据的 HTTP POST 请求
     *
     * @param ctx: 上下文
     * @param path: 请求路径
     * @param headers: 请求头
     * @param form: 表单数据
     * @return HTTP 响应
     */
    func postform(ctx: Context, path: String, headers: HttpHeaders, form: Form): JoyHttpResponse {
        let body = form.toEncodeString()
        headers.add(JoyHttpConsts.HEADER_CONTENT_TYPE, JoyHttpConsts.MIME_APP_FORM_URL_ENCODED)
        send(ctx, JoyHttpRequest.of(path).post().headers(headers).body(body))
    }
    /**
     * 发送带表单数据的 HTTP POST 请求
     *
     * @param ctx: 上下文
     * @param path: 请求路径
     * @param form: 表单数据
     * @return HTTP 响应
     */
    func postform(ctx: Context, path: String, form: Form): JoyHttpResponse {
        let body = form.toEncodeString()
        send(ctx,
            JoyHttpRequest
                .of(path)
                .post()
                .header(JoyHttpConsts.HEADER_CONTENT_TYPE, JoyHttpConsts.MIME_APP_FORM_URL_ENCODED)
                .body(body))
    }
}
