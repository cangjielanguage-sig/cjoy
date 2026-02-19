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

/**
 * 定义一个工具，用于向 LLM 暴露功能
 *
 * @attribute name: 工具名称
 * @attribute description: 工具描述
 */
public macro Tool(attr: Tokens, input: Tokens): Tokens {
    input + parseFunc("Tool", attr, input)
}

/**
 * 工具参数注解，用于标记工具函数的参数
 *
 * @attribute name: 参数名称
 * @attribute description: 参数描述
 * @attribute required: 是否必需，默认为 true
 */
public macro ToolParam(attr: Tokens, input: Tokens): Tokens {
    parseParam("ToolParam", attr, input)
    input
}

/**
 * 定义一个资源，用于向 LLM 暴露功能
 *
 * @attribute name: 资源名称
 * @attribute description: 资源描述
 */
public macro Resource(attr: Tokens, input: Tokens): Tokens {
    input + parseFunc("Resource", attr, input)
}

/**
 * 资源参数注解，用于标记资源函数的参数
 *
 * @attribute name: 参数名称
 * @attribute description: 参数描述
 * @attribute required: 是否必需，默认为 true
 */
public macro ResourceParam(attr: Tokens, input: Tokens): Tokens {
    parseParam("ResourceParam", attr, input)
    input
}

/**
 * 定义一个提示，用于向 LLM 暴露功能
 *
 * @attribute name: 提示名称
 * @attribute description: 提示描述
 */
public macro Prompt(attr: Tokens, input: Tokens): Tokens {
    input + parseFunc("Prompt", attr, input)
}

/**
 * 提示参数注解，用于标记提示函数的参数
 *
 * @attribute name: 参数名称
 * @attribute description: 参数描述
 * @attribute required: 是否必需，默认为 true
 */
public macro PromptParam(attr: Tokens, input: Tokens): Tokens {
    parseParam("PromptParam", attr, input)
    input
}
