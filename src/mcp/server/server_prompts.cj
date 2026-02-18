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
import cjoy.jsonrpc.{JSONRPCException, JSONRPCError, JSONRPCConsts}

/**
 * MCP 提示管理器类
 *
 * 处理提示的注册、发现和检索。提供添加提示、注册提示处理程序和获取提示内容的方法。
 */
public class McpPrompts {
    /**
     * 用于存储获取提示处理程序的 ConcurrentHashMap
     */
    private let getPromptHandlers: ConcurrentHashMap<String, McpGetPromptHandler> = ConcurrentHashMap()

    /**
     * 用于存储已注册 MCP 提示的 ConcurrentHashMap
     */
    let prompts: ConcurrentHashMap<String, McpPrompt> = ConcurrentHashMap()

    private let _pageSize = 10

    /**
     * 向管理器添加 MCP 提示
     *
     * @param prompt 要添加的 McpPrompt 实例
     */
    public func addPrompt(prompt: McpPrompt): Unit {
        if (prompts.contains(prompt.name)) {
            @JoyLogWarn("[MCP] prompt `${prompt.name}` is existed, will be overwrite")
        }
        prompts.add(prompt.name, prompt)
    }

    /**
     * 为特定提示名称添加获取提示处理程序
     *
     * @param name 要处理的提示名称
     * @param handler McpGetPromptHandler 实现
     */
    public func addGetPromptHandler(name: String, handler: McpGetPromptHandler): Unit {
        getPromptHandlers.add(name, handler)
    }

    /**
     * 列出所有可用的 MCP 提示，支持分页
     *
     * @param page 包含分页游标的 PaginatedRequest
     * @return 包含提示列表和下一个游标的 ListPromptResult
     */
    public func listPrompt(page: PaginatedRequest): ListPromptResult {
        let res: ArrayList<McpPrompt> = ArrayList()

        // 将 ConcurrentHashMap 转换为 ArrayList 以便分页
        for ((_, value) in prompts) {
            res.add(value)
        }

        // 使用统一的分页工具
        let utils = McpPaginationUtils(pageSize: _pageSize)
        let (paginatedRes, nextCursor) = utils.paginate(res, page)

        let result = ListPromptResult(prompts: paginatedRes)
        result.nextCursor = nextCursor
        result
    }

    /**
     * 移除具有给定名称的提示
     *
     * @param names 要移除的提示名称数组
     */
    public func removePrompts(names: Array<String>): Unit {
        for (name in names) {
            prompts.remove(name)
            getPromptHandlers.remove(name)
        }
    }

    /**
     * 移除具有给定名称的单个提示
     *
     * @param name 要移除的提示名称
     */
    public func removePrompt(name: String): Unit {
        removePrompts([name])
    }

    /**
     * 使用给定的请求获取特定的提示
     *
     * @param ctx JoyContext
     * @param req 包含提示名称和参数的 GetPromptRequest
     * @return 包含提示消息的 GetPromptResult
     * @throws Exception 如果找不到提示或处理程序返回未知类型
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
                        let error = JSONRPCError(code: JSONRPCConsts.ERR_INVALID_REQUEST, message: "unknow prompt")
                        throw JSONRPCException(error)
                }
            case _ =>
                @JoyLogError("[MCP] not found prompt handler, name=${req.name}")
                let error = JSONRPCError(code: JSONRPCConsts.ERR_INVALID_REQUEST, message: "not found prompt")
                throw JSONRPCException(error)
                
        }
        GetPromptResult(messages: ArrayList(messages))
    }

    /**
     * 将内容转换为 PromptMessage
     *
     * @param content 要转换的内容
     * @param role 消息发送者的角色（默认："assistant"）
     * @return PromptMessage 实例
     */
    private func toPromptMessage(content: String, role!: String = "assistant"): PromptMessage {
        var res = TextContent(text: content)
        res.type_ = "text"
        PromptMessage(role: role, content: res)
    }
}
