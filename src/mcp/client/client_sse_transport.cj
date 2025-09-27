/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

public package cjoy.mcp.client

import std.time.DateTime
import std.io.ByteBuffer
import std.collection.HashMap
import std.sync.AtomicBool
import stdx.encoding.url.URL
import cjoy.mcp.api.*
import cjoy.log.*
import cjoy.httpx.{JoySSEventStream, JoySimpleHttpClient}

class McpSseClientTransport <: McpClientTransport {
    private let _url: String
    private let _baseUrl: String
    private var _lastInitTime: DateTime
    private var _endpoint: String = ""
    private var _consumer: ?(ByteBuffer) -> Unit = None
    private var _callback: ?()->Unit = None
    private var _sseStream: ?JoySSEventStream = None
    private var _connected = AtomicBool(false)

    private var _isClosed: Bool = false

    prop seeStream: JoySSEventStream {
        get() {
            _sseStream.getOrThrow()
        }
    }

    init(url: String) {
        _url = url
        _lastInitTime = DateTime.now()
        var u = URL.parse(url)
        u = u.replace(path: "")
        _baseUrl = u.toString()
        @LogInfo("[MCP]http sse base url: ${_baseUrl}")
    }

    public func connect(consumer: (ByteBuffer) -> Unit): Unit {
        _consumer = consumer
        doConnect()
    }

    public func whenReConnect(callback: ()->Unit): Unit {
        _callback = callback
    }

    private func doConnect() {
        if (_connected.load()) {
            return
        }
        _lastInitTime = DateTime.now()
        _sseStream = JoySimpleHttpClient.sseConnect(_url)
        let seeStream_ = this.seeStream
        if (let Some(evt) <- seeStream_.next()) {
            if (evt.event != McpConsts.EVENT_ENDPOINT) {
                throw McpException(
                    JSONRPCError(code: McpConsts.ERR_INTERNAL_ERROR, message: "invliad endpoint event ${evt}"))
            }
            _endpoint = evt.data
        }
        _connected.store(true)

        // recv sse message 
        let consumer_ = _consumer.getOrThrow()
        let connected_ = _connected
        spawn {
            while (let Some(evt) <- seeStream_.next()) {
                if (evt.event != McpConsts.EVENT_MESSAGE) {
                    @LogError("invliad message event ${evt}")
                    break
                }
                let buffer = ByteBuffer()
                unsafe { buffer.write(evt.data.rawData()) }
                consumer_(buffer)
            }
            @LogInfo("[MCP]http sse stream is close")
            connected_.store(false)
        }
    }

    private func checkConnected() {
        if (!_connected.load()) {
            _sseStream?.close()
            doConnect()
            _callback?()
        }
    }

    public func send(message: ByteBuffer): Unit {
        checkConnected()
        let header = HashMap<String, String>([("Content-Type", "application/json")])
        let resp: Option<String> = JoySimpleHttpClient.post("${_baseUrl}${_endpoint}", message.bytes(), header: header, verify: false)
        if (let Some(v) <- resp) {
            if (v !="") {
                @LogInfo("[MCP]http request response ${v}")
            }
        }
    }

    public func close() {
        if (_isClosed) {
            return
        }
        _sseStream?.close()
        _isClosed = true
    }

    public func isClosed(): Bool {
        _isClosed
    }
}
