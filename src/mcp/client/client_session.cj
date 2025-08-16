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

import std.collection.concurrent.ConcurrentHashMap
import std.sync.{AtomicUInt64, SyncCounter}
import std.io.ByteBuffer
import stdx.encoding.json.stream.{JsonDeserializable, JsonSerializable, JsonReader}
import cjoy.mcp.api.*
import cjoy.utils.{TimeoutCache, randStr}
import cjoy.log.LogTool

class ResponseWaiter {
    ResponseWaiter(var response!: ?JSONRPCResponse = None, let counter!: SyncCounter = SyncCounter(1)) {}
}

class DefaultMcpClientSession <: McpClientSession & McpResponseHandler & McpNotificationHandler {
    private let _transport: McpClientTransport
    private let _requestTimeout: Duration
    private let _sessPefix: String = randStr(8)
    private let _reqCount: AtomicUInt64 = AtomicUInt64(0)
    private let _respWaiters: TimeoutCache<String, ResponseWaiter>
    private let _notificationConsumer: ConcurrentHashMap<String, (Array<Byte>) -> Unit> = ConcurrentHashMap()
    private var _isClosed: Bool = false

    init(transport: McpClientTransport, requestTimeout: Duration) {
        _transport = transport
        _requestTimeout = requestTimeout
        _respWaiters = TimeoutCache(requestTimeout) {
            k, v => LogTool.info("MCP request is timout, id: ${k}")
        }
    }

    private func genReqId(): String {
        "${_sessPefix}-${_reqCount.fetchAnd(1)}"
    }

    public func connect(): Unit {
        _transport.connect(
            {
                buffer: ByteBuffer =>
                let message = RPCJsonTool.deserialize(buffer)
                match (message) {
                    case m: JSONRPCResponse => onResponse(m)
                    case m: JSONRPCNotification => onNotification(m)
                    case _ => LogTool.info("[MCP]client recv unknown message")
                }
            }
        )
    }

    public func sendRequest<T>(method: String, requestParams: JsonSerializable): T where T <: JsonDeserializable<T> {
        let id = genReqId()
        let request = JSONRPCRequest(id: id, method: method, params: requestParams)
        let waiter = ResponseWaiter()
        _respWaiters.add(id, waiter)
        _transport.send(RPCJsonTool.serialize(request))
        LogTool.debug("[MCP]sent request, method: ${method}, id: ${id}")

        waiter.counter.waitUntilZero(timeout: _requestTimeout)
        match (waiter.response) {
            case Some(r) =>
                if (let Some(err) <- r.error) {
                    throw McpException(err)
                }
                let buffer = ByteBuffer()
                buffer.write((r.result as Array<Byte>).getOrThrow())
                let reader = JsonReader(buffer)
                T.fromJson(reader)
            case _ => throw McpException(
                JSONRPCError(code: McpConsts.ERR_INTERNAL_ERROR, message: "wait reponse timeout"))
        }
    }

    public func sendNotification(method: String, params: ?JsonSerializable): Unit {
        let message = if (let Some(v) <- params) {
            JSONRPCNotification(method: method, params: params)
        } else {
            JSONRPCNotification(method: method)
        }
        _transport.send(RPCJsonTool.serialize(message))
        LogTool.info("[MCP]send notification, method:${method}")
    }

    public func addNotificationConsumer(method: String, consumer: (Array<Byte>) -> Unit): Unit {
        _notificationConsumer.add(method, consumer)
    }

    public func onResponse(message: JSONRPCResponse): Unit {
        let id = (message.id as String) ?? ""
        _respWaiters.get(id).map(
            {
                waiter: ResponseWaiter =>
                waiter.response = message
                waiter.counter.dec()
            }
        )
    }

    public func onNotification(message: JSONRPCNotification): Unit {
        _notificationConsumer
            .get(message.method)
            .map({
                consumer: (Array<Byte>) -> Unit => consumer((message.params as Array<Byte>) ?? Array<Byte>())
            })
    }

    public func close() {
        if (_isClosed) {
            return
        }
        _transport.close()
        _respWaiters.close()
        _isClosed = true
    }

    public func isClosed(): Bool {
        _isClosed
    }
}
