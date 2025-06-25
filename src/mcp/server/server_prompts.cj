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
import cjoy.framework.{Joy, JoyContext, JoyRequestHandler, RouteDistributor, VERSION}
import cjoy.log.LogTool
import cjoy.json.JsonTool

public class McpPrompts {
    private let getPromptHandlers: ConcurrentHashMap<String, McpGetPromptHandler> = ConcurrentHashMap()
    let prompts: ConcurrentHashMap<String, McpPrompt> = ConcurrentHashMap()

    //-----Prompt -----
    public func addPrompt(prompt: McpPrompt): Unit {
        if (prompts.contains(prompt.name)) {
            LogTool.warn("[MCP]prompt `${prompt.name}` is existed, will be overwrite")
        }
        prompts.add(prompt.name, prompt)
    }

    public func addGetPromptHandler(name: String, handler: McpGetPromptHandler) {
        getPromptHandlers.add(name, handler)
    }

    public func listPrompt(page: PaginatedRequest): ListPromptResult {
        let res: ArrayList<McpPrompt> = ArrayList()
        for ((_, value) in prompts) {
            res.add(value)
        }
        ListPromptResult(prompts: res)
    }
}
