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

import std.collection.{ArrayList, HashMap}
import std.collection.concurrent.ConcurrentHashMap
import stdx.encoding.json.stream.JsonSerializable
import stdx.encoding.base64.toBase64String
import cjoy.mcp.common.*
import cjoy.framework.{Joy, JoyContext, JoyRequestHandler, RouteDistributor, VERSION}
import cjoy.log.LogTool
import cjoy.json.JsonTool

public class McpServerFeatures {
    public var protocolVesion: String = McpConsts.LASTEST_PROTOCOL_VERSION
    public var serverInfo: Implementation = Implementation(name: "cjoy", version: VERSION)
    var capabilities: ServerCapabilities = ServerCapabilities()
    public var instructions: ?String = None
}

public class McpServer {
    static let tools: ConcurrentHashMap<String, McpTool> = ConcurrentHashMap()
    static let callToolHandlers: ConcurrentHashMap<String, McpCallToolHandler> = ConcurrentHashMap()

    static let readReourceHandlers: ConcurrentHashMap<String, JoyRequestHandler> = ConcurrentHashMap()
    static let resources: ConcurrentHashMap<String, McpResource> = ConcurrentHashMap()
    static let resourceTempls: ConcurrentHashMap<String, ResourceTemplate> = ConcurrentHashMap()

    static var serverFeatures: ?McpServerFeatures = None

    //-----Tool -----
    public static func addCallToolHandler(method: String, handler: McpCallToolHandler) {
        callToolHandlers.add(method, handler)
    }

    public static func addTool(tool: McpTool): Unit {
        if (tools.contains(tool.name)) {
            LogTool.warn("[MCP]tool `${tool.name}` is existed, will be overwrite")
        }
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
                    case x: ArrayList<JsonSerializable> => createTextContent(JsonTool.toJson(x))
                    case x: HashMap<String, JsonSerializable> => createTextContent(JsonTool.toJson(x))
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

    //-----Resource -----
    public static func addReadResourceHandler(uri: String, handler: JoyRequestHandler) {
        readReourceHandlers.add(uri, handler)
    }

    public static func addResource(resource: McpResource): Unit {
        if (resources.contains(resource.uri)) {
            LogTool.warn("[MCP]resource `${resource.uri}` is existed, will be overwrite")
        }
        if (resource.uri.indexOf("://").isNone()) {
            LogTool.error("[MCP]resource `${resource.uri}` is invalid")
            return
        }
        resources.add(resource.uri, resource)
    }

    public static func listResources(page: PaginatedRequest): ListResourcesResult {
        let res: ArrayList<McpResource> = ArrayList()
        for ((_, value) in resources) {
            res.add(value)
        }
        ListResourcesResult(resources: res)
    }

    public static func listResourceTemplates(page: PaginatedRequest): ListResourceTemplatesResult {
        let res: ArrayList<ResourceTemplate> = ArrayList()
        for ((_, value) in resourceTempls) {
            res.add(value)
        }
        ListResourceTemplatesResult(resourceTemplates: res)
    }

    public static func readResource(ctx: JoyContext, request: ReadResourceRequest): ReadResourceResult {
        let distributor: RouteDistributor = ctx.getCtxParm<RouteDistributor>("__RouteDistributor__").getOrThrow()
        let uri = normUrl(request.uri)
        let rt = distributor.findRouteTarget("GET", uri)
        match (rt) {
            case Some(x) =>
                let handler = (x.handler as McpReadResuorceHandler).getOrThrow()
                for ((k, v) in x.paramMap) {
                    ctx.addParam(k, v)
                }
                let result: Any = handler.readResource(ctx)
                let content = match (result) {
                    case x: Array<Byte> => createBlobResourceContents(request.uri, toBase64String(x),
                        ctx.getParam("mimeType") ?? "application/octet-stream")
                    case x: ArrayList<JsonSerializable> => createTextResourceContents(request.uri, JsonTool.toJson(x),
                        ctx.getParam("mimeType") ?? "application/json")
                    case x: HashMap<String, JsonSerializable> => createTextResourceContents(request.uri,
                        JsonTool.toJson(x), ctx.getParam("mimeType") ?? "application/json")
                    case x: ToString => createTextResourceContents(request.uri, x.toString(),
                        ctx.getParam("mimeType") ?? "text/plain")
                    case x: JsonSerializable => createTextResourceContents(request.uri, JsonTool.toJson(x),
                        ctx.getParam("mimeType") ?? "application/json")
                    case _ =>
                        LogTool.warn("[MCP]read resource `${request.uri}`unknow return type")
                        createTextResourceContents(request.uri, "", ctx.getParam("mimeType") ?? "text/plain")
                }
                ReadResourceResult(contents: ArrayList<ResourceContents>([content]))
            case _ => throw Exception("not found resource handler")
        }
    }

    private static func normUrl(uri: String): String {
        "/" + uri.replace("://", "/").replace("//", "/")
    }

    private static func createTextResourceContents(uri: String, text: String, mimeType: String): TextResourceContents {
        let res = TextResourceContents(text: text)
        res.uri = uri
        res.mimeType = mimeType
        res
    }

    private static func createBlobResourceContents(uri: String, blob: String, mimeType: String): BlobResourceContents {
        let res = BlobResourceContents(blob: blob)
        res.uri = uri
        res.mimeType = mimeType
        res
    }

    //-----Initilize -----
    public static func exchangeInit(): InitializeResult {
        let features = McpServer.serverFeatures.getOrThrow()
        InitializeResult(protocolVersion: features.protocolVesion, capabilities: features.capabilities,
            serverInfo: features.serverInfo, instructions: features.instructions)
    }

    //-----register -----
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

        // add resource handler
        for ((k, v) in readReourceHandlers) {
            let uri = normUrl(k)
            joy.router.get(uri, v)
        }
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
        if (!resources.isEmpty()) {
            serverFeatures.capabilities.resources = ResourceCapability()
        }
    }
}
