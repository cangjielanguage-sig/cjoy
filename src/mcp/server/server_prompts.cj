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
import cjoy.framework.JoyContext
import cjoy.log.macros.*
import cjoy.json.JsonTool

/**
 * manages MCP prompts
 */
public class McpPrompts {
    private let getPromptHandlers: ConcurrentHashMap<String, McpGetPromptHandler> = ConcurrentHashMap()
    let prompts: ConcurrentHashMap<String, McpPrompt> = ConcurrentHashMap()

    //-----Prompt -----
    public func addPrompt(prompt: McpPrompt): Unit {
        if (prompts.contains(prompt.name)) {
            @JoyLogWarn("[MCP] prompt `${prompt.name}` is existed, will be overwrite")
        }
        prompts.add(prompt.name, prompt)
    }

    public func addGetPromptHandler(name: String, handler: McpGetPromptHandler): Unit {
        getPromptHandlers.add(name, handler)
    }

    public func listPrompt(page: PaginatedRequest): ListPromptResult {
        let res: ArrayList<McpPrompt> = ArrayList()
        for ((_, value) in prompts) {
            res.add(value)
        }
        ListPromptResult(prompts: res)
    }

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

    private func toPromptMessage(content: String, role!: String = "assistant"): PromptMessage {
        var res = TextContent(text: content)
        res.type_ = "text"
        PromptMessage(role: role, content: res)
    }
}
