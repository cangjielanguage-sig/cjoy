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

let EMPTY_QUERIES = HashMap<String, ToString>()

/**
 * the http client service interface
 */
public interface JoyHttpClient {
    func get(ctx: Context, path: String, queries: Map<String, ToString>, headers: HttpHeaders): JoyHttpResponse {
        exchange(ctx, JoyHttpConsts.METHOD_GET, path, queries, headers, Option<Any>.None)
    }
    func get(ctx: Context, path: String): JoyHttpResponse {
        get(ctx, path, EMPTY_QUERIES, HttpHeaders())
    }
    func get(ctx: Context, path: String, queries: Map<String, ToString>): JoyHttpResponse {
        get(ctx, path, queries, HttpHeaders())
    }
    func get(ctx: Context, path: String, headers: HttpHeaders): JoyHttpResponse {
        get(ctx, path, EMPTY_QUERIES, headers)
    }

    func post(ctx: Context, path: String, queries: Map<String, ToString>, headers: HttpHeaders, body: Any): JoyHttpResponse {
        exchange(ctx, JoyHttpConsts.METHOD_POST, path, queries, headers, body)
    }
    func post(ctx: Context, path: String, body: Any): JoyHttpResponse {
        post(ctx, path, EMPTY_QUERIES, HttpHeaders(), body)
    }
    func post(ctx: Context, path: String, queries: Map<String, ToString>, body: Any): JoyHttpResponse {
        post(ctx, path, queries, HttpHeaders(), body)
    }
    func post(ctx: Context, path: String, headers: HttpHeaders, body: Any): JoyHttpResponse {
        post(ctx, path, EMPTY_QUERIES, headers, body)
    }

    func put(ctx: Context, path: String, queries: Map<String, ToString>, headers: HttpHeaders, body: Any): JoyHttpResponse {
        exchange(ctx, JoyHttpConsts.METHOD_PUT, path, queries, headers, body)
    }
    func put(ctx: Context, path: String, body: Any): JoyHttpResponse {
        put(ctx, path, EMPTY_QUERIES, HttpHeaders(), body)
    }
    func put(ctx: Context, path: String, queries: Map<String, ToString>, body: Any): JoyHttpResponse {
        put(ctx, path, queries, HttpHeaders(), body)
    }
    func put(ctx: Context, path: String, headers: HttpHeaders, body: Any): JoyHttpResponse {
        put(ctx, path, EMPTY_QUERIES, headers, body)
    }

    func patch(ctx: Context, path: String, queries: Map<String, ToString>, headers: HttpHeaders, body: Any): JoyHttpResponse {
        exchange(ctx, JoyHttpConsts.METHOD_PATCH, path, queries, headers, body)
    }
    func patch(ctx: Context, path: String, body: Any): JoyHttpResponse {
        patch(ctx, path, EMPTY_QUERIES, HttpHeaders(), body)
    }
    func patch(ctx: Context, path: String, queries: Map<String, ToString>, body: Any): JoyHttpResponse {
        patch(ctx, path, queries, HttpHeaders(), body)
    }
    func patch(ctx: Context, path: String, headers: HttpHeaders, body: Any): JoyHttpResponse {
        patch(ctx, path, EMPTY_QUERIES, headers, body)
    }

    func delete(ctx: Context, path: String, queries: Map<String, ToString>, headers: HttpHeaders, body: Any): JoyHttpResponse {
        exchange(ctx, JoyHttpConsts.METHOD_PUT, path, queries, headers, body)
    }
    func delete(ctx: Context, path: String, body: Any): JoyHttpResponse {
        delete(ctx, path, EMPTY_QUERIES, HttpHeaders(), body)
    }
    func delete(ctx: Context, path: String): JoyHttpResponse {
        delete(ctx, path, EMPTY_QUERIES, HttpHeaders(), Option<Any>.None)
    }
    func delete(ctx: Context, path: String, queries: Map<String, ToString>, body: Any): JoyHttpResponse {
        delete(ctx, path, queries, HttpHeaders(), body)
    }
    func delete(ctx: Context, path: String, headers: HttpHeaders, body: Any): JoyHttpResponse {
        delete(ctx, path, EMPTY_QUERIES, headers, body)
    }

    func postform(ctx: Context, path: String, queries: Map<String, ToString>, headers: HttpHeaders, form: Form): JoyHttpResponse {
        let body = form.toEncodeString()
        headers.add(JoyHttpConsts.HEADER_CONTENT_TYPE, JoyHttpConsts.MIME_APP_FORM_URL_ENCODED)
        post(ctx, path, EMPTY_QUERIES, headers, body)
    }
    func postform(ctx: Context, path: String, headers: HttpHeaders, form: Form): JoyHttpResponse {
        postform(ctx, path, EMPTY_QUERIES, headers, form)
    }
    func postform(ctx: Context, path: String, queries: Map<String, ToString>, form: Form): JoyHttpResponse {
        postform(ctx, path, queries, HttpHeaders(), form)
    }
    func postform(ctx: Context, path: String, form: Form): JoyHttpResponse {
        postform(ctx, path, EMPTY_QUERIES, HttpHeaders(), form)
    }

    func exchange(ctx: Context, method: String, path: String, queries: Map<String, ToString>, headers: HttpHeaders,
        body: Any): JoyHttpResponse
}
