/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

public package cjoy.mcp.client

import std.collection.HashMap
import std.io.{ByteBuffer, StringReader}
import stdx.net.http.{Client, ClientBuilder, HttpRequestBuilder}
import cjoy.mcp.api.*
import cjoy.jsonrpc.*
import cjoy.log.macros.*

/**
 * 基于 Streamable HTTP 的 MCP 客户端传输
 *
 * 每个请求通过 POST 发送，响应可以是 JSON 或 SSE 流；
 * 初始化时服务器返回的 mcp-session-id 会在后续请求中携带。
 */
class McpStreamableClientTransport <: McpClientTransport {
    private let _url: String
    private let _client: Client
    private var _sessionId: ?String = None
    private var _consumer: ?(ByteBuffer) -> Unit = None
    private var _callback: ?() -> Unit = None
    private var _isClosed: Bool = false

    init(url: String) {
        _url = url
        _client = ClientBuilder().build()
    }

    public func connect(consumer: (ByteBuffer) -> Unit): Unit {
        _consumer = consumer
    }

    public func whenReConnect(callback: () -> Unit): Unit {
        _callback = callback
    }

    public func send(message: ByteBuffer): Unit {
        let builder = HttpRequestBuilder().url(_url).method("POST")
            .header("Content-Type", "application/json")
            .header("Accept", "application/json, text/event-stream")
            .header(McpConsts.HEADER_PROTOCOL_VERSION, McpConsts.LASTEST_PROTOCOL_VERSION)
            .body(message.bytes())
        if (let Some(id) <- _sessionId) {
            builder.header(McpConsts.HEADER_MCP_SESSION_ID, id)
        }
        let rsp = _client.send(builder.build())
        // 必须先完整读取响应体，再让连接回到池中
        let body = StringReader(rsp.body).readToEnd()

        if (rsp.status >= 300) {
            throw JSONRPCException(JSONRPCError(code: JSONRPCConsts.ERR_INTERNAL_ERROR, message: body))
        }

        if (let Some(id) <- rsp.headers.getFirst(McpConsts.HEADER_MCP_SESSION_ID)) {
            _sessionId = Some(id)
        }

        dispatch(body, rsp.headers.getFirst("Content-Type") ?? "")
    }

    /**
     * 将响应内容按 JSON 或 SSE 格式分发给消息消费者
     */
    private func dispatch(body: String, contentType: String): Unit {
        if (body.isEmpty()) {
            return
        }
        let consumer = _consumer.getOrThrow()
        if (contentType.toAsciiLower().contains("text/event-stream")) {
            // SSE 响应：逐条提取 data 行
            for (block in body.split("\n\n")) {
                var data = StringBuilder()
                for (line in block.split("\n")) {
                    if (line.startsWith("data:")) {
                        if (data.size > 0) {
                            data.append("\n")
                        }
                        data.append(line.trimStart("data:").trimAscii())
                    }
                }
                if (data.size > 0) {
                    let buffer = ByteBuffer()
                    buffer.write(data.toString().toArray())
                    consumer(buffer)
                }
            }
        } else {
            let buffer = ByteBuffer()
            buffer.write(body.toArray())
            consumer(buffer)
        }
    }

    public func close(): Unit {
        if (_isClosed) {
            return
        }
        _isClosed = true
        _client.close()
    }

    public func isClosed(): Bool {
        _isClosed
    }
}
