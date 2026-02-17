/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.mcp.api

import std.io.ByteBuffer
import std.collection.HashMap
import std.fs.{File, OpenMode, Path}
import std.io.{readToEnd}
import stdx.encoding.base64.toBase64String
import stdx.encoding.json.stream.{JsonDeserializable, JsonSerializable}
import cjoy.framework.{JoyContext, JoyHttpConsts}
import cjoy.jsonrpc.*
import cjoy.multipart.getMimeTypeByExt

/**
 * base interface for MCP session
 */
public interface McpSession <: Resource {
    /**
     * send a JSON-RPC request and wait for response
     *
     * @param method the method name
     * @param requestParams the request parameters
     * @return the response of type T
     */
    func sendRequest<T>(method: String, requestParams: JsonSerializable): T where T <: JsonDeserializable<T>

    /**
     * send a JSON-RPC notification without waiting for response
     *
     * @param method the notification method name
     * @param params the notification parameters
     */
    func sendNotification(method: String, params: ?JsonSerializable): Unit
    func sendNotification(method: String) {
        sendNotification(method, None)
    }

    /**
     * add a consumer for notification method
     *
     * @param method the notification method name
     * @param consumer the consumer function to handle notification bytes
     */
    func addNotificationConsumer(method: String, consumer: (Array<Byte>) -> Unit): Unit
}

/**
 * MCP server session interface for handling incoming requests
 */
public interface McpServerSession <: McpSession {
    /**
     * handle incoming JSON-RPC message
     *
     * @param ctx the context
     * @param message the JSON-RPC message
     */
    func handle(ctx: JoyContext, message: JSONRPCMessage): Unit
}

/**
 * MCP client session interface for connecting to MCP server
 */
public interface McpClientSession <: McpSession {
    /**
     * connect to MCP server
     */
    func connect(): Unit
}

/**
 * MCP notification handler interface
 */
public interface McpNotificationHandler {
    /**
     * handle notification message
     *
     * @param message the notification message
     */
    func onNotification(message: JSONRPCNotification): Unit
}

/**
 * MCP response handler interface
 */
public interface McpResponseHandler {
    /**
     * handle response message
     *
     * @param message the response message
     */
    func onResponse(message: JSONRPCResponse): Unit
}

/**
 * MCP request handler interface
 */
public interface McpRequestHandler {
    /**
     * handle request message
     *
     * @param ctx the context
     * @param message the request message
     */
    func onRequest(ctx: JoyContext, message: JSONRPCRequest): Unit
}

/**
 * MCP tool call handler interface
 */
public interface McpCallToolHandler {
    /**
     * handle tool call with arguments
     *
     * @param ctx the context
     * @param arguments the tool arguments as bytes
     * @return the result of tool call
     */
    func handle(ctx: JoyContext, arguments: Array<Byte>): Any
}

/**
 * MCP resource read handler interface
 */
public interface McpReadResourceHandler {
    /**
     * read resource content
     *
     * @param ctx the context
     * @return the resource content
     */
    func readResource(ctx: JoyContext): Any
}

/**
 * MCP prompt get handler interface
 */
public interface McpGetPromptHandler {
    /**
     * get prompt content with arguments
     *
     * @param ctx the context
     * @param arguments the prompt arguments
     * @return the prompt content
     */
    func getPrompt(ctx: JoyContext, arguments: HashMap<String, String>): Any
}

/**
 * MCP transport interface for message communication
 */
public interface McpTransport <: Resource {
    /**
     * send message through transport
     *
     * @param message the message bytes to send
     */
    func send(message: ByteBuffer): Unit
}

/**
 * MCP client transport interface with connection support
 */
public interface McpClientTransport <: McpTransport {
    /**
     * connect to transport with message consumer
     *
     * @param consumer the consumer function to handle incoming messages
     */
    func connect(consumer: (ByteBuffer) -> Unit): Unit

    /**
     * set callback when reconnected
     *
     * @param callback the callback function
     */
    func whenReConnect(callback: () -> Unit): Unit
}

/**
 * MCP server transport interface
 */
public interface McpServerTransport <: McpTransport {}

/**
 * MCP client interface for communicating with MCP server
 */
public interface McpClient <: Resource {
    /**
     * return server capabilities
     */
    prop serverCapabilities: ?ServerCapabilities

    /**
     * return server info
     */
    prop serverInfo: ?Implementation

    /**
     * send ping request
     */
    func ping(): Unit

    /**
     * initialize connection with server
     *
     * @return the initialize result
     */
    func initialize(): InitializeResult

    /**
     * list available tools
     *
     * @param cursor the pagination cursor
     * @return the list tools result
     */
    func listTools(cursor: ?String): ListToolsResult
    func listTools(): ListToolsResult {
        listTools(None)
    }

    /**
     * call a tool
     *
     * @param request the tool call request
     * @return the tool call result
     */
    func callTool(request: CallToolRequest): CallToolResult

    /**
     * list available resources
     *
     * @param cursor the pagination cursor
     * @return the list resources result
     */
    func listResources(cursor: ?String): ListResourcesResult
    func listResources(): ListResourcesResult {
        listResources(None)
    }

    /**
     * list resource templates
     *
     * @param cursor the pagination cursor
     * @return the list resource templates result
     */
    func listResourceTemplates(cursor: ?String): ListResourceTemplatesResult
    func listResourceTemplates(): ListResourceTemplatesResult {
        listResourceTemplates(None)
    }

    /**
     * read resource content
     *
     * @param request the read resource request
     * @return the read resource result
     */
    func readResource(request: ReadResourceRequest): ReadResourceResult

    /**
     * list available prompts
     *
     * @param cursor the pagination cursor
     * @return the list prompts result
     */
    func listPrompts(cursor: ?String): ListPromptResult
    func listPrompts(): ListPromptResult {
        listPrompts(None)
    }

    /**
     * get prompt content
     *
     * @param request the get prompt request
     * @return the get prompt result
     */
    func getPrompt(request: GetPromptRequest): GetPromptResult
}

/**
 * Represents an image content type for MCP
 *
 * This class provides functionality to load images from files or raw data
 * and convert them to ImageContent format for use in MCP responses.
 */
public class Image {
    /**
     * Initializes a new Image instance
     *
     * @param path Path to the image file (default: empty string)
     * @param data Raw image data (default: empty array)
     * @param format Image format (e.g., "png", "jpeg") (default: empty string)
     */
    public Image(public let path!: String = "", public var data!: Array<Byte> = [], public let format!: String = "") {
    }

    /**
     * Converts the Image to ImageContent format for MCP responses
     *
     * @return ImageContent instance containing the image data
     */
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

/**
 * Represents an audio content type for MCP
 *
 * This class provides functionality to load audio from files or raw data
 * and convert them to AudioContent format for use in MCP responses.
 */
public class Audio {
    /**
     * Initializes a new Audio instance
     *
     * @param path Path to the audio file (default: empty string)
     * @param data Raw audio data (default: empty array)
     * @param format Audio format (e.g., "mp3", "wav") (default: empty string)
     */
    public Audio(public let path!: String = "", public var data!: Array<Byte> = [], public let format!: String = "") {
    }

    /**
     * Converts the Audio to AudioContent format for MCP responses
     *
     * @return AudioContent instance containing the audio data
     */
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

/**
 * Represents a message type for MCP prompts
 *
 * This class provides functionality to create prompt messages with
 * specific roles (e.g., user, assistant) for use in MCP responses.
 */
public class Message {
    /**
     * Initializes a new Message instance
     *
     * @param content Message content (default: empty string)
     * @param role Message sender role (e.g., "user", "assistant") (default: "assistant")
     */
    public Message(public let content!: String = "", public let role!: String = "assistant") {
    }

    /**
     * Converts the Message to PromptMessage format for MCP responses
     *
     * @return PromptMessage instance containing the message
     */
    public func toPromptMessage(): PromptMessage {
        var res = TextContent(text: content)
        res.type_ = "text"
        PromptMessage(role: role, content: res)
    }
}
