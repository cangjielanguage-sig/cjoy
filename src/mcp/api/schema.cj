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
 * 表示用于访问控制和权限的角色类型
 */
public type Role = String

/**
 * 支持游标的分页请求基类
 */
@Json
public class PaginatedRequest <: BaseMessage {
    /**
     * 分页游标，指示要获取的下一页
     */
    @JsonField[omitempty = true]
    public var cursor: ?String = None
}

/**
 * 支持下一页游标的分页结果基类
 */
@Json
public class PaginatedResult <: BaseMessage {
    /**
     * 用于获取附加页面的下一页游标，如果没有更多结果则为空
     */
    public var nextCursor: String = ""
}

/**
 * 表示 MCP 资源的注释，包含受众和优先级信息
 */
@Json
public class Annotations <: BaseMessage {
    /**
     * 有权访问此资源的角色列表
     */
    public var audience: ArrayList<Role> = ArrayList()

    /**
     * 资源的优先级（0.0 - 1.0，值越高表示优先级越高）
     */
    public var priority: Float32 = 0.0
}

/**
 * 表示客户端或服务器的实现信息
 */
@Json
public class Implementation <: BaseMessage {
    /**
     * 实现名称
     */
    public var name: String = ""

    /**
     * 实现版本
     */
    public var version: String = ""
}

/**
 * 表示 MCP 客户端支持的 capabilities
 */
@Json
public class ClientCapabilities <: BaseMessage {
    /**
     * 客户端支持的实验性 capabilities
     */
    public var experimental: HashMap<String, String> = HashMap()
}

/**
 * 表示 MCP 服务器支持的工具相关 capabilities
 */
@Json
public class ToolCapability <: BaseMessage {
    /**
     * 指示服务器是否支持工具列表变更通知
     */
    public var listChanged: Bool = false
}

/**
 * 表示 MCP 服务器支持的资源相关 capabilities
 */
@Json
public class ResourceCapability <: BaseMessage {
    /**
     * 指示服务器是否支持资源订阅
     */
    public var subscribe: Bool = false

    /**
     * 指示服务器是否支持资源列表变更通知
     */
    public var listChanged: Bool = false
}

/**
 * 表示 MCP 服务器支持的提示词相关 capabilities
 */
@Json
public class PromptsCapability <: BaseMessage {
    /**
     * 指示服务器是否支持提示词列表变更通知
     */
    public var listChanged: Bool = false
}

/**
 * 表示 MCP 服务器支持的所有 capabilities
 */
@Json
public class ServerCapabilities <: BaseMessage {
    /**
     * 服务器支持的工具 capabilities
     */
    public var tools: ?ToolCapability = None

    /**
     * 服务器支持的资源 capabilities
     */
    public var resources: ?ResourceCapability = None

    /**
     * 服务器支持的提示词 capabilities
     */
    public var prompts: ?PromptsCapability = None
}

/**
 * 初始化 MCP 会话的请求
 */
@Json
public class InitializeRequest <: BaseMessage {
    /**
     * 客户端请求的 MCP 协议版本
     */
    public var protocolVersion: String = McpConsts.LASTEST_PROTOCOL_VERSION

    /**
     * 客户端支持的 capabilities
     */
    public var capabilities: ?ClientCapabilities = None

    /**
     * 客户端实现的详细信息
     */
    public var clientInfo: ?Implementation = None
}

/**
 * MCP 会话初始化的结果
 */
@Json
public class InitializeResult <: BaseMessage {
    /**
     * 服务器支持的 MCP 协议版本
     */
    public var protocolVersion: String = McpConsts.LASTEST_PROTOCOL_VERSION

    /**
     * 服务器支持的 capabilities
     */
    public var capabilities: ?ServerCapabilities = None

    /**
     * 服务器实现的详细信息
     */
    public var serverInfo: ?Implementation = None

    /**
     * 使用服务器的说明或指南
     */
    public var instructions: ?String = None
}

/**
 * MCP 工具的注释，包含额外信息和提示
 */
@Json
public class ToolAnnotations <: BaseMessage {
    /**
     * 工具的显示标题
     */
    public var title: String = ""

    /**
     * 指示工具是否应被视为只读（无副作用）
     */
    public var readOnlyHint: Bool = false

    /**
     * 指示工具是否可能导致破坏性操作
     */
    public var destructiveHint: Bool = false

    /**
     * 指示工具是否是幂等的（多次调用产生相同结果）
     */
    public var idempotentHint: Bool = false

    /**
     * 指示工具是否与开放世界（外部系统）交互
     */
    public var openWorldHint: Bool = true
}

/**
 * MCP 工具，包含元数据和模式信息
 */
@Json
public class McpTool <: BaseMessage {
    /**
     * 工具的唯一名称
     */
    public var name: String = ""

    /**
     * 工具功能的人类可读描述
     */
    public var description: String = ""

    /**
     * 用于验证工具输入参数的 JSON 模式
     */
    public var inputSchema: Any = Option<Any>.None

    /**
     * 工具的额外注释和提示
     */
    public var annotations: ?ToolAnnotations = None
}

/**
 * 列出可用 MCP 工具的结果，支持分页
 */
@Json
public class ListToolsResult <: BaseMessage {
    /**
     * 获取额外工具的下一页游标，如果没有更多工具则为空
     */
    public var nextCursor: ?String = None

    /**
     * 可用工具列表
     */
    public var tools: ArrayList<McpTool> = ArrayList()
}

/**
 * 使用特定参数调用 MCP 工具的请求
 */
@Json
public class CallToolRequest <: BaseMessage {
    /**
     * 要调用的工具名称
     */
    public var name: String = ""

    /**
     * 传递给工具的参数（JSON 序列化）
     */
    @JsonField[omitempty = true, raw = true]
    public var arguments: Any = Option<Any>.None
}

/**
 * MCP 中所有内容类型的基类（文本、图像、音频、资源）
 */
@Json[subTypeField = "type", subTypes = { "text": "TextContent", "image": "ImageContent", "audio": "AudioContent", "resource": "EmbeddedResource" }]
public open class Content <: BaseMessage {
    /**
     * 内容类型（文本、图像、音频或资源）
     */
    @JsonField[name = "type"]
    public var type_: String = ""
}

/**
 * 表示工具结果和提示的文本内容
 */
@Json[superClass = Content]
public class TextContent <: Content {
    /**
     * 文本内容
     */
    public var text: String = ""
}

/**
 * 表示使用 base64 编码数据的图像内容
 */
@Json[superClass = Content]
public class ImageContent <: Content {
    /**
     * Base64 编码的图像数据
     */
    public var data: String = ""

    /**
     * 图像的 MIME 类型（例如：image/png, image/jpeg）
     */
    public var mimeType: String = ""
}

/**
 * 表示使用 base64 编码数据的音频内容
 */
@Json[superClass = Content]
public class AudioContent <: Content {
    /**
     * Base64 编码的音频数据
     */
    public var data: String = ""

    /**
     * 音频的 MIME 类型（例如：audio/mp3, audio/wav）
     */
    public var mimeType: String = ""
}

/**
 * 调用 MCP 工具的结果
 */
@Json
public class CallToolResult <: BaseMessage {
    /**
     * 指示工具执行期间是否发生错误
     */
    public var isError: Bool = false

    /**
     * 工具返回的内容（可以包含文本、图像、音频或资源）
     */
    public var content: ArrayList<Content> = ArrayList()
}

/**
 * MCP 资源，包含元数据和访问信息
 */
@Json
public class McpResource <: BaseMessage {
    /**
     * 资源的唯一 URI
     */
    public var uri: String = ""

    /**
     * 资源的人类可读名称
     */
    public var name: String = ""

    /**
     * 资源描述
     */
    public var description: ?String = None

    /**
     * 资源内容的 MIME 类型
     */
    public var mimeType: ?String = None

    /**
     * 资源大小（字节）
     */
    public var size: ?Int = None

    /**
     * 资源的注释，包含受众和优先级信息
     */
    public var annotations: ?Annotations = None
}

/**
 * 使用参数创建资源 URI 的模板
 */
@Json
public class ResourceTemplate <: BaseMessage {
    /**
     * 带占位符的 URI 模板（例如：/resource/{id}）
     */
    public var uriTemplate: String = ""

    /**
     * 资源模板的人类可读名称
     */
    public var name: String = ""

    /**
     * 资源模板描述
     */
    public var description: ?String = None

    /**
     * 资源内容的 MIME 类型
     */
    public var mimeType: ?String = None

    /**
     * 资源模板的注释
     */
    public var annotations: ?Annotations = None
}

/**
 * 列出可用 MCP 资源的结果，支持分页
 */
@Json
public class ListResourcesResult <: BaseMessage {
    /**
     * 获取额外资源的下一页游标，如果没有更多资源则为空
     */
    public var nextCursor: ?String = None

    /**
     * 可用资源列表
     */
    public var resources: ArrayList<McpResource> = ArrayList()
}

/**
 * 列出可用资源模板的结果，支持分页
 */
@Json
public class ListResourceTemplatesResult <: BaseMessage {
    /**
     * 获取额外模板的下一页游标，如果没有更多模板则为空
     */
    public var nextCursor: ?String = None

    /**
     * 可用资源模板列表
     */
    public var resourceTemplates: ArrayList<ResourceTemplate> = ArrayList()
}

/**
 * 从 MCP 资源读取内容的请求
 */
@Json
public class ReadResourceRequest <: BaseMessage {
    /**
     * 要读取的资源的 URI
     */
    public var uri: String = ""
}

/**
 * 资源内容类型的基类（文本或二进制）
 */
@Json[subTypeAs = true, subTypes = { "text": "TextResourceContents", "blob": "BlobResourceContents" }]
public open class ResourceContents <: BaseMessage {
    /**
     * 资源的 URI
     */
    public var uri: String = ""

    /**
     * 资源内容的 MIME 类型
     */
    public var mimeType: String = ""
}

/**
 * 资源的文本内容
 */
@Json[superClass = ResourceContents]
public class TextResourceContents <: ResourceContents {
    /**
     * 资源的文本内容
     */
    public var text: String = ""
}

/**
 * 资源的二进制内容（base64 编码）
 */
@Json[superClass = ResourceContents]
public class BlobResourceContents <: ResourceContents {
    /**
     * 资源的 base64 编码二进制内容
     */
    public var blob: String = ""
}

/**
 * 读取 MCP 资源的结果
 */
@Json
public class ReadResourceResult <: BaseMessage {
    /**
     * 资源的内容（可以是文本或二进制）
     */
    public var contents: ArrayList<ResourceContents> = ArrayList()
}

/**
 * 内容中的嵌入式资源
 */
@Json[superClass = Content]
public class EmbeddedResource <: Content {
    /**
     * 嵌入式资源内容
     */
    public var resource: ?ResourceContents = None
}

/**
 * MCP 提示的单个参数
 */
@Json
public class PromptArgument <: BaseMessage {
    /**
     * 参数名称
     */
    public var name: String = ""

    /**
     * 参数用途的描述
     */
    public var description: String = ""

    /**
     * 指示此参数是否为必需
     */
    public var required: Bool = false
}

/**
 * MCP 提示词，包含元数据和参数
 */
@Json
public class McpPrompt <: BaseMessage {
    /**
     * 提示词的唯一名称
     */
    public var name: String = ""

    /**
     * 提示词用途的人类可读描述
     */
    public var description: String = ""

    /**
     * 此提示词接受的参数列表
     */
    public var arguments: ArrayList<PromptArgument> = ArrayList()
}

/**
 * 列出可用 MCP 提示词的结果
 */
@Json
public class ListPromptResult <: BaseMessage {
    /**
     * 获取额外提示词的下一页游标，如果没有更多提示词则为空
     */
    public var nextCursor: ?String = None

    /**
     * 可用提示词列表
     */
    public var prompts: ArrayList<McpPrompt> = ArrayList()
}

/**
 * 使用特定参数获取 MCP 提示词的请求
 */
@Json
public class GetPromptRequest <: BaseMessage {
    /**
     * 要获取的提示词名称
     */
    public var name: String = ""

    /**
     * 传递给提示词的参数
     */
    public var arguments: HashMap<String, String> = HashMap()
}

/**
 * 提示词对话中的单个消息
 */
@Json
public class PromptMessage <: BaseMessage {
    /**
     * 消息发送者的角色（例如：user, assistant）
     */
    public var role: Role = ""

    /**
     * 消息内容（可以包含文本、图像、音频或资源）
     */
    public var content: ?Content = None
}

/**
 * 获取渲染内容的 MCP 提示词结果
 */
@Json
public class GetPromptResult <: BaseMessage {
    /**
     * 提示词描述
     */
    public var description: String = ""

    /**
     * 组成提示词的消息列表
     */
    public var messages: ArrayList<PromptMessage> = ArrayList()
}

// ---------------------------------------------------------------------------------------
// Const

public struct McpConsts {
    // protocol versions
    public static const PROTOCOL_VERSION_20250326 = "2025-03-26"
    public static const PROTOCOL_VERSION_20250618 = "2025-06-18"
    public static const PROTOCOL_VERSION_20251125 = "2025-11-25"
    public static const LASTEST_PROTOCOL_VERSION = PROTOCOL_VERSION_20251125

    // supported protocol versions
    public static func supportedProtocolVersions(): Array<String> {
        [
            PROTOCOL_VERSION_20250326,
            PROTOCOL_VERSION_20250618,
            PROTOCOL_VERSION_20251125
        ]
    }

    // role
    public static const ROLE_USER = "user"
    public static const ROLE_ASSISTANT = "assistant"

    // headers
    public static const HEADER_PROTOCOL_VERSION = "Mcp-Protocol-Version"

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