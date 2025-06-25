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
import cjoy.framework.{JoyContext, JoyRequestHandler, RouteDistributor}
import cjoy.log.LogTool
import cjoy.json.JsonTool

public class McpResources {
    let readReourceHandlers: ConcurrentHashMap<String, JoyRequestHandler> = ConcurrentHashMap()
    let resources: ConcurrentHashMap<String, McpResource> = ConcurrentHashMap()
    let resourceTempls: ConcurrentHashMap<String, ResourceTemplate> = ConcurrentHashMap()

    //-----Resource -----
    public func addReadResourceHandler(uri: String, handler: JoyRequestHandler) {
        readReourceHandlers.add(uri, handler)
    }

    public func addResource(resource: McpResource): Unit {
        if (resources.contains(resource.uri)) {
            LogTool.warn("[MCP]resource `${resource.uri}` is existed, will be overwrite")
        }
        if (resource.uri.indexOf("://").isNone()) {
            LogTool.error("[MCP]resource `${resource.uri}` is invalid")
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

    public func readResource(ctx: JoyContext, request: ReadResourceRequest): ReadResourceResult {
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
                let contents: Array<ResourceContents> = match (result) {
                    case x: Array<Byte> => [createBlobResourceContents(request.uri, toBase64String(x),
                        ctx.getParam("mimeType") ?? "application/octet-stream")]
                    case x: Collection<Array<Byte>> => x |>
                        map {
                        it => createBlobResourceContents(request.uri, toBase64String(it),
                            ctx.getParam("mimeType") ?? "application/octet-stream")
                    } |> collectArray
                    case x: Collection<JsonSerializable> => x |>
                        map {
                        it => createTextResourceContents(request.uri, JsonTool.toJson(it),
                            ctx.getParam("mimeType") ?? "application/json")
                    } |> collectArray
                    case x: Collection<ToString> => x |>
                        map {
                        it => createTextResourceContents(request.uri, it.toString(),
                            ctx.getParam("mimeType") ?? "text/plain")
                    } |> collectArray
                    case x: HashMap<String, JsonSerializable> => [createTextResourceContents(request.uri,
                        JsonTool.toJson(x), ctx.getParam("mimeType") ?? "application/json")]
                    case x: ToString => [createTextResourceContents(request.uri, x.toString(),
                        ctx.getParam("mimeType") ?? "text/plain")]
                    case x: JsonSerializable => [createTextResourceContents(request.uri, JsonTool.toJson(x),
                        ctx.getParam("mimeType") ?? "application/json")]
                    case _ =>
                        LogTool.warn("[MCP]read resource `${request.uri}`unknow return type")
                        [createTextResourceContents(request.uri, "", ctx.getParam("mimeType") ?? "text/plain")]
                }
                ReadResourceResult(contents: ArrayList<ResourceContents>(contents))
            case _ => throw Exception("not found resource handler")
        }
    }

    static func normUrl(uri: String): String {
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
