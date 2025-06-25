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
import cjoy.framework.{JoyContext}
import cjoy.log.LogTool
import cjoy.json.JsonTool

public class McpTools {
    // tools
    let tools: ConcurrentHashMap<String, McpTool> = ConcurrentHashMap()
    let callToolHandlers: ConcurrentHashMap<String, McpCallToolHandler> = ConcurrentHashMap()

    public func addCallToolHandler(method: String, handler: McpCallToolHandler) {
        callToolHandlers.add(method, handler)
    }

    public func addTool(tool: McpTool): Unit {
        if (tools.contains(tool.name)) {
            LogTool.warn("[MCP]tool `${tool.name}` is existed, will be overwrite")
        }
        tools.add(tool.name, tool)
    }

    public func listTools(page: PaginatedRequest): ListToolsResult {
        let res: ArrayList<McpTool> = ArrayList()
        for ((_, value) in tools) {
            res.add(value)
        }
        ListToolsResult(tools: res)
    }

    public func callTool(ctx: JoyContext, request: CallToolRequest): CallToolResult {
        if (let Some(handler) <- callToolHandlers.get(request.name)) {
            let arguments = (request.arguments as Array<Byte>) ?? Array<Byte>()
            var isError = false
            let contents: Array<Content> = try {
                let result: Any = handler.handle(ctx, arguments)
                match (result) {
                    case x: Collection<ToString> => x |> map {it => createTextContent(it.toString())} |> collectArray
                    case x: Collection<JsonSerializable> => x |> map {it => createTextContent(JsonTool.toJson(it))} |>
                        collectArray
                    case x: HashMap<String, JsonSerializable> => [createTextContent(JsonTool.toJson(x))]
                    case x: ToString => [createTextContent(x.toString())]
                    case x: JsonSerializable => [createTextContent(JsonTool.toJson(x))]
                    case x: Image => [x.toImageContext()]
                    case x: Audio => [x.toAudioContent()]
                    case x: Collection<Image> => x |> map {it => it.toImageContext()} |> collectArray
                    case x: Collection<Audio> => x |> map {it => it.toAudioContent()} |> collectArray
                    case _ =>
                        LogTool.error("[MCP]call tool `${request.name}` failed, unknow return type")
                        isError = true
                        [createTextContent("unknow return type")]
                }
            } catch (ex: Exception) {
                isError = true
                LogTool.error("[MCP]call tool `${request.name}` failed, ${ex.message}")
                [createTextContent(ex.message)]
            }
            CallToolResult(isError: isError, content: ArrayList<Content>(contents))
        } else {
            let content = createTextContent("not found tool handler")
            CallToolResult(isError: true, content: ArrayList<Content>([content]))
        }
    }

    private static func createTextContent(text: String): Content {
        let content = TextContent(text: text)
        content.type_ = "text"
        content
    }
}
