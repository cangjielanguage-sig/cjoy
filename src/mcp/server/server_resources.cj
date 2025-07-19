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
import cjoy.mcp.api.*
import cjoy.framework.{JoyContext, RouteInfo, TreeNode, JoyHttpConsts}
import cjoy.log.LogTool
import cjoy.json.JsonTool

public class McpResources {
    let resources: ConcurrentHashMap<String, McpResource> = ConcurrentHashMap()
    let resourceTempls: ConcurrentHashMap<String, ResourceTemplate> = ConcurrentHashMap()
    private let _root: TreeNode<McpReadResourceHandler> = TreeNode()

    //-----Resource -----
    public func addReadResourceHandler(uri: String, handler: McpReadResourceHandler) {
        _root.addRoute("GET", normUrl(uri), handler)
    }

    public func dump() {
        LogTool.info("[MCP] resource handler:\n${_root.dumpTree()}")
    }

    public func addResource(resource: McpResource): Unit {
        if (resources.contains(resource.uri)) {
            LogTool.warn("[MCP] resource `${resource.uri}` is existed, will be overwrite")
        }
        if (resource.uri.indexOf("://").isNone()) {
            LogTool.error("[MCP] resource `${resource.uri}` is invalid")
            return
        }
        if (resource.uri.indexOf("{").isSome()) {
            let templ = ResourceTemplate(uriTemplate: resource.uri, name: resource.name,
                description: resource.description, mimeType: resource.mimeType)
            resourceTempls.add(resource.uri, templ)
        } else {
            resources.add(resource.uri, resource)
        }
    }

    public func listResources(page: PaginatedRequest): ListResourcesResult {
        let res: ArrayList<McpResource> = ArrayList()
        for ((_, value) in resources) {
            res.add(value)
        }
        ListResourcesResult(resources: res)
    }

    public func listResourceTemplates(page: PaginatedRequest): ListResourceTemplatesResult {
        let res: ArrayList<ResourceTemplate> = ArrayList()
        for ((_, value) in resourceTempls) {
            res.add(value)
        }
        ListResourceTemplatesResult(resourceTemplates: res)
    }

    private func addCtxParam(ctx: JoyContext, ri: RouteInfo<McpReadResourceHandler>) {
        if (!ri.routeParamKeys.isEmpty()) {
            if (ri.routeParamKeys.size != ri.routeParamValues.size) {
                LogTool.error("[MCP] resource handler parameter list length mismatch when find route target")
                throw Exception("parameter list length mismatch")
            }
            for (idx in 0..ri.routeParamKeys.size) {
                ctx.addParam(ri.routeParamKeys[idx], ri.routeParamValues[idx])
            }
        }
    }

    public func readResource(ctx: JoyContext, request: ReadResourceRequest): ReadResourceResult {
        let uri = normUrl(request.uri)
        let ri: RouteInfo<McpReadResourceHandler> = RouteInfo()
        let _ = _root.findRouteHandler(ri, "GET", uri)
        match (ri.handler) {
            case Some(x) =>
                LogTool.debug("[MCP] found resource handler, uri=${request.uri}")
                addCtxParam(ctx, ri)
                let result: Any = x.readResource(ctx)
                let contents: Array<ResourceContents> = match (result) {
                    case x: Array<Byte> => [createBlobResourceContents(request.uri, toBase64String(x),
                        getMimeType(ctx, JoyHttpConsts.MIME_APP_OCTET_STREAM))]
                    case x: Collection<Array<Byte>> => x |>
                        map {
                        it => createBlobResourceContents(request.uri, toBase64String(it),
                            getMimeType(ctx, JoyHttpConsts.MIME_APP_OCTET_STREAM))
                    } |> collectArray
                    case x: Collection<String> => x |>
                        map {
                        it => createTextResourceContents(request.uri, it,
                            getMimeType(ctx, JoyHttpConsts.MIME_TEXT_PLAIN))
                    } |> collectArray
                    case x: Collection<JsonSerializable> => x |>
                        map {
                        it =>
                        let value = JsonTool.toJson(it)
                        createTextResourceContents(request.uri, value, getMimeType(ctx, getMimeType(value)))
                    } |> collectArray
                    case x: Collection<ToString> => x |>
                        map {
                        it => createTextResourceContents(request.uri, it.toString(),
                            getMimeType(ctx, JoyHttpConsts.MIME_TEXT_PLAIN))
                    } |> collectArray
                    case x: String => [createTextResourceContents(request.uri, x,
                        getMimeType(ctx, JoyHttpConsts.MIME_TEXT_PLAIN))]
                    case x: JsonSerializable =>
                        let value = JsonTool.toJson(x)
                        [createTextResourceContents(request.uri, value, getMimeType(ctx, getMimeType(value)))]
                    case x: ToString => [createTextResourceContents(request.uri, x.toString(),
                        getMimeType(ctx, JoyHttpConsts.MIME_TEXT_PLAIN))]
                    case _ =>
                        LogTool.warn("[MCP] read resource `${request.uri}`unknow return type")
                        [createTextResourceContents(request.uri, "", getMimeType(ctx, JoyHttpConsts.MIME_TEXT_PLAIN))]
                }
                ReadResourceResult(contents: ArrayList<ResourceContents>(contents))
            case _ =>
                LogTool.error("[MCP] not found resource handler, uri=${request.uri}")
                throw Exception("not found resource handler")
        }
    }

    private static func getMimeType(ctx: JoyContext, defaultValue: String): String {
        ctx.getParam("mimeType") ?? defaultValue
    }

    private static func getMimeType(str: String): String {
        if (str.startsWith("{") || str.startsWith("[")) {
            JoyHttpConsts.MIME_APP_JSON
        } else {
            JoyHttpConsts.MIME_TEXT_PLAIN
        }
    }

    private static func normUrl(uri: String): String {
        "/" + uri.replace("://", "/").replace("//", "/")
    }

    private static func createTextResourceContents(uri: String, text: String, mimeType: String): ResourceContents {
        let res = TextResourceContents(text: text)
        res.uri = uri
        res.mimeType = mimeType
        res
    }

    private static func createBlobResourceContents(uri: String, blob: String, mimeType: String): ResourceContents {
        let res = BlobResourceContents(blob: blob)
        res.uri = uri
        res.mimeType = mimeType
        res
    }
}
