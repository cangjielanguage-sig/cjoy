/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.httpx

import std.collection.{Map, HashMap}
import stdx.net.http.{HttpHeaders}
import stdx.encoding.url.Form
import cjoy.context.Context
import cjoy.framework.{JoyHttpConsts}

/**
 * the http client service interface
 */
public interface JoyHttpClient {
    func send(ctx: Context, request: JoyHttpRequest): JoyHttpResponse

    func get(ctx: Context, path: String): JoyHttpResponse {
        send(ctx, JoyHttpRequest.of(path).get())
    }
    func get(ctx: Context, path: String, queries: Map<String, ToString>): JoyHttpResponse {
        send(ctx, JoyHttpRequest.of(path).get().queries(queries))
    }
    func get(ctx: Context, path: String, headers: HttpHeaders): JoyHttpResponse {
        send(ctx, JoyHttpRequest.of(path).get().headers(headers))
    }

    func post(ctx: Context, path: String, body: Any): JoyHttpResponse {
        send(ctx, JoyHttpRequest.of(path).post().body(body))
    }
    func post(ctx: Context, path: String, headers: HttpHeaders, body: Any): JoyHttpResponse {
        send(ctx, JoyHttpRequest.of(path).post().headers(headers).body(body))
    }

    func put(ctx: Context, path: String, body: Any): JoyHttpResponse {
        send(ctx, JoyHttpRequest.of(path).put().body(body))
    }
    func put(ctx: Context, path: String, headers: HttpHeaders, body: Any): JoyHttpResponse {
        send(ctx, JoyHttpRequest.of(path).put().headers(headers).body(body))
    }

    func patch(ctx: Context, path: String, body: Any): JoyHttpResponse {
        send(ctx, JoyHttpRequest.of(path).patch().body(body))
    }
    func patch(ctx: Context, path: String, headers: HttpHeaders, body: Any): JoyHttpResponse {
        send(ctx, JoyHttpRequest.of(path).patch().headers(headers).body(body))
    }

    func delete(ctx: Context, path: String, body: Any): JoyHttpResponse {
        send(ctx, JoyHttpRequest.of(path).delete().body(body))
    }
    func delete(ctx: Context, path: String): JoyHttpResponse {
        send(ctx, JoyHttpRequest.of(path).delete())
    }
    func delete(ctx: Context, path: String, headers: HttpHeaders, body: Any): JoyHttpResponse {
        send(ctx, JoyHttpRequest.of(path).delete().headers(headers).body(body))
    }

    func postform(ctx: Context, path: String, headers: HttpHeaders, form: Form): JoyHttpResponse {
        let body = form.toEncodeString()
        headers.add(JoyHttpConsts.HEADER_CONTENT_TYPE, JoyHttpConsts.MIME_APP_FORM_URL_ENCODED)
        send(ctx, JoyHttpRequest.of(path).post().headers(headers).body(body))
    }
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
