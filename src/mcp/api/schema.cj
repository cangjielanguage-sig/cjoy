/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.mcp.api

import std.collection.{HashMap, ArrayList}
import cjoy.jsonrpc.*
import cjoy.json.*

// ---------------------------------------------------------------------------------------

public type Role = String

@Json
public class PaginatedRequest <: BaseMessage {
    @JsonField[omitempty = true]
    public var cursor: ?String = None
}

@Json
public class PaginatedResult <: BaseMessage {
    public var nextCursor: String = ""
}

@Json
public class Annotations <: BaseMessage {
    public var audience: ArrayList<Role> = ArrayList()
    public var priority: Float32 = 0.0
}

// ---------------------------------------------------------------------------------------
// Initialize

@Json
public class Implementation <: BaseMessage {
    public var name: String = ""
    public var version: String = ""
}

@Json
public class ClientCapabilities <: BaseMessage {
    public var experimental: HashMap<String, String> = HashMap()
}

@Json
public class ToolCapability <: BaseMessage {
    public var listChanged: Bool = false
}

@Json
public class ResourceCapability <: BaseMessage {
    public var subscribe: Bool = false
    public var listChanged: Bool = false
}

@Json
public class PromptsCapability <: BaseMessage {
    public var listChanged: Bool = false
}

@Json
public class ServerCapabilities <: BaseMessage {
    public var tools: ?ToolCapability = None
    public var resources: ?ResourceCapability = None
    public var prompts: ?PromptsCapability = None
}

@Json
public class InitializeRequest <: BaseMessage {
    public var protocolVersion: String = McpConsts.LASTEST_PROTOCOL_VERSION
    public var capabilities: ?ClientCapabilities = None
    public var clientInfo: ?Implementation = None
}

@Json
public class InitializeResult <: BaseMessage {
    public var protocolVersion: String = McpConsts.LASTEST_PROTOCOL_VERSION
    public var capabilities: ?ServerCapabilities = None
    public var serverInfo: ?Implementation = None
    public var instructions: ?String = None
}

// ---------------------------------------------------------------------------------------
// Tool

@Json
public class ToolAnnotations <: BaseMessage {
    public var title: String = ""
    public var readOnlyHint: Bool = false
    public var destructiveHint: Bool = false
    public var idempotentHint: Bool = false
    public var opneWorldHint: Bool = true
}

@Json
public class McpTool <: BaseMessage {
    public var name: String = ""
    public var description: String = ""
    public var inputSchema: Any = Option<Any>.None
    public var annotations: ?ToolAnnotations = None
}

@Json
public class ListToolsResult <: BaseMessage {
    public var nextCursor: ?String = None
    public var tools: ArrayList<McpTool> = ArrayList()
}

@Json
public class CallToolRequest <: BaseMessage {
    public var name: String = ""

    @JsonField[omitempty = true, raw = true]
    public var arguments: Any = Option<Any>.None
}

@Json[subTypeField = "type", subTypes = { "text": "TextContent", "image": "ImageContent", "audio": "AudioContent", "resource": "EmbeddedResource" }]
public open class Content <: BaseMessage {
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
public class CallToolResult <: BaseMessage {
    public var isError: Bool = false
    public var content: ArrayList<Content> = ArrayList()
}

// ---------------------------------------------------------------------------------------
// Resource

@Json
public class McpResource <: BaseMessage {
    public var uri: String = ""
    public var name: String = ""
    public var description: ?String = None
    public var mimeType: ?String = None
    public var size: ?Int = None
    public var annotations: ?Annotations = None
}

@Json
public class ResourceTemplate <: BaseMessage {
    public var uriTemplate: String = ""
    public var name: String = ""
    public var description: ?String = None
    public var mimeType: ?String = None
    public var annotations: ?Annotations = None
}

@Json
public class ListResourcesResult <: BaseMessage {
    public var nextCursor: ?String = None
    public var resources: ArrayList<McpResource> = ArrayList()
}

@Json
public class ListResourceTemplatesResult <: BaseMessage {
    public var nextCursor: ?String = None
    public var resourceTemplates: ArrayList<ResourceTemplate> = ArrayList()
}

@Json
public class ReadResourceRequest <: BaseMessage {
    public var uri: String = ""
}

@Json[subTypeAs = true, subTypes = { "text": "TextResourceContents", "blob": "BlobResourceContents" }]
public open class ResourceContents <: BaseMessage {
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
public class ReadResourceResult <: BaseMessage {
    public var contents: ArrayList<ResourceContents> = ArrayList()
}

@Json[superClass = Content]
public class EmbeddedResource <: Content {
    public var resource: ?ResourceContents = None
}

// ---------------------------------------------------------------------------------------
// Prompt
@Json
public class PromptArgument <: BaseMessage {
    public var name: String = ""
    public var description: String = ""
    public var required: Bool = false
}

@Json
public class McpPrompt <: BaseMessage {
    public var name: String = ""
    public var description: String = ""
    public var arguments: ArrayList<PromptArgument> = ArrayList()
}

@Json
public class ListPromptResult <: BaseMessage {
    public var prompts: ArrayList<McpPrompt> = ArrayList()
}

@Json
public class GetPromptRequest <: BaseMessage {
    public var name: String = ""
    public var arguments: HashMap<String, String> = HashMap()
}

@Json
public class PromptMessage <: BaseMessage {
    public var role: Role = ""
    public var content: ?Content = None
}

@Json
public class GetPromptResult <: BaseMessage {
    public var description: String = ""
    public var messages: ArrayList<PromptMessage> = ArrayList()
}

// ---------------------------------------------------------------------------------------
// Const

public struct McpConsts {
    // protocol
    public static const LASTEST_PROTOCOL_VERSION = "2025-03-26"

    // role 
    public static const ROLE_USER = "user"
    public static const ROLE_ASSISTANT = "assistant"

    // methods
    public static const METHOD_INITIALIZE = "initialize"
    public static const METHOD_NOTIFICATION_INITIALIZED = "notifications/initialized"
    public static const METHOD_PING = "ping"
    public static const METHOD_TOOLS_LIST = "tools/list"
    public static const METHOD_TOOLS_CALL = "tools/call"
    public static const METHOD_NOTIFICATION_TOOLS_LIST_CHANGED = "notifications/tools/list_changed"
    public static const METHOD_RESOURCES_LIST = "resources/list"
    public static const METHOD_RESOURCES_TEMPLATES_LIST = "resources/templates/list"
    public static const METHOD_RESOURCES_READ = "resources/read"
    public static const METHOD_NOTIFICATION_RESOURCES_LIST_CHANGED = "notifications/resources/list_changed"
    public static const METHOD_PROMPTS_LIST = "prompts/list"
    public static const METHOD_PROMPTS_GET = "prompts/get"
    public static const METHOD_NOTIFICATION_PROMPTS_LIST_CHANGED = "notifications/prompts/list_changed"

    // event
    public static const EVENT_MESSAGE = "message"
    public static const EVENT_ENDPOINT = "endpoint"

    // header
    public static const HEADER_MCP_SESSION_ID = "mcp-session-id"
    public static const HEADER_LAST_EVENT_ID = "last-event-id"
}
