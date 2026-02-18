/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.mcp.server

import cjoy.mcp.api.*
import cjoy.framework.Joy
import cjoy.version.VERSION
import cjoy.log.macros.*

@JoyCreateLogger("cjoy.mcp.server")

/**
 * 表示 MCP 服务器的可配置功能
 *
 * 此类包含在 MCP 初始化阶段协商的所有服务器特定配置和功能。
 */
public class McpServerFeatures {
    /**
     * 服务器支持的 MCP 协议版本
     */
    public var protocolVersion: String = McpConsts.LASTEST_PROTOCOL_VERSION

    /**
     * 服务器实现信息
     */
    public var serverInfo: Implementation = Implementation(name: "cjoy", version: VERSION)

    /**
     * 服务器支持的功能（工具、资源、提示）
     */
    var capabilities: ServerCapabilities = ServerCapabilities()

    /**
     * 使用服务器的说明或指南
     */
    public var instructions: ?String = None

    /**
     * MCP 会话的保活间隔（毫秒）
     *
     * 如果设为正值，服务器将在指定间隔发送 ping 消息以保持连接活跃。
     * 如果设为 0 或负值，则禁用保活。
     */
    public var keepaliveIntervalMs: Int64 = 0

    /**
     * MCP 会话的保活超时（毫秒）
     *
     * 如果在此时间内未收到 ping 响应，会话将关闭。
     * 默认为保活间隔的一半。
     */
    public var keepaliveTimeoutMs: Int64 = 0
}

/**
 * MCP 服务器功能的主入口点
 *
 * 提供用于向 CJoy 框架注册 MCP 服务器和管理服务器级资源、工具和提示的静态方法。
 */
public class McpServer {
    /**
     * 用于管理 MCP 工具的静态实例
     */
    public static let TOOLS: McpTools = McpTools()

    /**
     * 用于管理 MCP 资源的静态实例
     */
    public static let RESOURCES: McpResources = McpResources()

    /**
     * 用于管理 MCP 提示的静态实例
     */
    public static let PROMPTS: McpPrompts = McpPrompts()

    private static var serverFeatures: ?McpServerFeatures = None
    private static var dump = false

    /**
     * 处理与 MCP 客户端的初始化交换
     *
     * @return 包含服务器功能信息的 InitializeResult
     * @throws Exception 如果服务器功能未正确配置
     */
    public static func exchangeInit(): InitializeResult {
        let features = McpServer.serverFeatures.getOrThrow()
        InitializeResult(protocolVersion: features.protocolVersion, capabilities: features.capabilities,
            serverInfo: features.serverInfo, instructions: features.instructions)
    }

    /**
     * 使用 SSE（Server-Sent Events）传输将 MCP 服务器注册到 CJoy 框架
     *
     * @param joy 要注册的 CJoy 实例
     * @param ssePath SSE 连接的路径（默认为 "/sse"）
     * @param messagePath 消息交换的路径（默认为 "/messages"）
     * @param serverFeatures 服务器功能配置（默认为 McpServerFeatures()）
     * @param disableLocalhostProtection 是否禁用 localhost 的 DNS 重绑定保护（默认为 false）
     */
    public static func registerSseTo(joy: Joy, ssePath!: String = "/sse", messagePath!: String = "/messages",
        serverFeatures!: McpServerFeatures = McpServerFeatures(), disableLocalhostProtection!: Bool = false): Unit {
        updateFeatures(serverFeatures)

        let transport = McpSseServerTransport(messagePath, disableLocalhostProtection: disableLocalhostProtection)
        // sse
        let rg1 = joy.router.findGroup(ssePath)
        let rpath1 = ssePath[rg1.basePath().size..]
        rg1.get(rpath1, transport.handleSseRequest)

        // messages
        let rg2 = joy.router.findGroup(messagePath)
        let rpath2 = messagePath[rg2.basePath().size..]
        rg2.post(rpath2, transport.handlePostRequest)

        dumpResources()
    }

    /**
     * 使用可流式传输将 MCP 服务器注册到 CJoy 框架
     *
     * @param joy 要注册的 CJoy 实例
     * @param path 可流式传输的路径（默认为 "/mcp"）
     * @param isJsonResp 是否直接返回 JSON 响应而不是 SSE 流（默认为 false）
     * @param eventStore 用于持久化事件的可选事件存储（默认为 None）
     * @param serverFeatures 服务器功能配置（默认为 McpServerFeatures()）
     * @param disableLocalhostProtection 是否禁用 localhost 的 DNS 重绑定保护（默认为 false）
     */
    public static func registerStreamableTo(joy: Joy, path!: String = "/mcp", isJsonResp!: Bool = false,
        eventStore!: ?EventStore = None, serverFeatures!: McpServerFeatures = McpServerFeatures(),
        disableLocalhostProtection!: Bool = false): Unit {
        updateFeatures(serverFeatures)
        let transport = McpStreamableServerTransport(isJsonResp, eventStore: eventStore,
            disableLocalhostProtection: disableLocalhostProtection)

        let rg = joy.router.findGroup(path)
        let rpath = path[rg.basePath().size..]
        rg.get(rpath, transport.handleGetRequest)
        rg.post(rpath, transport.handlePostRequest)
        rg.delete(rpath, transport.handleDelRequest)

        dumpResources()
    }

    /**
     * 根据已注册的工具、资源和提示更新服务器功能
     *
     * @param serverFeatures 要更新的服务器功能配置
     */
    private static func updateFeatures(serverFeatures: McpServerFeatures) {
        McpServer.serverFeatures = serverFeatures
        if (!TOOLS.tools.isEmpty()) {
            serverFeatures.capabilities.tools = ToolCapability()
        }
        if (!RESOURCES.resources.isEmpty() || !RESOURCES.resourceTempls.isEmpty()) {
            serverFeatures.capabilities.resources = ResourceCapability()
        }
        if (!PROMPTS.prompts.isEmpty()) {
            serverFeatures.capabilities.prompts = PromptsCapability()
        }
    }

    /**
     * 转储已注册的资源，用于调试目的
     */
    private static func dumpResources(): Unit {
        if (!dump) {
            RESOURCES.dump()
            dump = true
        }
    }
}
