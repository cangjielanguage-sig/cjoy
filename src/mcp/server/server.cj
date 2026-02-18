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
 * Represents the configurable features for an MCP server
 *
 * This class contains all the server-specific configurations and capabilities
 * that are negotiated during the MCP initialization phase.
 */
public class McpServerFeatures {
    /**
     * MCP protocol version supported by the server
     */
    public var protocolVersion: String = McpConsts.LASTEST_PROTOCOL_VERSION

    /**
     * Information about the server implementation
     */
    public var serverInfo: Implementation = Implementation(name: "cjoy", version: VERSION)

    /**
     * Capabilities supported by the server (tools, resources, prompts)
     */
    var capabilities: ServerCapabilities = ServerCapabilities()

    /**
     * Instructions or guidelines for using the server
     */
    public var instructions: ?String = None

    /**
     * Keepalive interval for MCP sessions in milliseconds
     *
     * If set to a positive value, the server will send ping messages at the specified interval
     * to keep the connection alive. If set to 0 or negative, keepalive is disabled.
     */
    public var keepaliveIntervalMs: Int64 = 0

    /**
     * Keepalive timeout for MCP sessions in milliseconds
     *
     * If no response to a ping is received within this time, the session will be closed.
     * Defaults to half of the keepalive interval.
     */
    public var keepaliveTimeoutMs: Int64 = 0
}

/**
 * Main entry point for MCP server functionality
 *
 * Provides static methods for registering MCP servers with CJoy framework and
 * managing server-wide resources, tools, and prompts.
 */
public class McpServer {
    /**
     * Static instance for managing MCP tools
     */
    public static let TOOLS: McpTools = McpTools()

    /**
     * Static instance for managing MCP resources
     */
    public static let RESOURCES: McpResources = McpResources()

    /**
     * Static instance for managing MCP prompts
     */
    public static let PROMPTS: McpPrompts = McpPrompts()

    private static var serverFeatures: ?McpServerFeatures = None
    private static var dump = false

    /**
     * Handles the initialization exchange with MCP clients
     *
     * @return The InitializeResult containing server capabilities and information
     * @throws Exception If server features are not properly configured
     */
    public static func exchangeInit(): InitializeResult {
        let features = McpServer.serverFeatures.getOrThrow()
        InitializeResult(protocolVersion: features.protocolVersion, capabilities: features.capabilities,
            serverInfo: features.serverInfo, instructions: features.instructions)
    }

    /**
     * Registers an MCP server with SSE (Server-Sent Events) transport to CJoy framework
     *
     * @param joy The CJoy instance to register with
     * @param ssePath The path for SSE connections (default: "/sse")
     * @param messagePath The path for message exchange (default: "/messages")
     * @param serverFeatures The server features configuration (default: McpServerFeatures())
     * @param disableLocalhostProtection Whether to disable DNS rebinding protection for localhost (default: false)
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
     * Registers an MCP server with streamable transport to CJoy framework
     *
     * @param joy The CJoy instance to register with
     * @param path The path for streamable transport (default: "/mcp")
     * @param isJsonResp Whether to return JSON responses directly instead of SSE streams (default: false)
     * @param eventStore Optional event store for persisting events (default: None)
     * @param serverFeatures The server features configuration (default: McpServerFeatures())
     * @param disableLocalhostProtection Whether to disable DNS rebinding protection for localhost (default: false)
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
     * Updates the server features and capabilities based on registered tools, resources, and prompts
     *
     * @param serverFeatures The server features configuration to update
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
     * Dumps the registered resources for debugging purposes
     */
    private static func dumpResources(): Unit {
        if (!dump) {
            RESOURCES.dump()
            dump = true
        }
    }
}
