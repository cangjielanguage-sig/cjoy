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
import cjoy.context.Context
import cjoy.framework.{JoyHttpConsts}


let emptyParams = HashMap<String, ToString>()

/**
 * the http client service interface
 */
public interface JoyHttpClient {
    func get(ctx: Context, path: String, params: Map<String, ToString>, headers: HttpHeaders): JoyHttpResponse {
        exchange(ctx, JoyHttpConsts.METHOD_GET, path, params, headers, Option<Any>.None)
    }
    func get(ctx: Context, path: String): JoyHttpResponse {
        get(ctx, path, emptyParams, HttpHeaders())
    }
    func get(ctx: Context, path: String, params: Map<String, ToString>): JoyHttpResponse {
        get(ctx, path, params, HttpHeaders())
    }
    func get(ctx: Context, path: String, headers: HttpHeaders): JoyHttpResponse {
        get(ctx, path, emptyParams, headers)
    }

    func post(ctx: Context, path: String, params: Map<String, ToString>, headers: HttpHeaders, body: Any): JoyHttpResponse {
        exchange(ctx, JoyHttpConsts.METHOD_POST, path, params, headers, body)
    }
    func post(ctx: Context, path: String, body: Any): JoyHttpResponse {
        post(ctx, path, emptyParams, HttpHeaders(), body)
    }
    func post(ctx: Context, path: String, params: Map<String, ToString>, body: Any): JoyHttpResponse {
        post(ctx, path, params, HttpHeaders(), body)
    }
    func post(ctx: Context, path: String, headers: HttpHeaders, body: Any): JoyHttpResponse {
        post(ctx, path, emptyParams, headers, body)
    }

    func put(ctx: Context, path: String, params: Map<String, ToString>, headers: HttpHeaders, body: Any): JoyHttpResponse {
        exchange(ctx, JoyHttpConsts.METHOD_PUT, path, params, headers, body)
    }
    func put(ctx: Context, path: String, body: Any): JoyHttpResponse {
        put(ctx, path, emptyParams, HttpHeaders(), body)
    }
    func put(ctx: Context, path: String, params: Map<String, ToString>, body: Any): JoyHttpResponse {
        put(ctx, path, params, HttpHeaders(), body)
    }
    func put(ctx: Context, path: String, headers: HttpHeaders, body: Any): JoyHttpResponse {
        put(ctx, path, emptyParams, headers, body)
    }

    func delete(ctx: Context, path: String, params: Map<String, ToString>, headers: HttpHeaders, body: Any): JoyHttpResponse {
        exchange(ctx, JoyHttpConsts.METHOD_PUT, path, params, headers, body)
    }
    func delete(ctx: Context, path: String, body: Any): JoyHttpResponse {
        delete(ctx, path, emptyParams, HttpHeaders(), body)
    }
    func delete(ctx: Context, path: String, params: Map<String, ToString>, body: Any): JoyHttpResponse {
        delete(ctx, path, params, HttpHeaders(), body)
    }
    func delete(ctx: Context, path: String, headers: HttpHeaders, body: Any): JoyHttpResponse {
        delete(ctx, path, emptyParams, headers, body)
    }

    func exchange(ctx: Context, method: String, path: String, params: Map<String, ToString>, headers: HttpHeaders,
        body: Any): JoyHttpResponse
}
