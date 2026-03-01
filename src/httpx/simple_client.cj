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
 * 这是一个简单的 HTTP 客户端，每个请求响应后直接关闭连接，
 * 不适合高性能连接复用场景。
 */
public struct JoySimpleHttpClient {
    /**
     * 连接到服务器发送事件 (SSE) 端点
     *
     * @param url SSE 端点 URL
     * @param verify 是否验证 SSL 证书
     * @return SSE 事件流
     */
    public static func sseConnect(url: String, verify!: Bool = false): JoySSEventStream {
        let header = HashMap<String, String>()
        header.add(JoyHttpConsts.HEADER_ACCEPT, JoyHttpConsts.MIME_TEXT_EVENT_STREAM)
        let httpStream = asyncGet(url, header: header, body: None, verify: verify)
        return JoySSEventStream(httpStream)
    }

    /**
     * 发送 HTTP GET 请求
     *
     * @param url 请求 URL
     * @param body 可选请求体
     * @param header 可选请求头
     * @param verify 是否验证 SSL 证书
     * @return 响应体字符串，失败返回 None
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
     * 发送 HTTP POST 请求
     *
     * @param url 请求 URL
     * @param body 请求体
     * @param header 可选请求头
     * @param verify 是否验证 SSL 证书
     * @return 响应体字符串，失败返回 None
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
     * 同步发送 HTTP 请求
     *
     * @param method HTTP 方法
     * @param url 请求 URL
     * @param header 请求头
     * @param body 可选请求体
     * @param verify 是否验证 SSL 证书
     * @return 响应体字符串，失败返回 None
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
        resp.close()
        client.close()
        return respBody
    }

    /**
     * 异步发送 HTTP GET 请求
     *
     * @param url 请求 URL
     * @param body 可选请求体
     * @param header 可选请求头
     * @param verify 是否验证 SSL 证书
     * @return HTTP 字节流
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
     * 异步发送 HTTP POST 请求
     *
     * @param url 请求 URL
     * @param body 请求体
     * @param header 可选请求头
     * @param verify 是否验证 SSL 证书
     * @return HTTP 字节流
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
     * 异步发送 HTTP 请求
     *
     * @param method HTTP 方法
     * @param url 请求 URL
     * @param header 请求头
     * @param body 可选请求体
     * @param verify 是否验证 SSL 证书
     * @return HTTP 字节流
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
            resp.close()
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
                resp.close()
                client.close()
            }
        }
        return httpStream
    }

    /**
     * 准备 HTTP 请求构建器
     *
     * @param method HTTP 方法
     * @param url 请求 URL
     * @param header 请求头
     * @param body 可选请求体
     * @return HTTP 请求
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
     * 发送 HTTP 请求并获取响应
     *
     * @param method HTTP 方法
     * @param url 请求 URL
     * @param header 请求头
     * @param body 可选请求体
     * @param verify 是否验证 SSL 证书
     * @return HTTP 客户端和响应
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
     * 记录 HTTP 请求信息
     *
     * @param method HTTP 方法
     * @param url 请求 URL
     * @param header 请求头
     * @param body 可选请求体
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
