/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

protected package cjoy.mcp.common

import std.io.ByteBuffer
import stdx.encoding.json.stream.{JsonDeserializable, JsonSerializable}
import cjoy.mcp.schema.*

public interface McpSession <: Resource {
    func sendRequest<T>(method: String, requestParams: JsonSerializable): T where T <: JsonDeserializable<T>
    func sendNotification(method: String, params: ?JsonSerializable): Unit
    func sendNotification(method: String) {
        sendNotification(method, None)
    }
    func addNotificationConsumer(method: String, consumer: (Array<Byte>) -> Unit): Unit
}

public interface McpServerSession <: McpSession {
    func handle(message: JSONRPCMessage): Unit
}

public interface McpNotificationHandler {
    func onNotification(message: JSONRPCNotification): Unit
}

public interface McpResponseHandler {
    func onResponse(message: JSONRPCResponse): Unit
}

public interface McpRequestHandler {
    func onRequest(message: JSONRPCRequest): Unit
}

public interface McpToolRequestHandler {
    func handle(param: Array<Byte>): String
}

public interface McpTransport <: Resource {
    func send(message: ByteBuffer): Unit
}

public interface McpClientTransport <: McpTransport {
    func connect(consumer: (ByteBuffer) -> Unit): Unit
}

public interface McpServerTransport <: McpTransport {}

public interface McpClient <: Resource {
    prop serverCapabilities: ?ServerCapabilities
    prop serverInfo: ?Implementation

    func ping(): Unit
    func initialize(): InitializeResult

    func listTools(cursor: ?String): ListToolsResult
    func listTools(): ListToolsResult {
        listTools(None)
    }
    func callTool(request: CallToolRequest): CallToolResult
}
