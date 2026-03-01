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

import std.io.{InputStream, ByteBuffer}
import std.net.{SocketAddress, TcpSocket}
import stdx.net.http.{ClientBuilder, Client, HttpRequestBuilder, HttpHeaders}
import stdx.net.tls.{TlsClientConfig, CertificateVerifyMode}
import stdx.encoding.json.stream.{JsonSerializable, JsonWriter}
import stdx.encoding.url.{URL, Form}
import cjoy.context.Context
import cjoy.framework.{JoyHttpConsts}

func defaultNoVerifyHttpCert(url: String, verify: Bool): ClientBuilder {
    let cb = ClientBuilder()
    if (url.startsWith("https")) {
        var config = TlsClientConfig()
        if (!verify) {
            config.verifyMode = TrustAll
        }
        config.domain = URL.parse(url).hostName
        cb.tlsConfig(config)
    }
    let socketConnector = {
        sa: SocketAddress =>
            let socket = TcpSocket(sa)
            socket.readTimeout = Duration.minute
            socket.writeTimeout = Duration.minute
            socket.connect(timeout: Duration.minute)
            return socket
    }
    cb.readTimeout(Duration.minute)
    cb.connector(socketConnector)
    cb.poolSize(100)
}

/**
 * 支持连接池的 HTTP 客户端服务
 */
public class JoyHttpClientService <: JoyHttpClient & Resource {
    private let _client: Client
    private let _url: String
    private var _isClosed = false

    /**
     * 使用给定基础 URL 创建 HTTP 客户端服务
     *
     * @param url 基础 URL
     * @param verify 是否验证 SSL 证书
     * @param budilerFn 可选的客户端构建器函数
     */
    public init(url: String, verify!: Bool = false,
        budilerFn!: (url: String, verify: Bool) -> ClientBuilder = defaultNoVerifyHttpCert) {
        _url = url.trimEnd("/")
        _client = budilerFn(url, verify).build()
    }

    ~init() {
        _client.close()
    }

    /**
     * 销毁客户端服务
     */
    public func destroy(): Unit {
        close()
    }

    /**
     * 关闭客户端连接
     */
    public func close(): Unit {
        if (_isClosed) {
            return
        }
        _client.close()
        _isClosed = true
    }

    /**
     * 检查客户端是否已关闭
     *
     * @return 如果已关闭返回 true
     */
    public func isClosed(): Bool {
        _isClosed
    }

    /**
     * 发送 HTTP 请求
     *
     * @param ctx 请求上下文
     * @param request HTTP 请求
     * @return HTTP 响应
     */
    public func send(ctx: Context, request: JoyHttpRequest): JoyHttpResponse {
        let url = mergeUrl(request)
        let rb = HttpRequestBuilder().url(url)
        rb.setHeaders(request._headers)
        rb.method(request._method)
        if (let Some(t) <- request._timeout) {
            rb.readTimeout(t)
        }

        writeBody(request, rb)
        let rsp = _client.send(rb.build())
        JoyHttpResponse(rsp)
    }

    /**
     * 将基础 URL 与请求路径和查询参数合并
     *
     * @param request HTTP 请求
     * @return 完整 URL
     */
    private func mergeUrl(request: JoyHttpRequest): String {
        var url = if (request._path.startsWith("/")) {
            _url + request._path
        } else {
            _url + "/" + request._path
        }

        if (!request._queries.isEmpty()) {
            let queryForm = Form()
            for ((k, v) in request._queries) {
                queryForm.add(k, v.toString())
            }
            if (url.contains("?")) {
                url = url + "&" + queryForm.toEncodeString()
            } else {
                url = url + "?" + queryForm.toEncodeString()
            }
        }
        url
    }

    /**
     * 将请求体写入请求构建器
     *
     * @param request HTTP 请求
     * @param rb HTTP 请求构建器
     */
    private func writeBody(request: JoyHttpRequest, rb: HttpRequestBuilder): Unit {
        if (let Some(f) <- request._form) {
            let body = f.toEncodeString()
            if (request._headers.getFirst(JoyHttpConsts.HEADER_CONTENT_TYPE).isNone()) {
                rb.header(JoyHttpConsts.HEADER_CONTENT_TYPE, JoyHttpConsts.MIME_APP_FORM_URL_ENCODED)
            }
            rb.post().body(body)
            return
        }

        match (request._body) {
            case x: String =>
                if (request._headers.getFirst(JoyHttpConsts.HEADER_CONTENT_TYPE).isNone()) {
                    rb.header(JoyHttpConsts.HEADER_CONTENT_TYPE, JoyHttpConsts.MIME_TEXT_PLAIN_UTF8)
                }
                rb.body(x)
            case x: JsonRequest => x.write(rb)
            case x: Array<Byte> => rb.body(x)
            case x: JsonSerializable =>
                let buffer = ByteBuffer()
                let writer = JsonWriter(buffer)
                writer.writeValue(x)
                writer.flush()
                if (request._headers.getFirst(JoyHttpConsts.HEADER_CONTENT_TYPE).isNone()) {
                    rb.header(JoyHttpConsts.HEADER_CONTENT_TYPE, JoyHttpConsts.MIME_APP_JSON_UTF8)
                }
                rb.body(buffer)
            case x: InputStream => rb.body(x)
            case _ => ()
        }
    }
}
