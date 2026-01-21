/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

macro package cjoy.mcp.macros

import std.ast.Tokens

public macro Tool(attr: Tokens, input: Tokens): Tokens {
    input + parseFunc("Tool", attr, input)
}

public macro ToolParam(attr: Tokens, input: Tokens): Tokens {
    parseParam("ToolParam", attr, input)
    input
}

public macro Resource(attr: Tokens, input: Tokens): Tokens {
    input + parseFunc("Resource", attr, input)
}

public macro ResourceParam(attr: Tokens, input: Tokens): Tokens {
    parseParam("ResourceParam", attr, input)
    input
}

public macro Prompt(attr: Tokens, input: Tokens): Tokens {
    input + parseFunc("Prompt", attr, input)
}

public macro PromptParam(attr: Tokens, input: Tokens): Tokens {
    parseParam("PromptParam", attr, input)
    input
}
