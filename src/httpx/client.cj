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

import std.collection.{Map}
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
}

public class JoyHttpClientService <: JoyHttpClient & Resource {
    private let _client: Client
    private let _url: String
    private var _isClosed = false

    public init(url: String, verify!: Bool = false,
        budilerFn!: (url: String, verify: Bool) -> ClientBuilder = defaultNoVerifyHttpCert) {
        _url = url.trimEnd("/")
        _client = budilerFn(url, verify).build()
    }

    ~init() {
        _client.close()
    }

    public func destroy(): Unit {
        close()
    }

    public func close(): Unit {
        if (_isClosed) {
            return
        }
        _client.close()
        _isClosed = true
    }

    public func isClosed(): Bool {
        _isClosed
    }

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

    private func writeBody(request: JoyHttpRequest, rb: HttpRequestBuilder): Unit {
        match (request._body) {
            case x: String =>
                if (request._headers.getFirst(JoyHttpConsts.HEADER_CONTENT_TYPE).isNone()) {
                    rb.header(JoyHttpConsts.HEADER_CONTENT_TYPE, JoyHttpConsts.MIME_TEXT_PLAIN_UTF8)
                }
                rb.body(x)
            case x: JsonRequest<JsonSerializable> => x.write(rb)
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
