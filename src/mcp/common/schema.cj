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

import std.collection.{HashMap, ArrayList}
import cjoy.json.*

// ---------------------------------------------------------------------------------------
// Base

public abstract class McpMessage <: ToString & JsonSerializable {
    public func toString(): String {
        JsonTool.toJson(this)
    }
}

public abstract class JSONRPCMessage <: McpMessage {}

@Json
public class JSONRPCRequest <: JSONRPCMessage {
    public var jsonrpc: String = McpConsts.JSON_RPC_VERSION
    public var id: Any = Option<Any>.None
    public var method: String = ""
    @JsonField[raw = true]
    public var params: Any = Option<Any>.None
}

@Json
public class JSONRPCError <: McpMessage {
    public var code: Int = 0
    public var message: ?String = None
    public var data: Any = Option<Any>.None
}

@Json
public class JSONRPCResponse <: JSONRPCMessage {
    public var jsonrpc: String = McpConsts.JSON_RPC_VERSION
    public var id: Any = Option<Any>.None
    @JsonField[raw = true]
    public var result: Any = Option<Any>.None
    public var error: ?JSONRPCError = None
}

@Json
public class JSONRPCNotification <: JSONRPCMessage {
    public var jsonrpc: String = McpConsts.JSON_RPC_VERSION
    public var method: String = ""
    @JsonField[raw = true]
    public var params: Any = Option<Any>.None
}

public type Role = String

@Json
public class PaginatedRequest <: McpMessage {
    @JsonField[omitempty = true]
    public var cursor: ?String = None
}

@Json
public class PaginatedResult <: McpMessage {
    public var nextCursor: String = ""
}

// ---------------------------------------------------------------------------------------
// Initialize

@Json
public class Implementation <: McpMessage {
    public var name: String = ""
    public var version: String = ""
}

@Json
public class ClientCapabilities <: McpMessage {
    public var experimental: HashMap<String, String> = HashMap()
}

@Json
public class ToolCapability <: McpMessage {
    public var listChanged: Bool = false
}

@Json
public class ResourceCapability <: McpMessage {
    public var subscribe: Bool = false
    public var listChanged: Bool = false
}

@Json
public class ServerCapabilities <: McpMessage {
    public var tools: ?ToolCapability = None
    public var resources: ?ResourceCapability = None
}

@Json
public class InitializeRequest <: McpMessage {
    public var protocolVersion: String = McpConsts.LASTEST_PROTOCOL_VERSION
    public var capabilities: ?ClientCapabilities = None
    public var clientInfo: ?Implementation = None
}

@Json
public class InitializeResult <: McpMessage {
    public var protocolVersion: String = McpConsts.LASTEST_PROTOCOL_VERSION
    public var capabilities: ?ServerCapabilities = None
    public var serverInfo: ?Implementation = None
    public var instructions: ?String = None
}

// ---------------------------------------------------------------------------------------
// Tool

@Json
public class McpTool <: McpMessage {
    public var name: String = ""
    public var description: String = ""
    public var inputSchema: Any = Option<Any>.None
}

@Json
public class ListToolsResult <: McpMessage {
    public var nextCursor: ?String = None
    public var tools: ArrayList<McpTool> = ArrayList()
}

@Json
public class CallToolRequest <: McpMessage {
    public var name: String = ""

    @JsonField[omitempty = true, raw = true]
    public var arguments: Any = Option<Any>.None
}

@Json[subTypeField = "type", subTypes = { "text": "TextContent", "image": "ImageContent", "audio": "AudioContent" }]
public open class Content <: McpMessage {
    @JsonField[name = "type"]
    public var type_: String = ""
}

@Json[superClass = Content]
public class TextContent <: Content {
    public var text: String = ""
}

@Json[superClass = Content]
public class ImageContent <: Content {
    public var data: String = ""
    public var mimeType: String = ""
}

@Json[superClass = Content]
public class AudioContent <: Content {
    public var data: String = ""
    public var mimeType: String = ""
}

@Json
public class CallToolResult <: McpMessage {
    public var isError: Bool = false
    public var content: ArrayList<Content> = ArrayList()
}

// ---------------------------------------------------------------------------------------
// Resource

@Json
public class McpResource <: McpMessage {
    public var uri: String = ""
    public var name: String = ""
    public var description: ?String = None
    public var mimeType: ?String = None
    public var size: ?Int = None
}

@Json
public class ResourceTemplate <: McpMessage {
    public var uriTemplate: String = ""
    public var name: String = ""
    public var description: ?String = None
    public var mimeType: ?String = None
}

@Json
public class ListResourcesResult <: McpMessage {
    public var nextCursor: ?String = None
    public var resources: ArrayList<McpResource> = ArrayList()
}

@Json
public class ListResourceTemplatesResult <: McpMessage {
    public var nextCursor: ?String = None
    public var ResourceTemplates: ArrayList<ResourceTemplate> = ArrayList()
}

@Json
public class ReadResourceRequest <: McpMessage {
    public var uri: String = ""
}

@Json
public open class ResourceContents <: McpMessage {
    public var uri: String = ""
    public var mimeType: String = ""
}

@Json[superClass = ResourceContents]
public class TextResourceContents <: ResourceContents {
    public var text: String = ""
}

@Json[superClass = ResourceContents]
public class BlobResourceContents <: ResourceContents {
    public var blob: String = ""
}

@Json
public class ReadResourceResult <: McpMessage {
    public var contents: ArrayList<ResourceContents> = ArrayList()
}

// ---------------------------------------------------------------------------------------
// Const

public struct McpConsts {
    // protocol
    public static const JSON_RPC_VERSION = "2.0"
    public static const LASTEST_PROTOCOL_VERSION = "2024-11-05"

    // role 
    public static const ROLE_USER = "user"
    public static const ROLE_ASSISTANT = "assistant"

    // error code
    public static const ERR_PARSE_ERROR = -32700
    public static const ERR_INVALID_REQUEST = -32600
    public static const ERR_METHOD_NOT_FOUND = -32601
    public static const ERR_INVALID_PARAMS = -32602
    public static const ERR_INTERNAL_ERROR = -32603

    // methods
    public static const METHOD_INITIALIZE = "initialize"
    public static const METHOD_NOTIFICATION_INITIALIZED = "notifications/initialized"
    public static const METHOD_PING = "ping"
    public static const METHOD_TOOLS_LIST = "tools/list"
    public static const METHOD_TOOLS_CALL = "tools/call"
    public static const METHOD_NOTIFICATION_TOOLS_LIST_CHANGED = "notifications/tools/list_changed"

    // event
    public static const EVENT_MESSAGE = "message"
    public static const EVENT_ENDPOINT = "endpoint"

    // content-type
    public static const CONTENT_TYPE_JSON = "appliction/json"
    public static const CONTENT_TYPE_SSE = "text/event-stream"

    // header
    public static const HEADER_MCP_SESSION_ID = "mcp-session-id"
    public static const HEADER_LAST_EVENT_ID = "last-event-id"
}

public class McpException <: Exception {
    public let error: JSONRPCError

    public init(error: JSONRPCError) {
        super(error.message ?? "")
        this.error = error
    }
}
