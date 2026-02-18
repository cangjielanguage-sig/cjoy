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
 * MCP 会话的基础接口
 */
public interface McpSession <: Resource {
    /**
     * 发送 JSON-RPC 请求并等待响应
     *
     * @param method 方法名称
     * @param requestParams 请求参数
     * @return 类型 T 的响应
     */
    func sendRequest<T>(method: String, requestParams: JsonSerializable): T where T <: JsonDeserializable<T>

    /**
     * 发送 JSON-RPC 通知而不等待响应
     *
     * @param method 通知方法名称
     * @param params 通知参数
     */
    func sendNotification(method: String, params: ?JsonSerializable): Unit
    func sendNotification(method: String) {
        sendNotification(method, None)
    }

    /**
     * 为通知方法添加消费者
     *
     * @param method 通知方法名称
     * @param consumer 处理通知字节的消费者函数
     */
    func addNotificationConsumer(method: String, consumer: (Array<Byte>) -> Unit): Unit
}

/**
 * 用于处理传入请求的 MCP 服务器会话接口
 */
public interface McpServerSession <: McpSession {
    /**
     * 会话标识符，用于唯一标识 MCP 会话
     *
     * 会话 ID 在会话创建时生成，用于跟踪和管理整个会话期间的通信
     * 它通常通过请求头或查询参数传递，以将不同的请求与同一个会话关联
     */
    prop sessionId: String

    /**
     * 处理传入的 JSON-RPC 消息
     *
     * @param ctx 上下文
     * @param message JSON-RPC 消息
     */
    func handle(ctx: JoyContext, message: JSONRPCMessage): Unit
}

/**
 * 用于连接 MCP 服务器的 MCP 客户端会话接口
 */
public interface McpClientSession <: McpSession {
    /**
     * 连接到 MCP 服务器
     */
    func connect(): Unit
}

/**
 * MCP 通知处理器接口
 */
public interface McpNotificationHandler {
    /**
     * 处理通知消息
     *
     * @param message 通知消息
     */
    func onNotification(message: JSONRPCNotification): Unit
}

/**
 * MCP 响应处理器接口
 */
public interface McpResponseHandler {
    /**
     * 处理响应消息
     *
     * @param message 响应消息
     */
    func onResponse(message: JSONRPCResponse): Unit
}

/**
 * MCP 请求处理器接口
 */
public interface McpRequestHandler {
    /**
     * 处理请求消息
     *
     * @param ctx 上下文
     * @param message 请求消息
     */
    func onRequest(ctx: JoyContext, message: JSONRPCRequest): Unit
}

/**
 * MCP 工具调用处理器接口
 */
public interface McpCallToolHandler {
    /**
     * 使用参数处理工具调用
     *
     * @param ctx 上下文
     * @param arguments 工具参数字节
     * @return 工具调用结果
     */
    func handle(ctx: JoyContext, arguments: Array<Byte>): Any
}

/**
 * MCP 资源读取处理器接口
 */
public interface McpReadResourceHandler {
    /**
     * 读取资源内容
     *
     * @param ctx 上下文
     * @return 资源内容
     */
    func readResource(ctx: JoyContext): Any
}

/**
 * MCP 提示获取处理器接口
 */
public interface McpGetPromptHandler {
    /**
     * 使用参数获取提示内容
     *
     * @param ctx 上下文
     * @param arguments 提示参数
     * @return 提示内容
     */
    func getPrompt(ctx: JoyContext, arguments: HashMap<String, String>): Any
}

/**
 * MCP 传输接口，用于消息通信
 */
public interface McpTransport <: Resource {
    /**
     * 通过传输发送消息
     *
     * @param message 要发送的消息字节
     */
    func send(message: ByteBuffer): Unit
}

/**
 * 支持连接的 MCP 客户端传输接口
 */
public interface McpClientTransport <: McpTransport {
    /**
     * 使用消息消费者连接到传输
     *
     * @param consumer 处理传入消息的消费者函数
     */
    func connect(consumer: (ByteBuffer) -> Unit): Unit

    /**
     * 设置重新连接时的回调
     *
     * @param callback 回调函数
     */
    func whenReConnect(callback: () -> Unit): Unit
}

/**
 * MCP 事件存储接口，用于持久化和重放事件
 *
 * 提供可插拔接口，用于存储和检索事件以实现流恢复。
 * 实现可以包括内存、文件或数据库支持的存储。
 */
public interface EventStore {
    /**
     * 为特定会话和流 ID 打开事件流
     *
     * @param sessionId 唯一会话标识符
     * @param streamId 唯一流标识符
     * @throws Exception 如果无法打开流
     */
    func open(sessionId: String, streamId: String): Unit

    /**
     * 向流追加事件
     *
     * @param sessionId 唯一会话标识符
     * @param streamId 唯一流标识符
     * @param data 要追加的事件数据
     * @throws Exception 如果无法追加事件
     */
    func append(sessionId: String, streamId: String, data: ByteBuffer): Unit

    /**
     * 检索特定索引后的所有事件
     *
     * @param sessionId 唯一会话标识符
     * @param streamId 唯一流标识符
     * @param lastIndex 开始索引（不包含）
     * @return 包含事件索引和数据的迭代器
     * @throws Exception 如果无法检索事件
     */
    func after(sessionId: String, streamId: String, lastIndex: Int64): Iterator<(Int64, ByteBuffer)>

    /**
     * 获取特定会话和流存储的事件数量
     *
     * @param sessionId 唯一会话标识符
     * @param streamId 唯一流标识符
     * @return 存储的事件数量
     */
    func getEventCount(sessionId: String, streamId: String): Int64

    /**
     * 会话关闭时调用，用于清理资源
     *
     * @param sessionId 唯一会话标识符
     * @throws Exception 如果清理失败
     */
    func sessionClosed(sessionId: String): Unit
}

/**
 * MCP 服务器传输接口
 */
public interface McpServerTransport <: McpTransport {}

/**
 * 用于与 MCP 服务器通信的 MCP 客户端接口
 */
public interface McpClient <: Resource {
    /**
     * 返回服务器能力
     */
    prop serverCapabilities: ?ServerCapabilities

    /**
     * 返回服务器信息
     */
    prop serverInfo: ?Implementation

    /**
     * 发送 ping 请求
     */
    func ping(): Unit

    /**
     * 初始化与服务器的连接
     *
     * @return 初始化结果
     */
    func initialize(): InitializeResult

    /**
     * 列出可用工具
     *
     * @param cursor 分页游标
     * @return 工具列表结果
     */
    func listTools(cursor: ?String): ListToolsResult
    func listTools(): ListToolsResult {
        listTools(None)
    }

    /**
     * 调用工具
     *
     * @param request 工具调用请求
     * @return 工具调用结果
     */
    func callTool(request: CallToolRequest): CallToolResult

    /**
     * 列出可用资源
     *
     * @param cursor 分页游标
     * @return 资源列表结果
     */
    func listResources(cursor: ?String): ListResourcesResult
    func listResources(): ListResourcesResult {
        listResources(None)
    }

    /**
     * 列出资源模板
     *
     * @param cursor 分页游标
     * @return 资源模板列表结果
     */
    func listResourceTemplates(cursor: ?String): ListResourceTemplatesResult
    func listResourceTemplates(): ListResourceTemplatesResult {
        listResourceTemplates(None)
    }

    /**
     * 读取资源内容
     *
     * @param request 读取资源请求
     * @return 读取资源结果
     */
    func readResource(request: ReadResourceRequest): ReadResourceResult

    /**
     * 列出可用提示
     *
     * @param cursor 分页游标
     * @return 提示列表结果
     */
    func listPrompts(cursor: ?String): ListPromptResult
    func listPrompts(): ListPromptResult {
        listPrompts(None)
    }

    /**
     * 获取提示内容
     *
     * @param request 获取提示请求
     * @return 获取提示结果
     */
    func getPrompt(request: GetPromptRequest): GetPromptResult
}

/**
 * 表示 MCP 的图像内容类型
 *
 * 该类提供了从文件或原始数据加载图像的功能，
 * 并将其转换为 ImageContent 格式，以便在 MCP 响应中使用。
 */
public class Image {
    /**
     * 初始化新的 Image 实例
     *
     * @param path 图像文件路径（默认：空字符串）
     * @param data 原始图像数据（默认：空数组）
     * @param format 图像格式（例如，"png", "jpeg"）（默认：空字符串）
     */
    public Image(public let path!: String = "", public var data!: Array<Byte> = [], public let format!: String = "") {}

    /**
     * 将 Image 转换为 MCP 响应的 ImageContent 格式
     *
     * @return 包含图像数据的 ImageContent 实例
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
 * 表示 MCP 的音频内容类型
 *
 * 该类提供了从文件或原始数据加载音频的功能，
 * 并将其转换为 AudioContent 格式，以便在 MCP 响应中使用。
 */
public class Audio {
    /**
     * 初始化新的 Audio 实例
     *
     * @param path 音频文件路径（默认：空字符串）
     * @param data 原始音频数据（默认：空数组）
     * @param format 音频格式（例如，"mp3", "wav"）（默认：空字符串）
     */
    public Audio(public let path!: String = "", public var data!: Array<Byte> = [], public let format!: String = "") {}

    /**
     * 将 Audio 转换为 MCP 响应的 AudioContent 格式
     *
     * @return 包含音频数据的 AudioContent 实例
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
 * 表示 MCP 提示的消息类型
 *
 * 该类提供了创建具有特定角色（例如，用户、助手）的提示消息的功能，
 * 以便在 MCP 响应中使用。
 */
public class Message {
    /**
     * 初始化新的 Message 实例
     *
     * @param content 消息内容（默认：空字符串）
     * @param role 消息发送者角色（例如，"user", "assistant"）（默认："assistant"）
     */
    public Message(public let content!: String = "", public let role!: String = "assistant") {}

    /**
     * 将 Message 转换为 MCP 响应的 PromptMessage 格式
     *
     * @return 包含消息的 PromptMessage 实例
     */
    public func toPromptMessage(): PromptMessage {
        var res = TextContent(text: content)
        res.type_ = "text"
        PromptMessage(role: role, content: res)
    }
}