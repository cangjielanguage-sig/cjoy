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

import std.collection.{HashMap, ArrayList}
import cjoy.jsonrpc.*
import cjoy.json.*
import cjoy.json.macros.*

/**
 * Represents a role type used for access control and permissions
 */
public type Role = String

/**
 * Base class for paginated requests with cursor support
 */
@Json
public class PaginatedRequest <: BaseMessage {
    /**
     * Cursor for pagination, indicating the next page to fetch
     */
    @JsonField[omitempty = true]
    public var cursor: ?String = None
}

/**
 * Base class for paginated results with next cursor support
 */
@Json
public class PaginatedResult <: BaseMessage {
    /**
     * Next cursor for fetching additional pages, empty if no more results
     */
    public var nextCursor: String = ""
}

/**
 * Represents annotations for MCP resources with audience and priority information
 */
@Json
public class Annotations <: BaseMessage {
    /**
     * List of roles that have access to this resource
     */
    public var audience: ArrayList<Role> = ArrayList()

    /**
     * Priority level of the resource (0.0 - 1.0, higher indicates higher priority)
     */
    public var priority: Float32 = 0.0
}

/**
 * Represents implementation information about a client or server
 */
@Json
public class Implementation <: BaseMessage {
    /**
     * Name of the implementation
     */
    public var name: String = ""

    /**
     * Version of the implementation
     */
    public var version: String = ""
}

/**
 * Represents capabilities supported by an MCP client
 */
@Json
public class ClientCapabilities <: BaseMessage {
    /**
     * Experimental capabilities supported by the client
     */
    public var experimental: HashMap<String, String> = HashMap()
}

/**
 * Represents tool-related capabilities supported by an MCP server
 */
@Json
public class ToolCapability <: BaseMessage {
    /**
     * Indicates whether the server supports tool list change notifications
     */
    public var listChanged: Bool = false
}

/**
 * Represents resource-related capabilities supported by an MCP server
 */
@Json
public class ResourceCapability <: BaseMessage {
    /**
     * Indicates whether the server supports resource subscription
     */
    public var subscribe: Bool = false

    /**
     * Indicates whether the server supports resource list change notifications
     */
    public var listChanged: Bool = false
}

/**
 * Represents prompt-related capabilities supported by an MCP server
 */
@Json
public class PromptsCapability <: BaseMessage {
    /**
     * Indicates whether the server supports prompt list change notifications
     */
    public var listChanged: Bool = false
}

/**
 * Represents all capabilities supported by an MCP server
 */
@Json
public class ServerCapabilities <: BaseMessage {
    /**
     * Tool capabilities supported by the server
     */
    public var tools: ?ToolCapability = None

    /**
     * Resource capabilities supported by the server
     */
    public var resources: ?ResourceCapability = None

    /**
     * Prompt capabilities supported by the server
     */
    public var prompts: ?PromptsCapability = None
}

/**
 * Request for initializing an MCP session
 */
@Json
public class InitializeRequest <: BaseMessage {
    /**
     * MCP protocol version requested by the client
     */
    public var protocolVersion: String = McpConsts.LASTEST_PROTOCOL_VERSION

    /**
     * Capabilities supported by the client
     */
    public var capabilities: ?ClientCapabilities = None

    /**
     * Information about the client implementation
     */
    public var clientInfo: ?Implementation = None
}

/**
 * Result of the MCP session initialization
 */
@Json
public class InitializeResult <: BaseMessage {
    /**
     * MCP protocol version supported by the server
     */
    public var protocolVersion: String = McpConsts.LASTEST_PROTOCOL_VERSION

    /**
     * Capabilities supported by the server
     */
    public var capabilities: ?ServerCapabilities = None

    /**
     * Information about the server implementation
     */
    public var serverInfo: ?Implementation = None

    /**
     * Instructions or guidelines for using the server
     */
    public var instructions: ?String = None
}

/**
 * Represents annotations for MCP tools with additional information and hints
 */
@Json
public class ToolAnnotations <: BaseMessage {
    /**
     * Display title of the tool
     */
    public var title: String = ""

    /**
     * Indicates if the tool should be treated as read-only (no side effects)
     */
    public var readOnlyHint: Bool = false

    /**
     * Indicates if the tool can cause destructive operations
     */
    public var destructiveHint: Bool = false

    /**
     * Indicates if the tool is idempotent (multiple calls produce same result)
     */
    public var idempotentHint: Bool = false

    /**
     * Indicates if the tool interacts with the open world (external systems)
     */
    public var opneWorldHint: Bool = true
}

/**
 * Represents an MCP tool with metadata and schema information
 */
@Json
public class McpTool <: BaseMessage {
    /**
     * Unique name of the tool
     */
    public var name: String = ""

    /**
     * Human-readable description of what the tool does
     */
    public var description: String = ""

    /**
     * JSON schema for validating tool input arguments
     */
    public var inputSchema: Any = Option<Any>.None

    /**
     * Additional annotations and hints for the tool
     */
    public var annotations: ?ToolAnnotations = None
}

/**
 * Result of listing available MCP tools with pagination support
 */
@Json
public class ListToolsResult <: BaseMessage {
    /**
     * Next cursor for fetching additional tools, empty if no more tools
     */
    public var nextCursor: ?String = None

    /**
     * List of available tools
     */
    public var tools: ArrayList<McpTool> = ArrayList()
}

/**
 * Request for calling an MCP tool with specific arguments
 */
@Json
public class CallToolRequest <: BaseMessage {
    /**
     * Name of the tool to call
     */
    public var name: String = ""

    /**
     * Arguments to pass to the tool (JSON serialized)
     */
    @JsonField[omitempty = true, raw = true]
    public var arguments: Any = Option<Any>.None
}

/**
 * Base class for all content types in MCP (text, image, audio, resource)
 */
@Json[subTypeField = "type", subTypes = { "text": "TextContent", "image": "ImageContent", "audio": "AudioContent", "resource": "EmbeddedResource" }]
public open class Content <: BaseMessage {
    /**
     * Type of content (text, image, audio, or resource)
     */
    @JsonField[name = "type"]
    public var type_: String = ""
}

/**
 * Represents text content for tool results and prompts
 */
@Json[superClass = Content]
public class TextContent <: Content {
    /**
     * Text content
     */
    public var text: String = ""
}

/**
 * Represents image content with base64 encoded data
 */
@Json[superClass = Content]
public class ImageContent <: Content {
    /**
     * Base64 encoded image data
     */
    public var data: String = ""

    /**
     * MIME type of the image (e.g., image/png, image/jpeg)
     */
    public var mimeType: String = ""
}

/**
 * Represents audio content with base64 encoded data
 */
@Json[superClass = Content]
public class AudioContent <: Content {
    /**
     * Base64 encoded audio data
     */
    public var data: String = ""

    /**
     * MIME type of the audio (e.g., audio/mp3, audio/wav)
     */
    public var mimeType: String = ""
}

/**
 * Result of calling an MCP tool
 */
@Json
public class CallToolResult <: BaseMessage {
    /**
     * Indicates if an error occurred during tool execution
     */
    public var isError: Bool = false

    /**
     * Content returned by the tool (can include text, images, audio, or resources)
     */
    public var content: ArrayList<Content> = ArrayList()
}

/**
 * Represents an MCP resource with metadata and access information
 */
@Json
public class McpResource <: BaseMessage {
    /**
     * Unique URI of the resource
     */
    public var uri: String = ""

    /**
     * Human-readable name of the resource
     */
    public var name: String = ""

    /**
     * Description of the resource
     */
    public var description: ?String = None

    /**
     * MIME type of the resource content
     */
    public var mimeType: ?String = None

    /**
     * Size of the resource in bytes
     */
    public var size: ?Int = None

    /**
     * Annotations for the resource with audience and priority information
     */
    public var annotations: ?Annotations = None
}

/**
 * Represents a template for creating resource URIs with parameters
 */
@Json
public class ResourceTemplate <: BaseMessage {
    /**
     * URI template with placeholders (e.g., /resource/{id})
     */
    public var uriTemplate: String = ""

    /**
     * Human-readable name of the resource template
     */
    public var name: String = ""

    /**
     * Description of the resource template
     */
    public var description: ?String = None

    /**
     * MIME type of the resource content
     */
    public var mimeType: ?String = None

    /**
     * Annotations for the resource template
     */
    public var annotations: ?Annotations = None
}

/**
 * Result of listing available MCP resources with pagination support
 */
@Json
public class ListResourcesResult <: BaseMessage {
    /**
     * Next cursor for fetching additional resources, empty if no more resources
     */
    public var nextCursor: ?String = None

    /**
     * List of available resources
     */
    public var resources: ArrayList<McpResource> = ArrayList()
}

/**
 * Result of listing available resource templates with pagination support
 */
@Json
public class ListResourceTemplatesResult <: BaseMessage {
    /**
     * Next cursor for fetching additional templates, empty if no more templates
     */
    public var nextCursor: ?String = None

    /**
     * List of available resource templates
     */
    public var resourceTemplates: ArrayList<ResourceTemplate> = ArrayList()
}

/**
 * Request for reading content from an MCP resource
 */
@Json
public class ReadResourceRequest <: BaseMessage {
    /**
     * URI of the resource to read
     */
    public var uri: String = ""
}

/**
 * Base class for resource content types (text or blob)
 */
@Json[subTypeAs = true, subTypes = { "text": "TextResourceContents", "blob": "BlobResourceContents" }]
public open class ResourceContents <: BaseMessage {
    /**
     * URI of the resource
     */
    public var uri: String = ""

    /**
     * MIME type of the resource content
     */
    public var mimeType: String = ""
}

/**
 * Represents text content of a resource
 */
@Json[superClass = ResourceContents]
public class TextResourceContents <: ResourceContents {
    /**
     * Text content of the resource
     */
    public var text: String = ""
}

/**
 * Represents binary content of a resource (base64 encoded)
 */
@Json[superClass = ResourceContents]
public class BlobResourceContents <: ResourceContents {
    /**
     * Base64 encoded binary content of the resource
     */
    public var blob: String = ""
}

/**
 * Result of reading an MCP resource
 */
@Json
public class ReadResourceResult <: BaseMessage {
    /**
     * Content of the resource (can be text or binary)
     */
    public var contents: ArrayList<ResourceContents> = ArrayList()
}

/**
 * Represents an embedded resource within content
 */
@Json[superClass = Content]
public class EmbeddedResource <: Content {
    /**
     * The embedded resource content
     */
    public var resource: ?ResourceContents = None
}

/**
 * Represents a single argument for an MCP prompt
 */
@Json
public class PromptArgument <: BaseMessage {
    /**
     * Name of the argument
     */
    public var name: String = ""

    /**
     * Description of what the argument is used for
     */
    public var description: String = ""

    /**
     * Indicates if this argument is required
     */
    public var required: Bool = false
}

/**
 * Represents an MCP prompt with metadata and arguments
 */
@Json
public class McpPrompt <: BaseMessage {
    /**
     * Unique name of the prompt
     */
    public var name: String = ""

    /**
     * Human-readable description of what the prompt is used for
     */
    public var description: String = ""

    /**
     * List of arguments accepted by this prompt
     */
    public var arguments: ArrayList<PromptArgument> = ArrayList()
}

/**
 * Result of listing available MCP prompts
 */
@Json
public class ListPromptResult <: BaseMessage {
    /**
     * Next cursor for fetching additional prompts, empty if no more prompts
     */
    public var nextCursor: ?String = None

    /**
     * List of available prompts
     */
    public var prompts: ArrayList<McpPrompt> = ArrayList()
}

/**
 * Request for getting an MCP prompt with specific arguments
 */
@Json
public class GetPromptRequest <: BaseMessage {
    /**
     * Name of the prompt to get
     */
    public var name: String = ""

    /**
     * Arguments to pass to the prompt
     */
    public var arguments: HashMap<String, String> = HashMap()
}

/**
 * Represents a single message in a prompt conversation
 */
@Json
public class PromptMessage <: BaseMessage {
    /**
     * Role of the message sender (e.g., user, assistant)
     */
    public var role: Role = ""

    /**
     * Content of the message (can include text, images, audio, or resources)
     */
    public var content: ?Content = None
}

/**
 * Result of getting an MCP prompt with rendered content
 */
@Json
public class GetPromptResult <: BaseMessage {
    /**
     * Description of the prompt
     */
    public var description: String = ""

    /**
     * List of messages that make up the prompt
     */
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