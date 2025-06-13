/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.mcp.server

import std.collection.ArrayList
import std.collection.concurrent.ConcurrentHashMap
import cjoy.mcp.schema.*
import cjoy.mcp.common.*
import cjoy.framework.{Joy, JoyContext}

public class McpServerFeatures {
    public var protocolVesion: String = McpConsts.LASTEST_PROTOCOL_VERSION
    public var serverInfo: Implementation = Implementation(name: "cjoy", version: "1.0")
    var capabilities: ServerCapabilities = ServerCapabilities()
    public var instructions: ?String = None
}

public class McpServer {
    static let callToolHandlers: ConcurrentHashMap<String, McpCallToolHandler> = ConcurrentHashMap()

    static let tools: ConcurrentHashMap<String, Tool> = ConcurrentHashMap()

    static var serverFeatures: ?McpServerFeatures = None

    public static func addMcpCallToolHandler(method: String, handler: McpCallToolHandler) {
        callToolHandlers.add(method, handler)
    }

    public static func addTool(tool: Tool): Unit {
        tools.add(tool.name, tool)
    }

    public static func listTools(page: PaginatedRequest): ListToolsResult {
        let res: ArrayList<Tool> = ArrayList()
        for ((_, value) in tools) {
            res.add(value)
        }
        ListToolsResult(tools: res)
    }

    public static func callTool(ctx: JoyContext, request: CallToolRequest): CallToolResult {
        if (let Some(handler) <- callToolHandlers.get(request.name)) {
            let arguments = (request.arguments as Array<Byte>) ?? Array<Byte>()
            var isError = false
            let res = try {
                handler.handle(ctx, arguments)
            } catch (ex: Exception) {
                isError = true
                ex.message
            }
            let content = TextContent(type_: "text", text: res)
            CallToolResult(isError: isError, content: ArrayList([content]))
        } else {
            let content = TextContent(type_: "text", text: "not found tool handler")
            CallToolResult(isError: true, content: ArrayList([content]))
        }
    }

    public static func exchangeInit(): InitializeResult {
        let features = McpServer.serverFeatures.getOrThrow()
        InitializeResult(protocolVersion: features.protocolVesion, capabilities: features.capabilities,
            serverInfo: features.serverInfo, instructions: features.instructions)
    }

    public static func registerSseTo(joy: Joy, ssePath!: String = "/sse", messagePath!: String = "/messages",
        serverFeatures!: McpServerFeatures = McpServerFeatures()) {
        McpServer.serverFeatures = serverFeatures
        if (!tools.isEmpty()) {
            serverFeatures.capabilities.tools = ToolCapability()
        }

        let transport = McpSseServerTransport(messagePath)
        // sse 
        let rg1 = joy.router.findGroup(ssePath)
        let rpath1 = ssePath[rg1.basePath().size..]
        rg1.get(rpath1, transport.handleSseRequest)

        // messages
        let rg2 = joy.router.findGroup(messagePath)
        let rpath2 = messagePath[rg2.basePath().size..]
        rg2.post(rpath2, transport.handlePostRequest)
    }
}
