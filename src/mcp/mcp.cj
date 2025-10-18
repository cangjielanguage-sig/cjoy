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

// only export mcp server
public import std.collection.{HashMap, ArrayList}
public import cjoy.mcp.server.McpServer
public import cjoy.bind.api.{JoyBindable, JoyBindSource}
public import cjoy.json.*
public import cjoy.jsonrpc.{JSONRPCException, JSONRPCError, JSONRPCConsts}
public import cjoy.mcp.api.{McpCallToolHandler, McpReadResourceHandler, McpGetPromptHandler, McpConsts, McpTool, Audio, 
    Image, McpResource, McpPrompt, PromptArgument, PromptMessage, Message}
public import cjoy.mcp.macros.{Tool, ToolParam, Resource, ResourceParam, Prompt, PromptParam}
