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
import std.io.{InputStream, StringReader, ByteBuffer}
import stdx.encoding.json.stream.{JsonDeserializable, JsonSerializable, JsonReader, JsonWriter}
import stdx.net.http.{HttpHeaders, HttpResponse, HttpRequestBuilder}
import cjoy.context.Context
import cjoy.framework.{JoyHttpConsts}

/*
 * the http reponse wrapper
 */
public class JoyHttpResponse {
    private let _response: HttpResponse

    public JoyHttpResponse(response: HttpResponse) {
        _response = response
    }

    public prop status: UInt16 {
        get() {
            _response.status
        }
    }

    public prop text: String {
        get() {
            let reader = StringReader(_response.body)
            reader.readToEnd()
        }
    }

    public func json<T>(): ?T where T <: JsonDeserializable<T> {
        if (_response.bodySize.isSome() && _response.bodySize.getOrThrow() == 0) {
            return None
        }
        if (!contentType.startsWith(JoyHttpConsts.MIME_APP_JSON)) {
            return None
        }
        let reader = JsonReader(_response.body)
        T.fromJson(reader)
    }

    public prop data: InputStream {
        get() {
            _response.body
        }
    }

    public prop isJson: Bool {
        get() {
            contentType.startsWith(JoyHttpConsts.MIME_APP_JSON)
        }
    }

    public prop header: HttpHeaders {
        get() {
            _response.headers
        }
    }

    public prop contentType: String {
        get() {
            _response.headers.getFirst(JoyHttpConsts.HEADER_CONTENT_TYPE) ?? ""
        }
    }
}

/*
 * the http json request
 */
public class JsonRequest<T> where T <: JsonSerializable {
    public JsonRequest(let reqBody: T) {
    }

    public func write(buidler: HttpRequestBuilder): Unit {
        match (reqBody) {
            case x: String => buidler
                .header(JoyHttpConsts.HEADER_CONTENT_TYPE, JoyHttpConsts.MIME_APP_JSON_UTF8)
                .body(x)
            case _ =>
                let buffer = ByteBuffer()
                let writer = JsonWriter(buffer)
                writer.writeValue(reqBody)
                writer.flush()
                buidler.header(JoyHttpConsts.HEADER_CONTENT_TYPE, JoyHttpConsts.MIME_APP_JSON_UTF8).body(buffer)
        }
    }
}

let emptyParams = HashMap<String, ToString>()

/**
 * the http client service interface
 */
public interface JoyHttpClient {
    func get(ctx: Context, path: String, params: Map<String, ToString>, headers: HttpHeaders): JoyHttpResponse {
        exechange(ctx, JoyHttpConsts.METHOD_GET, path, params, headers, Option<Any>.None)
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
        exechange(ctx, JoyHttpConsts.METHOD_POST, path, params, headers, body)
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
        exechange(ctx, JoyHttpConsts.METHOD_PUT, path, params, headers, body)
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
        exechange(ctx, JoyHttpConsts.METHOD_PUT, path, params, headers, body)
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

    func exechange(ctx: Context, method: String, path: String, params: Map<String, ToString>, headers: HttpHeaders,
        body: Any): JoyHttpResponse
}
