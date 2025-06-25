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

import std.collection.{ArrayList, HashMap, map, collectArray}
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
    public static let tools = McpTools()
    public static let resources = McpResources()
    public static let prompts = McpPrompts()
    private static var serverFeatures: ?McpServerFeatures = None

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
        for ((k, v) in resources.readReourceHandlers) {
            let uri = McpResources.normUrl(k)
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
        if (!tools.tools.isEmpty()) {
            serverFeatures.capabilities.tools = ToolCapability()
        }
        if (!resources.resources.isEmpty() || !resources.resourceTempls.isEmpty()) {
            serverFeatures.capabilities.resources = ResourceCapability()
        }
        if (!prompts.prompts.isEmpty()) {
            serverFeatures.capabilities.prompts = PromptsCapability()
        }
    }
}
