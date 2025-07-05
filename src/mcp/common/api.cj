/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.mcp.common

import std.io.ByteBuffer
import std.collection.HashMap
import std.fs.{File, OpenMode, Path}
import std.io.{readToEnd}
import stdx.encoding.json.stream.{JsonDeserializable, JsonSerializable}
import stdx.encoding.base64.toBase64String
import cjoy.framework.{JoyContext, JoyRequestHandler, JoyHttpConsts}
import cjoy.multipart.getMimeTypeByExt

public interface McpSession <: Resource {
    func sendRequest<T>(method: String, requestParams: JsonSerializable): T where T <: JsonDeserializable<T>
    func sendNotification(method: String, params: ?JsonSerializable): Unit
    func sendNotification(method: String) {
        sendNotification(method, None)
    }
    func addNotificationConsumer(method: String, consumer: (Array<Byte>) -> Unit): Unit
}

public interface McpServerSession <: McpSession {
    func handle(ctx: JoyContext, message: JSONRPCMessage): Unit
}

public interface McpClientSession <: McpSession {
    func connect(): Unit
}

public interface McpNotificationHandler {
    func onNotification(message: JSONRPCNotification): Unit
}

public interface McpResponseHandler {
    func onResponse(message: JSONRPCResponse): Unit
}

public interface McpRequestHandler {
    func onRequest(ctx: JoyContext, message: JSONRPCRequest): Unit
}

public interface McpCallToolHandler {
    func handle(ctx: JoyContext, arguments: Array<Byte>): Any
}

public interface McpReadResourceHandler {
    func readResource(ctx: JoyContext): Any
}

public interface McpGetPromptHandler {
    func getPrompt(ctx: JoyContext, arguments: HashMap<String, String>): Any
}

public interface McpTransport <: Resource {
    func send(message: ByteBuffer): Unit
}

public interface McpClientTransport <: McpTransport {
    func connect(consumer: (ByteBuffer) -> Unit): Unit
    func whenReConnect(callback: () -> Unit): Unit
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

    func listResources(cursor: ?String): ListResourcesResult
    func listResources(): ListResourcesResult {
        listResources(None)
    }
    func listResourceTemplates(cursor: ?String): ListResourceTemplatesResult
    func listResourceTemplates(): ListResourceTemplatesResult {
        listResourceTemplates(None)
    }
    func readResource(request: ReadResourceRequest): ReadResourceResult

    func listPrompts(cursor: ?String): ListPromptResult
    func listPrompts(): ListPromptResult {
        listPrompts(None)
    }
    func getPrompt(request: GetPromptRequest): GetPromptResult
}

// -----
public class Image {
    public Image(public let path!: String = "", public var data!: Array<Byte> = [], public let format!: String = "") {
    }

    public func toImageContext(): Content {
        var mimeType = if (format != "") {
            "image/${format.toAsciiLower()}"
        } else {
            JoyHttpConsts.MIME_APP_OCTET_STREAM
        }
        if (path != "") {
            try (file = File(path, OpenMode.Read)) {
                data = readToEnd(file)
                let p = Path(path)
                mimeType = getMimeTypeByExt(".${p.extensionName}") ?? JoyHttpConsts.MIME_APP_OCTET_STREAM
            }
        }
        var res = ImageContent(mimeType: mimeType, data: toBase64String(data))
        res.type_ = "image"
        res
    }
}

public class Audio {
    public Audio(public let path!: String = "", public var data!: Array<Byte> = [], public let format!: String = "") {
    }

    public func toAudioContent(): Content {
        var mimeType = if (format != "") {
            "audio/${format.toAsciiLower()}"
        } else {
            JoyHttpConsts.MIME_APP_OCTET_STREAM
        }
        if (path != "") {
            try (file = File(path, OpenMode.Read)) {
                data = readToEnd(file)
                let p = Path(path)
                mimeType = getMimeTypeByExt(".${p.extensionName}") ?? JoyHttpConsts.MIME_APP_OCTET_STREAM
            }
        }
        var res = AudioContent(mimeType: mimeType, data: toBase64String(data))
        res.type_ = "audio"
        res
    }
}

public class Message {
    public Message(public let content!: String = "", public let role!: String = "assistant") {
    }

    public func toPromptMessage(): PromptMessage {
        var res = TextContent(text: content)
        res.type_ = "text"
        PromptMessage(role: role, content: res)
    }
}
