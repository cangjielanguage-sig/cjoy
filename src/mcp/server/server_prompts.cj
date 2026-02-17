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
import cjoy.mcp.api.*
import cjoy.framework.JoyContext
import cjoy.log.macros.*
import cjoy.json.JsonTool

/**
 * Manager class for MCP prompts
 *
 * Handles prompt registration, discovery, and retrieval. Provides methods for
 * adding prompts, registering prompt handlers, and getting prompt content.
 */
public class McpPrompts {
    /**
     * ConcurrentHashMap for storing get prompt handlers
     */
    private let getPromptHandlers: ConcurrentHashMap<String, McpGetPromptHandler> = ConcurrentHashMap()

    /**
     * ConcurrentHashMap for storing registered MCP prompts
     */
    let prompts: ConcurrentHashMap<String, McpPrompt> = ConcurrentHashMap()

    /**
     * Adds an MCP prompt to the manager
     *
     * @param prompt The McpPrompt instance to add
     */
    public func addPrompt(prompt: McpPrompt): Unit {
        if (prompts.contains(prompt.name)) {
            @JoyLogWarn("[MCP] prompt `${prompt.name}` is existed, will be overwrite")
        }
        prompts.add(prompt.name, prompt)
    }

    /**
     * Adds a get prompt handler for a specific prompt name
     *
     * @param name The name of the prompt to handle
     * @param handler The McpGetPromptHandler implementation
     */
    public func addGetPromptHandler(name: String, handler: McpGetPromptHandler): Unit {
        getPromptHandlers.add(name, handler)
    }

    /**
     * Lists all available MCP prompts with pagination support
     *
     * @param page PaginatedRequest containing cursor for pagination
     * @return ListPromptResult containing list of prompts and next cursor
     */
    public func listPrompt(page: PaginatedRequest): ListPromptResult {
        let pageSize = 10
        let startIndex = page.cursor.map {it: String => Int.tryParse(it) ?? 0} ?? 0
        let res: ArrayList<McpPrompt> = ArrayList()

        var index = 0
        for ((_, value) in prompts) {
            if (index >= startIndex && res.size < pageSize) {
                res.add(value)
            }
            index += 1
        }

        let nextCursor = if (index > startIndex + pageSize) {
            "${startIndex + pageSize}"
        } else {
            Option<String>.None
        }

        let result = ListPromptResult(prompts: res)
        result.nextCursor = nextCursor
        result
    }

    /**
     * Removes the prompts with the given names
     *
     * @param names The names of the prompts to remove
     */
    public func removePrompts(names: Array<String>): Unit {
        for (name in names) {
            prompts.remove(name)
            getPromptHandlers.remove(name)
        }
    }

    /**
     * Removes a single prompt with the given name
     *
     * @param name The name of the prompt to remove
     */
    public func removePrompt(name: String): Unit {
        removePrompts([name])
    }

    /**
     * Gets a specific prompt with the given request
     *
     * @param ctx The JoyContext
     * @param req GetPromptRequest containing prompt name and arguments
     * @return GetPromptResult containing the prompt messages
     * @throws Exception If prompt not found or handler returns unknown type
     */
    public func getPrompt(ctx: JoyContext, req: GetPromptRequest): GetPromptResult {
        let messages: Array<PromptMessage> = match (getPromptHandlers.get(req.name)) {
            case Some(handler) =>
                let result = handler.getPrompt(ctx, req.arguments)
                match (result) {
                    case x: PromptMessage => [x]
                    case x: Collection<PromptMessage> => x |> collectArray
                    case x: Message => [x.toPromptMessage()]
                    case x: Collection<Message> => x |> map {it => it.toPromptMessage()} |> collectArray
                    case x: String => [toPromptMessage(x)]
                    case x: JsonSerializable => [toPromptMessage(JsonTool.toJson(x))]
                    case x: ToString => [toPromptMessage(x.toString())]
                    case x: Collection<String> => x |> map {it => toPromptMessage(it)} |> collectArray
                    case x: Collection<JsonSerializable> => x |> map {it => toPromptMessage(JsonTool.toJson(it))} |>
                        collectArray
                    case x: Collection<ToString> => x |> map {it => toPromptMessage(it.toString())} |> collectArray
                    case _ =>
                        @JoyLogError("[MCP] unknow prompt return type, name=${req.name}")
                        throw Exception("unknow prompt return type")
                }
            case _ =>
                @JoyLogError("[MCP] not found prompt handler, name=${req.name}")
                throw Exception("not found prompt handler")
        }
        GetPromptResult(messages: ArrayList(messages))
    }

    /**
     * Converts content to a PromptMessage
     *
     * @param content The content to convert
     * @param role The role of the message sender (default: "assistant")
     * @return PromptMessage instance
     */
    private func toPromptMessage(content: String, role!: String = "assistant"): PromptMessage {
        var res = TextContent(text: content)
        res.type_ = "text"
        PromptMessage(role: role, content: res)
    }
}
