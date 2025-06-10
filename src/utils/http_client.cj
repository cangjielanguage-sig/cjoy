/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.utils

import std.collection.HashMap
import std.net.{SocketAddress, TcpSocket}
import std.io.StringReader
import stdx.net.tls.{TlsClientConfig, CertificateVerifyMode}
import stdx.net.http.*
import stdx.encoding.url.URL
import cjoy.log.LogTool

// modified from CangjieMagic

protected struct HttpClient {
    public static func sseConnect(url: String, verify!: Bool = false): SSEventStream {
        let header = HashMap<String, String>()
        header.add("Accept", "text/event-stream")
        let httpStream = asyncGet(url, header: header, body: None, verify: verify)
        return SSEventStream(httpStream)
    }

    public static func get(
        url: String,
        body!: Option<Array<Byte>> = None,
        header!: HashMap<String, String> = HashMap(),
        verify!: Bool = false
    ): Option<String> {
        return send("GET", url, header, body, verify: verify)
    }

    public static func post(
        url: String,
        body: Array<Byte>,
        header!: HashMap<String, String> = HashMap(),
        verify!: Bool = false
    ): Option<String> {
        return send("POST", url, header, body, verify: verify)
    }

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
            let err = readHttpBody(resp)
            LogTool.error("http request failed, ${method} ${url}, error:${err}")
            client.close()
            return None
        }
        let respBody = readHttpBody(resp)
        client.close()
        return respBody
    }

    public static func asyncGet(
        url: String,
        body!: Option<Array<Byte>> = None,
        header!: HashMap<String, String> = HashMap(),
        verify!: Bool = false
    ): HttpStream {
        return asyncSend("GET", url, header, body, verify: verify)
    }

    public static func asyncPost(
        url: String,
        body: Array<Byte>,
        header!: HashMap<String, String> = HashMap(),
        verify!: Bool = false
    ): HttpStream {
        return asyncSend("POST", url, header, body, verify: verify)
    }

    public static func asyncSend(
        method: String,
        url: String,
        header: HashMap<String, String>,
        body: Option<Array<Byte>>,
        verify!: Bool
    ): HttpStream {
        logHttpInfo(method, url, header, body)
        let (client, resp) = sendHttp(method, url, header, body, verify)
        let httpStream = HttpStream()
        if (resp.status != HttpStatusCode.STATUS_OK) {
            let err = readHttpBody(resp)
            LogTool.error("http request failed, ${method} ${url}, error:${err}")
            client.close()
            httpStream.markError()
        } else {
            spawn {
                let buffer = Array<Byte>(1024 * 10, {_ => 0})
                while (true) {
                    let length = resp.body.read(buffer)
                    if (length == 0) {
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

    private static func buildHttpClient(url: String, verify: Bool): Client {
        let cb = ClientBuilder()
        cb.readTimeout(Duration.minute * 10)
        if (url.startsWith("https")) {
            var config = TlsClientConfig()
            if (!verify) {
                config.verifyMode = TrustAll
            }
            config.domain = URL.parse(url).hostName
            cb.tlsConfig(config)
        }
        let TcpSocketConnector = {
            sa: SocketAddress =>
            let socket = TcpSocket(sa)
            socket.readTimeout = Duration.second * 60
            socket.writeTimeout = Duration.second * 60
            socket.connect(timeout: Duration.second * 60)
            return socket
        }
        cb.connector(TcpSocketConnector)
        return cb.build()
    }

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

    private static func sendHttp(
        method: String,
        url: String,
        header: HashMap<String, String>,
        body: Option<Array<Byte>>,
        verify: Bool
    ): (Client, HttpResponse) {
        let client = buildHttpClient(url, verify)
        let req = prepareHttpRequest(method, url, header, body)
        return (client, client.send(req))
    }

    private static func readHttpBody(resp: HttpResponse): String {
        let reader = StringReader(resp.body)
        return reader.readToEnd()
    }

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
        LogTool.debug("${sb.toString()}")
    }
}
