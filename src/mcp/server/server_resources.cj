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
import cjoy.jsonrpc.{JSONRPCException, JSONRPCError, JSONRPCConsts}

/**
 * MCP 资源管理器类
 *
 * 处理资源注册、发现和内容读取。提供添加资源、注册资源处理程序和访问资源内容的方法。
 */
public class McpResources {
    /**
     * 用于存储已注册 MCP 资源的 ConcurrentHashMap
     */
    let resources: ConcurrentHashMap<String, McpResource> = ConcurrentHashMap()

    /**
     * 用于存储资源模板的 ConcurrentHashMap
     */
    let resourceTempls: ConcurrentHashMap<String, ResourceTemplate> = ConcurrentHashMap()

    /**
     * 资源处理程序路由树的根节点
     */
    private let _root: TreeNode<McpReadResourceHandler> = TreeNode()

    private let _pageSize = 10

    /**
     * 为特定 URI 添加读取资源处理程序
     *
     * @param uri 要处理的 URI
     * @param handler McpReadResourceHandler 实现
     */
    public func addReadResourceHandler(uri: String, handler: McpReadResourceHandler): Unit {
        _root.addRoute("GET", normUrl(uri), handler)
    }

    /**
     * 转储资源处理程序路由树，用于调试目的
     */
    public func dump() {
        @JoyLogInfo("[MCP] resource handler:\n${_root.dumpTree()}")
    }

    /**
     * 向管理器添加 MCP 资源
     *
     * @param resource 要添加的 McpResource 实例
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
     * 列出所有可用的 MCP 资源，支持分页
     *
     * @param page 包含分页游标的 PaginatedRequest
     * @return 包含资源列表和下一个游标的 ListResourcesResult
     */
    public func listResources(page: PaginatedRequest): ListResourcesResult {
        let res: ArrayList<McpResource> = ArrayList()

        // 将 ConcurrentHashMap 转换为 ArrayList 以便分页
        for ((_, value) in resources) {
            res.add(value)
        }

        // 使用统一的分页工具
        let utils = McpPaginationUtils(pageSize: _pageSize)
        let (paginatedRes, nextCursor) = utils.paginate(res, page)

        let result = ListResourcesResult(resources: paginatedRes)
        result.nextCursor = nextCursor
        result
    }

    /**
     * 列出所有可用的资源模板，支持分页
     *
     * @param page 包含分页游标的 PaginatedRequest
     * @return 包含模板列表和下一个游标的 ListResourceTemplatesResult
     */
    public func listResourceTemplates(page: PaginatedRequest): ListResourceTemplatesResult {
        let res: ArrayList<ResourceTemplate> = ArrayList()

        // 将 ConcurrentHashMap 转换为 ArrayList 以便分页
        for ((_, value) in resourceTempls) {
            res.add(value)
        }

        // 使用统一的分页工具
        let utils = McpPaginationUtils(pageSize: _pageSize)
        let (paginatedRes, nextCursor) = utils.paginate(res, page)

        let result = ListResourceTemplatesResult(resourceTemplates: paginatedRes)
        result.nextCursor = nextCursor
        result
    }

    /**
     * 移除具有给定 URI 的资源
     *
     * @param uris 要移除的资源 URI 数组
     */
    public func removeResources(uris: Array<String>): Unit {
        for (uri in uris) {
            resources.remove(uri)
            resourceTempls.remove(uri)
        }
    }

    /**
     * 移除具有给定 URI 的单个资源
     *
     * @param uri 要移除的资源 URI
     */
    public func removeResource(uri: String): Unit {
        removeResources([uri])
    }

    /**
     * 向 JoyContext 添加路由参数
     *
     * @param ctx JoyContext
     * @param ri 包含路由参数的 RouteInfo
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
     * 读取特定资源的内容
     *
     * @param ctx JoyContext
     * @param request 包含要读取的 URI 的 ReadResourceRequest
     * @return 包含资源内容的 ReadResourceResult
     * @throws Exception 如果未找到资源或读取错误
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
                        let error = JSONRPCError(code: JSONRPCConsts.ERR_INVALID_REQUEST, message: "unknow resource")
                        throw JSONRPCException(error)
                }
                ReadResourceResult(contents: ArrayList<ResourceContents>(contents))
            case _ =>
                @JoyLogError("[MCP] not found resource handler, uri=${request.uri}")
                let error = JSONRPCError(code: JSONRPCConsts.ERR_INVALID_REQUEST, message: "not found resource")
                throw JSONRPCException(error)
        }
    }

    /**
     * 从上下文获取 MIME 类型或返回默认值
     *
     * @param ctx JoyContext
     * @param defaultValue 默认的 MIME 类型
     * @return 上下文中的 MIME 类型或默认值
     */
    private static func getMimeType(ctx: JoyContext, defaultValue: String): String {
        ctx.getParam("mimeType") ?? defaultValue
    }

    /**
     * 从字符串内容确定 MIME 类型
     *
     * @param str 要分析的字符串
     * @return MIME 类型（如果以 { 或 [ 开头则为 JSON，否则为纯文本）
     */
    private static func getMimeType(str: String): String {
        if (str.startsWith("{") || str.startsWith("[")) {
            JoyHttpConsts.MIME_APP_JSON
        } else {
            JoyHttpConsts.MIME_TEXT_PLAIN
        }
    }

    /**
     * 规范化 URI 用于路由
     *
     * @param uri 要规范化的 URI
     * @return 规范化后的 URI
     */
    private static func normUrl(uri: String): String {
        "/" + uri.replace("://", "/").replace("//", "/")
    }

    /**
     * 创建 TextResourceContents 实例
     *
     * @param uri 资源的 URI
     * @param text 文本内容
     * @param mimeType 内容的 MIME 类型
     * @return TextResourceContents 实例
     */
    private static func createTextResourceContents(uri: String, text: String, mimeType: String): ResourceContents {
        let res = TextResourceContents(text: text)
        res.uri = uri
        res.mimeType = mimeType
        res
    }

    /**
     * 创建 BlobResourceContents 实例
     *
     * @param uri 资源的 URI
     * @param blob base64 编码的 blob 内容
     * @param mimeType 内容的 MIME 类型
     * @return BlobResourceContents 实例
     */
    private static func createBlobResourceContents(uri: String, blob: String, mimeType: String): ResourceContents {
        let res = BlobResourceContents(blob: blob)
        res.uri = uri
        res.mimeType = mimeType
        res
    }
}
