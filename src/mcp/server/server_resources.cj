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

import std.convert.Parsable
import std.collection.{ArrayList, map, collectArray}
import std.collection.concurrent.ConcurrentHashMap
import stdx.encoding.json.stream.JsonSerializable
import stdx.encoding.base64.toBase64String
import cjoy.mcp.api.*
import cjoy.framework.{JoyContext, RouteInfo, TreeNode, JoyHttpConsts}
import cjoy.log.macros.*
import cjoy.json.JsonTool

/**
 * Manager class for MCP resources
 *
 * Handles resource registration, discovery, and content reading. Provides methods for
 * adding resources, registering resource handlers, and accessing resource contents.
 */
public class McpResources {
    /**
     * ConcurrentHashMap for storing registered MCP resources
     */
    let resources: ConcurrentHashMap<String, McpResource> = ConcurrentHashMap()

    /**
     * ConcurrentHashMap for storing resource templates
     */
    let resourceTempls: ConcurrentHashMap<String, ResourceTemplate> = ConcurrentHashMap()

    /**
     * Root node of the routing tree for resource handlers
     */
    private let _root: TreeNode<McpReadResourceHandler> = TreeNode()

    private let _pageSize = 10

    /**
     * Adds a read resource handler for a specific URI
     *
     * @param uri The URI to handle
     * @param handler The McpReadResourceHandler implementation
     */
    public func addReadResourceHandler(uri: String, handler: McpReadResourceHandler): Unit {
        _root.addRoute("GET", normUrl(uri), handler)
    }

    /**
     * Dumps the resource handler routing tree for debugging purposes
     */
    public func dump() {
        @JoyLogInfo("[MCP] resource handler:\n${_root.dumpTree()}")
    }

    /**
     * Adds an MCP resource to the manager
     *
     * @param resource The McpResource instance to add
     */
    public func addResource(resource: McpResource): Unit {
        if (resources.contains(resource.uri)) {
            @JoyLogError("[MCP] resource `${resource.uri}` is existed, will be overwrite")
        }
        if (resource.uri.indexOf("://").isNone()) {
            @JoyLogError("[MCP] resource `${resource.uri}` is invalid")
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

    /**
     * Lists all available MCP resources with pagination support
     *
     * @param page PaginatedRequest containing cursor for pagination
     * @return ListResourcesResult containing list of resources and next cursor
     */
    public func listResources(page: PaginatedRequest): ListResourcesResult {
        let startIndex = page.cursor.map {it: String => Int.tryParse(it) ?? 0} ?? 0
        let res: ArrayList<McpResource> = ArrayList()

        var index = 0
        for ((_, value) in resources) {
            if (index >= startIndex && res.size < _pageSize) {
                res.add(value)
            }
            index += 1
        }

        let nextCursor = if (index > startIndex + _pageSize) {
            "${startIndex + _pageSize}"
        } else {
            Option<String>.None
        }

        let result = ListResourcesResult(resources: res)
        result.nextCursor = nextCursor
        result
    }

    /**
     * Lists all available resource templates with pagination support
     *
     * @param page PaginatedRequest containing cursor for pagination
     * @return ListResourceTemplatesResult containing list of templates and next cursor
     */
    public func listResourceTemplates(page: PaginatedRequest): ListResourceTemplatesResult {
        let startIndex = page.cursor.map {it: String => Int.tryParse(it) ?? 0} ?? 0
        let res: ArrayList<ResourceTemplate> = ArrayList()

        var index = 0
        for ((_, value) in resourceTempls) {
            if (index >= startIndex && res.size < _pageSize) {
                res.add(value)
            }
            index += 1
        }

        let nextCursor = if (index > startIndex + _pageSize) {
            "${startIndex + _pageSize}"
        } else {
            Option<String>.None
        }

        let result = ListResourceTemplatesResult(resourceTemplates: res)
        result.nextCursor = nextCursor
        result
    }

    /**
     * Removes the resources with the given URIs
     *
     * @param uris The URIs of the resources to remove
     */
    public func removeResources(uris: Array<String>): Unit {
        for (uri in uris) {
            resources.remove(uri)
            resourceTempls.remove(uri)
        }
    }

    /**
     * Removes a single resource with the given URI
     *
     * @param uri The URI of the resource to remove
     */
    public func removeResource(uri: String): Unit {
        removeResources([uri])
    }

    /**
     * Adds route parameters to the JoyContext
     *
     * @param ctx The JoyContext
     * @param ri The RouteInfo containing route parameters
     */
    private func addCtxParam(ctx: JoyContext, ri: RouteInfo<McpReadResourceHandler>) {
        if (!ri.routeParamKeys.isEmpty()) {
            if (ri.routeParamKeys.size != ri.routeParamValues.size) {
                @JoyLogError("[MCP] resource handler parameter list length mismatch when find route target")
                throw Exception("parameter list length mismatch")
            }
            for (idx in 0..ri.routeParamKeys.size) {
                ctx.addParam(ri.routeParamKeys[idx], ri.routeParamValues[idx])
            }
        }
    }

    /**
     * Reads the content of a specific resource
     *
     * @param ctx The JoyContext
     * @param request ReadResourceRequest containing the URI to read
     * @return ReadResourceResult containing the resource content
     * @throws Exception If resource not found or read error occurs
     */
    public func readResource(ctx: JoyContext, request: ReadResourceRequest): ReadResourceResult {
        let uri = normUrl(request.uri)
        let ri: RouteInfo<McpReadResourceHandler> = RouteInfo()
        let _ = _root.findRouteHandler(ri, "GET", uri)
        match (ri.handler) {
            case Some(x) =>
                @JoyLogDebug("[MCP] found resource handler, uri=${request.uri}")
                addCtxParam(ctx, ri)
                let result: Any = x.readResource(ctx)
                let contents: Array<ResourceContents> = match (result) {
                    case x: Array<Byte> => [createBlobResourceContents(request.uri, toBase64String(x),
                        getMimeType(ctx, JoyHttpConsts.MIME_APP_OCTET_STREAM))]
                    case x: Collection<Array<Byte>> => x |> map {
                        it => createBlobResourceContents(request.uri, toBase64String(it),
                            getMimeType(ctx, JoyHttpConsts.MIME_APP_OCTET_STREAM))
                    } |> collectArray
                    case x: Collection<String> => x |> map {
                        it => createTextResourceContents(request.uri, it, getMimeType(ctx, JoyHttpConsts.MIME_TEXT_PLAIN))
                    } |> collectArray
                    case x: Collection<JsonSerializable> => x |> map {
                        it =>
                            let value = JsonTool.toJson(it)
                            createTextResourceContents(request.uri, value, getMimeType(ctx, getMimeType(value)))
                    } |> collectArray
                    case x: Collection<ToString> => x |> map {
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
                        @JoyLogWarn("[MCP] read resource `${request.uri}`unknow return type")
                        [createTextResourceContents(request.uri, "", getMimeType(ctx, JoyHttpConsts.MIME_TEXT_PLAIN))]
                }
                ReadResourceResult(contents: ArrayList<ResourceContents>(contents))
            case _ =>
                @JoyLogError("[MCP] not found resource handler, uri=${request.uri}")
                throw Exception("not found resource handler")
        }
    }

    /**
     * Gets the MIME type from context or returns a default
     *
     * @param ctx The JoyContext
     * @param defaultValue The default MIME type to return
     * @return The MIME type from context or default value
     */
    private static func getMimeType(ctx: JoyContext, defaultValue: String): String {
        ctx.getParam("mimeType") ?? defaultValue
    }

    /**
     * Determines MIME type from string content
     *
     * @param str The string to analyze
     * @return MIME type (JSON if starts with { or [, otherwise plain text)
     */
    private static func getMimeType(str: String): String {
        if (str.startsWith("{") || str.startsWith("[")) {
            JoyHttpConsts.MIME_APP_JSON
        } else {
            JoyHttpConsts.MIME_TEXT_PLAIN
        }
    }

    /**
     * Normalizes a URI for routing
     *
     * @param uri The URI to normalize
     * @return Normalized URI
     */
    private static func normUrl(uri: String): String {
        "/" + uri.replace("://", "/").replace("//", "/")
    }

    /**
     * Creates a TextResourceContents instance
     *
     * @param uri The URI of the resource
     * @param text The text content
     * @param mimeType The MIME type of the content
     * @return TextResourceContents instance
     */
    private static func createTextResourceContents(uri: String, text: String, mimeType: String): ResourceContents {
        let res = TextResourceContents(text: text)
        res.uri = uri
        res.mimeType = mimeType
        res
    }

    /**
     * Creates a BlobResourceContents instance
     *
     * @param uri The URI of the resource
     * @param blob The base64 encoded blob content
     * @param mimeType The MIME type of the content
     * @return BlobResourceContents instance
     */
    private static func createBlobResourceContents(uri: String, blob: String, mimeType: String): ResourceContents {
        let res = BlobResourceContents(blob: blob)
        res.uri = uri
        res.mimeType = mimeType
        res
    }
}
