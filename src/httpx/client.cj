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
import stdx.encoding.url.URL
import cjoy.context.Context
import cjoy.framework.{JoyHttpConsts}

func defaultNoVerifyHttpCert(url: String): ClientBuilder {
    let cb = ClientBuilder()
    if (url.startsWith("https")) {
        var config = TlsClientConfig()
        config.verifyMode = TrustAll
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

public class JoyHttpClientService <: JoyHttpClient {
    private let _client: Client
    private let _url: String

    public init(url: String, budilerFn!: (url: String) -> ClientBuilder = defaultNoVerifyHttpCert) {
        _url = url.trimEnd("/")
        _client = budilerFn(url).build()
    }

    ~init() {
        _client.close()
    }

    public func destroy(): Unit {
        _client.close()
    }

    public func exechange(ctx: Context, method: String, path: String, params: Map<String, ToString>,
        headers: HttpHeaders, body: Any): JoyHttpResponse {
        var url = if (path.startsWith("/")) {
            _url + path
        } else {
            _url + "/" + path
        }
        for ((k, v) in params) {
            url = url.replace("{${k}}", v.toString())
        }

        let rb = HttpRequestBuilder().url(url)
        rb.setHeaders(headers)
        match (method) {
            case "GET" => rb.get()
            case "POST" => rb.post()
            case "PUT" => rb.put()
            case "DELETE" => rb.delete()
            case _ => ()
        }

        match (body) {
            case x: String => rb.header(JoyHttpConsts.HEADER_CONTENT_TYPE, JoyHttpConsts.MIME_TEXT_PLAIN_UTF8).body(x)
            case x: JsonRequest<JsonSerializable> => x.write(rb)
            case x: Array<Byte> => rb.body(x)
            case x: JsonSerializable =>
                let buffer = ByteBuffer()
                let writer = JsonWriter(buffer)
                writer.writeValue(x)
                writer.flush()
                rb.header(JoyHttpConsts.HEADER_CONTENT_TYPE, JoyHttpConsts.MIME_APP_JSON_UTF8).body(buffer)
            case x: InputStream => rb.body(x)
            case _ => ()
        }

        let rsp = _client.send(rb.build())
        JoyHttpResponse(rsp)
    }
}
