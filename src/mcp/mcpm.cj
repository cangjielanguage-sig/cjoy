/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

macro package cjoy.mcp

import std.ast.Tokens
import cjoy.mcp.generate.{parseFunc, parseParam}

// only export mcp server
public import std.collection.{HashMap, ArrayList}
public import cjoy.mcp.server.McpServer
public import cjoy.mcp.common.McpCallToolHandler
public import cjoy.mcp.schema.{McpException, JSONRPCError, McpConsts, Tool as McpTool}
public import cjoy.json.*

public macro Tool(attr: Tokens, input: Tokens): Tokens {
    input + parseFunc("Tool", attr, input)
}

public macro ToolParam(attr: Tokens, input: Tokens): Tokens {
    parseParam("ToolParam", attr, input)
    input
}
