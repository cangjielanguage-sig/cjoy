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

import std.collection.HashMap
import stdx.net.http.*
import cjoy.framework.JoyHttpConsts
import cjoy.log.macros.*

@JoyCreateLogger("cjoy.httpx")

/**
 * This is a simple HTTP client that closes connection directly after each request response,
 * which is not suitable for high-performance connection reuse scenarios.
 */
public struct JoySimpleHttpClient {
    /**
     * Connect to server-sent events endpoint
     *
     * @param url SSE endpoint URL
     * @param verify whether to verify SSL certificate
     * @return SSE event stream
     */
    public static func sseConnect(url: String, verify!: Bool = false): JoySSEventStream {
        let header = HashMap<String, String>()
        header.add(JoyHttpConsts.HEADER_ACCEPT, JoyHttpConsts.MIME_TEXT_EVENT_STREAM)
        let httpStream = asyncGet(url, header: header, body: None, verify: verify)
        return JoySSEventStream(httpStream)
    }

    /**
     * Send HTTP GET request
     *
     * @param url request URL
     * @param body optional request body
     * @param header optional request headers
     * @param verify whether to verify SSL certificate
     * @return response body as string, or None if failed
     */
    public static func get(
        url: String,
        body!: Option<Array<Byte>> = None,
        header!: HashMap<String, String> = HashMap(),
        verify!: Bool = false
    ): Option<String> {
        return send("GET", url, header, body, verify: verify)
    }

    /**
     * Send HTTP POST request
     *
     * @param url request URL
     * @param body request body
     * @param header optional request headers
     * @param verify whether to verify SSL certificate
     * @return response body as string, or None if failed
     */
    public static func post(
        url: String,
        body: Array<Byte>,
        header!: HashMap<String, String> = HashMap(),
        verify!: Bool = false
    ): Option<String> {
        return send("POST", url, header, body, verify: verify)
    }

    /**
     * Send HTTP request synchronously
     *
     * @param method HTTP method
     * @param url request URL
     * @param header request headers
     * @param body optional request body
     * @param verify whether to verify SSL certificate
     * @return response body as string, or None if failed
     */
    public static func send(
        method: String,
        url: String,
        header: HashMap<String, String>,
        body: Option<Array<Byte>>,
        verify!: Bool = false
    ): Option<String> {
        logHttpInfo(method, url, header, body)
        let (client, resp) = sendHttp(method, url, header, body, verify)
        if (resp.status != HttpStatusCode.STATUS_OK) {
            let err = resp.text
            @JoyLogError("http request failed, ${method} ${url}, error:${err}")
            client.close()
            return None
        }
        let respBody = resp.text
        client.close()
        return respBody
    }

    /**
     * Send HTTP GET request asynchronously
     *
     * @param url request URL
     * @param body optional request body
     * @param header optional request headers
     * @param verify whether to verify SSL certificate
     * @return HTTP byte stream
     */
    public static func asyncGet(
        url: String,
        body!: Option<Array<Byte>> = None,
        header!: HashMap<String, String> = HashMap(),
        verify!: Bool = false
    ): JoyHttpStream {
        return asyncSend("GET", url, header, body, verify: verify)
    }

    /**
     * Send HTTP POST request asynchronously
     *
     * @param url request URL
     * @param body request body
     * @param header optional request headers
     * @param verify whether to verify SSL certificate
     * @return HTTP byte stream
     */
    public static func asyncPost(
        url: String,
        body: Array<Byte>,
        header!: HashMap<String, String> = HashMap(),
        verify!: Bool = false
    ): JoyHttpStream {
        return asyncSend("POST", url, header, body, verify: verify)
    }

    /**
     * Send HTTP request asynchronously
     *
     * @param method HTTP method
     * @param url request URL
     * @param header request headers
     * @param body optional request body
     * @param verify whether to verify SSL certificate
     * @return HTTP byte stream
     */
    public static func asyncSend(
        method: String,
        url: String,
        header: HashMap<String, String>,
        body: Option<Array<Byte>>,
        verify!: Bool
    ): JoyHttpStream {
        logHttpInfo(method, url, header, body)
        let (client, resp) = sendHttp(method, url, header, body, verify)
        let httpStream = JoyHttpStream()
        if (resp.status >= 300) {
            let err = resp.text
            @JoyLogError("http request failed, ${method} ${url}, error:${err}")
            client.close()
            httpStream.markError(err)
        } else {
            spawn {
                let buffer = Array<Byte>(1024 * 10, {_ => 0})
                while (true) {
                    let length = resp.body.read(buffer)
                    if (length == 0) {
                        httpStream.markEOF()
                        break
                    } else {
                        httpStream.put(buffer[..length])
                    }
                }
                client.close()
            }
        }
        return httpStream
    }

    /**
     * Prepare HTTP request builder
     *
     * @param method HTTP method
     * @param url request URL
     * @param header request headers
     * @param body optional request body
     * @return HTTP request
     */
    private static func prepareHttpRequest(
        method: String,
        url: String,
        header: HashMap<String, String>,
        body: Option<Array<Byte>>
    ): HttpRequest {
        let rb = HttpRequestBuilder().url(url)
        if (let Some(b) <- body) {
            rb.body(b)
        }
        if (method == "POST") {
            rb.post()
        } else if (method == "GET") {
            rb.get()
        }
        for ((k, v) in header) {
            rb.header(k, v)
        }
        return rb.build()
    }

    /**
     * Send HTTP request and get response
     *
     * @param method HTTP method
     * @param url request URL
     * @param header request headers
     * @param body optional request body
     * @param verify whether to verify SSL certificate
     * @return HTTP client and response
     */
    private static func sendHttp(
        method: String,
        url: String,
        header: HashMap<String, String>,
        body: Option<Array<Byte>>,
        verify: Bool
    ): (Client, HttpResponse) {
        let client = defaultNoVerifyHttpCert(url, verify).build()
        let req = prepareHttpRequest(method, url, header, body)
        return (client, client.send(req))
    }

    /**
     * Log HTTP request information
     *
     * @param method HTTP method
     * @param url request URL
     * @param header request headers
     * @param body optional request body
     */
    private static func logHttpInfo(method: String, url: String, header: HashMap<String, String>,
        body: Option<Array<Byte>>) {
        let sb = StringBuilder()
        sb.append("${method}: ${url}\n")
        for ((k, v) in header) {
            sb.append("${k}:${v}\n")
        }
        if (let Some(b) <- body) {
            sb.append("${String.fromUtf8(b)}\n")
        }
        @JoyLogDebug("${sb.toString()}")
    }
}
