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
import std.collection.{ArrayList, HashMap, map, collectArray}
import std.collection.concurrent.ConcurrentHashMap
import stdx.encoding.json.stream.JsonSerializable
import cjoy.mcp.api.*
import cjoy.framework.{JoyContext}
import cjoy.log.macros.*
import cjoy.json.JsonTool

/**
 * Manager class for MCP tools
 *
 * Handles tool registration, discovery, and invocation. Provides methods for
 * adding tools, registering tool handlers, and executing tool calls.
 */
public class McpTools {
    // tools
    /**
     * ConcurrentHashMap for storing registered MCP tools
     */
    let tools: ConcurrentHashMap<String, McpTool> = ConcurrentHashMap()

    /**
     * ConcurrentHashMap for storing tool call handlers
     */
    let callToolHandlers: ConcurrentHashMap<String, McpCallToolHandler> = ConcurrentHashMap()

    private let _pageSize = 10

    /**
     * Adds a tool call handler for a specific method
     *
     * @param method The method name to handle
     * @param handler The handler implementation
     */
    public func addCallToolHandler(method: String, handler: McpCallToolHandler) {
        callToolHandlers.add(method, handler)
    }

    /**
     * Adds an MCP tool to the manager
     *
     * @param tool The McpTool instance to add
     */
    public func addTool(tool: McpTool): Unit {
        if (tools.contains(tool.name)) {
            @JoyLogWarn("[MCP]tool `${tool.name}` is existed, will be overwrite")
        }
        tools.add(tool.name, tool)
    }

    /**
     * Lists all available MCP tools with pagination support
     *
     * @param page PaginatedRequest containing cursor for pagination
     * @return ListToolsResult containing list of tools and next cursor
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
     * Removes the tools with the given names
     *
     * @param names The names of the tools to remove
     */
    public func removeTools(names: Array<String>): Unit {
        for (name in names) {
            tools.remove(name)
            callToolHandlers.remove(name)
        }
    }

    /**
     * Removes a single tool with the given name
     *
     * @param name The name of the tool to remove
     */
    public func removeTool(name: String): Unit {
        removeTools([name])
    }

    /**
     * Calls an MCP tool with the given request
     *
     * @param ctx The JoyContext for the request
     * @param request CallToolRequest containing tool name and arguments
     * @return CallToolResult containing the tool's response or error information
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
     * Creates a TextContent instance with the given text
     *
     * @param text The text to wrap
     * @return TextContent instance with type "text"
     */
    private static func createTextContent(text: String): Content {
        let content = TextContent(text: text)
        content.type_ = "text"
        content
    }
}
