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

import std.collection.{ArrayList, map, collectArray}
import std.collection.concurrent.ConcurrentHashMap
import stdx.encoding.json.stream.JsonSerializable
import cjoy.mcp.api.*
import cjoy.framework.{JoyContext}
import cjoy.log.macros.*
import cjoy.json.JsonTool

/**
 * MCP 工具管理器类
 *
 * 处理工具注册、发现和调用。提供添加工具、注册工具处理程序和执行工具调用的方法。
 */
public class McpTools {
    // 工具
    /**
     * 用于存储已注册 MCP 工具的 ConcurrentHashMap
     */
    let tools: ConcurrentHashMap<String, McpTool> = ConcurrentHashMap()

    /**
     * 用于存储工具调用处理程序的 ConcurrentHashMap
     */
    let callToolHandlers: ConcurrentHashMap<String, McpCallToolHandler> = ConcurrentHashMap()

    private let _pageSize = 10

    /**
     * 为特定方法添加工具调用处理程序
     *
     * @param method 要处理的方法名
     * @param handler 处理程序实现
     */
    public func addCallToolHandler(method: String, handler: McpCallToolHandler) {
        callToolHandlers.add(method, handler)
    }

    /**
     * 向管理器添加 MCP 工具
     *
     * @param tool 要添加的 McpTool 实例
     */
    public func addTool(tool: McpTool): Unit {
        if (tools.contains(tool.name)) {
            @JoyLogWarn("[MCP]tool `${tool.name}` is existed, will be overwrite")
        }
        tools.add(tool.name, tool)
    }

    /**
     * 列出所有可用的 MCP 工具，支持分页
     *
     * @param page 包含分页游标的 PaginatedRequest
     * @return 包含工具列表和下一个游标的 ListToolsResult
     */
    public func listTools(page: PaginatedRequest): ListToolsResult {
        let res: ArrayList<McpTool> = ArrayList()

        // 将 ConcurrentHashMap 转换为 ArrayList 以便分页
        for ((_, value) in tools) {
            res.add(value)
        }

        // 使用统一的分页工具
        let utils = McpPaginationUtils(pageSize: _pageSize)
        let (paginatedRes, nextCursor) = utils.paginate(res, page)

        let result = ListToolsResult(tools: paginatedRes)
        result.nextCursor = nextCursor
        result
    }

    /**
     * 移除具有给定名称的工具
     *
     * @param names 要移除的工具名称数组
     */
    public func removeTools(names: Array<String>): Unit {
        for (name in names) {
            tools.remove(name)
            callToolHandlers.remove(name)
        }
    }

    /**
     * 移除具有给定名称的单个工具
     *
     * @param name 要移除的工具名称
     */
    public func removeTool(name: String): Unit {
        removeTools([name])
    }

    /**
     * 使用给定请求调用 MCP 工具
     *
     * @param ctx 请求的 JoyContext
     * @param request 包含工具名和参数的 CallToolRequest
     * @return 包含工具响应或错误信息的 CallToolResult
     */
    public func callTool(ctx: JoyContext, request: CallToolRequest): CallToolResult {
        if (let Some(handler) <- callToolHandlers.get(request.name)) {
            let arguments = (request.arguments as Array<Byte>) ?? Array<Byte>()
            var isError = false
            let contents: Array<Content> = try {
                let result: Any = handler.handle(ctx, arguments)
                match (result) {
                    case x: Collection<String> => x |> map {it => createTextContent(it)} |> collectArray
                    case x: Collection<JsonSerializable> => x |> map {it => createTextContent(JsonTool.toJson(it))} |>
                        collectArray
                    case x: Collection<ToString> => x |> map {it => createTextContent(it.toString())} |> collectArray
                    case x: String => [createTextContent(x.toString())]
                    case x: JsonSerializable => [createTextContent(JsonTool.toJson(x))]
                    case x: ToString => [createTextContent(x.toString())]
                    case x: Image => [x.toImageContext()]
                    case x: Audio => [x.toAudioContent()]
                    case x: Collection<Image> => x |> map {it => it.toImageContext()} |> collectArray
                    case x: Collection<Audio> => x |> map {it => it.toAudioContent()} |> collectArray
                    case _ =>
                        @JoyLogError("[MCP] call tool `${request.name}` failed, unknow return type")
                        isError = true
                        [createTextContent("unknow return type")]
                }
            } catch (ex: Exception) {
                isError = true
                @JoyLogError("[MCP]call tool `${request.name}` failed, ${ex.message}")
                [createTextContent(ex.message)]
            }
            CallToolResult(isError: isError, content: ArrayList<Content>(contents))
        } else {
            let content = createTextContent("not found tool handler")
            CallToolResult(isError: true, content: ArrayList<Content>([content]))
        }
    }

    /**
     * 创建具有给定文本的 TextContent 实例
     *
     * @param text 要包装的文本
     * @return 类型为 "text" 的 TextContent 实例
     */
    private static func createTextContent(text: String): Content {
        let content = TextContent(text: text)
        content.type_ = "text"
        content
    }
}
