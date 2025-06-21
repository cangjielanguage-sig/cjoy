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
import stdx.encoding.json.stream.JsonSerializable
import cjoy.mcp.common.*
import cjoy.framework.{Joy, JoyContext}
import cjoy.log.LogTool
import cjoy.json.JsonTool

public class McpServerFeatures {
    public var protocolVesion: String = McpConsts.LASTEST_PROTOCOL_VERSION
    public var serverInfo: Implementation = Implementation(name: "cjoy", version: "1.0")
    var capabilities: ServerCapabilities = ServerCapabilities()
    public var instructions: ?String = None
}

public class McpServer {
    static let callToolHandlers: ConcurrentHashMap<String, McpCallToolHandler> = ConcurrentHashMap()

    static let tools: ConcurrentHashMap<String, McpTool> = ConcurrentHashMap()

    static var serverFeatures: ?McpServerFeatures = None

    public static func addMcpCallToolHandler(method: String, handler: McpCallToolHandler) {
        callToolHandlers.add(method, handler)
    }

    public static func addTool(tool: McpTool): Unit {
        tools.add(tool.name, tool)
    }

    public static func listTools(page: PaginatedRequest): ListToolsResult {
        let res: ArrayList<McpTool> = ArrayList()
        for ((_, value) in tools) {
            res.add(value)
        }
        ListToolsResult(tools: res)
    }

    public static func callTool(ctx: JoyContext, request: CallToolRequest): CallToolResult {
        if (let Some(handler) <- callToolHandlers.get(request.name)) {
            let arguments = (request.arguments as Array<Byte>) ?? Array<Byte>()
            var isError = false
            let content: Content = try {
                let result: Any = handler.handle(ctx, arguments)
                match (result) {
                    case x: ToString => createTextContent(x.toString())
                    case x: JsonSerializable => createTextContent(JsonTool.toJson(x))
                    case x: Image => x.toImageContext()
                    case x: Audio => x.toAudioContent()
                    case _ =>
                        LogTool.error("[MCP]call tool `${request.name}` failed, unknow return type")
                        isError = true
                        createTextContent("unknow return type")
                }
            } catch (ex: Exception) {
                isError = true
                LogTool.error("[MCP]call tool `${request.name}` failed, ${ex.message}")
                createTextContent(ex.message)
            }
            CallToolResult(isError: isError, content: ArrayList<Content>([content]))
        } else {
            let content = createTextContent("not found tool handler")
            CallToolResult(isError: true, content: ArrayList<Content>([content]))
        }
    }

    private static func createTextContent(text: String): TextContent {
        let content = TextContent(text: text)
        content.type_ = "text"
        content
    }

    public static func exchangeInit(): InitializeResult {
        let features = McpServer.serverFeatures.getOrThrow()
        InitializeResult(protocolVersion: features.protocolVesion, capabilities: features.capabilities,
            serverInfo: features.serverInfo, instructions: features.instructions)
    }

    public static func registerSseTo(joy: Joy, ssePath!: String = "/sse", messagePath!: String = "/messages",
        serverFeatures!: McpServerFeatures = McpServerFeatures()): Unit {
        updateFeatures(serverFeatures)

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

    public static func registerStreamableTo(joy: Joy, path!: String = "/mcp", isJsonResp!: Bool = false,
        serverFeatures!: McpServerFeatures = McpServerFeatures()): Unit {
        updateFeatures(serverFeatures)
        let transport = McpStreamableServerTransport(isJsonResp)

        let rg = joy.router.findGroup(path)
        let rpath = path[rg.basePath().size..]
        rg.get(rpath, transport.handleGetRequest)
        rg.post(rpath, transport.handlePostRequest)
    }

    private static func updateFeatures(serverFeatures: McpServerFeatures) {
        McpServer.serverFeatures = serverFeatures
        if (!tools.isEmpty()) {
            serverFeatures.capabilities.tools = ToolCapability()
        }
    }
}
