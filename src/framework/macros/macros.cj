/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

macro package cjoy.framework.macros

import std.ast.Tokens

/**
 * PathParam 宏用于在函数参数上注解，其值来自 URL 路径中的命名参数。
 *
 * @attribute name URL 路径中的参数名称
 */
public macro PathParam(attr: Tokens, input: Tokens) {
    parseParam("PathParam", attr, input)
    input
}

/**
 * PathParam 宏用于在函数参数上注解，其值来自 URL 路径中的命名参数。
 * 函数参数名称与路径中的命名参数相同。
 *
 */
public macro PathParam(input: Tokens) {
    parseParam("PathParam", input)
    input
}

/**
 * QueryParam 宏用于在函数参数上注解，其值来自 URL 查询中的命名参数。
 *
 * @attribute name URL 查询中的参数名称
 * @attribute default 参数的默认值
 */
public macro QueryParam(attr: Tokens, input: Tokens) {
    parseParam("QueryParam", attr, input)
    input
}

/**
 * QueryParam 宏用于在函数参数上注解，其值来自 URL 查询中的命名参数。
 * 函数参数名称与查询中的参数名称相同。
 *
 */
public macro QueryParam(input: Tokens) {
    parseParam("QueryParam", input)
    input
}

/**
 * QueryBindParam 宏用于在函数参数上注解，其值来自 URL 查询中的参数。
 *
 */
public macro QueryBindParam(input: Tokens) {
    parseParam("QueryBindParam", input)
    input
}

/**
 * PostFormParam 宏用于在函数参数上注解，其值来自编码 URL 或 POST 表单中的命名参数。
 *
 * @attribute name 编码 URL 或 POST 表单中的参数名称
 * @attribute default 参数的默认值
 */
public macro PostFormParam(attr: Tokens, input: Tokens) {
    parseParam("PostFormParam", attr, input)
    input
}

/**
 * PostFormParam 宏用于在函数参数上注解，其值来自编码 URL 或 POST 表单中的命名参数。
 * 函数参数名称与编码 URL 或 POST 表单中的参数名称相同。
 *
 */
public macro PostFormParam(input: Tokens) {
    parseParam("PostFormParam", input)
    input
}

/**
 * PostFormBindParam 宏用于在函数参数上注解，其值来自编码 URL 或 POST 表单中的参数。
 */
public macro PostFormBindParam(input: Tokens) {
    parseParam("PostFormBindParam", input)
    input
}

/**
 * HeaderParam 宏用于在函数参数上注解，其值来自请求头中的命名参数。
 *
 * @attribute name 请求头中的参数名称
 * @attribute default 参数的默认值
 */
public macro HeaderParam(attr: Tokens, input: Tokens) {
    parseParam("HeaderParam", attr, input)
    input
}

/**
 * HeaderParam 宏用于在函数参数上注解，其值来自请求头中的命名参数。
 * 函数参数名称与请求头中的参数名称相同。
 *
 */
public macro HeaderParam(input: Tokens) {
    parseParam("HeaderParam", input)
    input
}

/**
 * HeaderBindParam 宏用于在函数参数上注解，其值来自请求头中的参数。
 *
 */
public macro HeaderBindParam(input: Tokens) {
    parseParam("HeaderBindParam", input)
    input
}

/**
 * ContextParam 宏用于在函数参数上注解，其值来自上下文中的命名参数。
 *
 * @attribute name 上下文中的参数名称
 */
public macro ContextParam(attr: Tokens, input: Tokens) {
    parseParam("ContextParam", attr, input)
    input
}

/**
 * ContextParam 宏用于在函数参数上注解，其值来自上下文中的命名参数。
 * 函数参数名称与上下文中的参数名称相同。
 *
 */
public macro ContextParam(input: Tokens) {
    parseParam("ContextParam", input)
    input
}

/**
 * CookieParam 宏用于在函数参数上注解，其值来自 Cookie 中的命名参数。
 *
 * @attribute name Cookie 中的参数名称
 * @attribute default 参数的默认值
 */
public macro CookieParam(attr: Tokens, input: Tokens) {
    parseParam("CookieParam", attr, input)
    input
}

/**
 * CookieParam 宏用于在函数参数上注解，其值来自 Cookie 中的命名参数。
 * 函数参数名称与 Cookie 中的参数名称相同。
 *
 */
public macro CookieParam(input: Tokens) {
    parseParam("CookieParam", input)
    input
}

/**
 * BodyParam 宏用于在函数参数上注解，其值来自请求体。
 *
 */
public macro BodyParam(attr: Tokens, input: Tokens) {
    parseParam("BodyParam", attr, input)
    input
}

/**
 * BodyParam 宏用于在函数参数上注解，其值来自请求体。
 *
 */
public macro BodyParam(input: Tokens) {
    parseParam("BodyParam", input)
    input
}

/**
 * Get 宏用于在函数上注解，为 GET `path` 注册函数
 *
 * @attribute path 路径模式
 * @attribute produce 响应体格式，值为 json/text，默认为 text
 */
public macro Get(attr: Tokens, input: Tokens) {
    input + parseFunc("Get", attr, input)
}

/**
 * Post 宏用于在函数上注解，为 POST `path` 注册函数
 *
 * @attribute path 路径模式
 * @attribute produce 响应体格式，值为 json/text，默认为 text
 */
public macro Post(attr: Tokens, input: Tokens) {
    input + parseFunc("Post", attr, input)
}

/**
 * Delete 宏用于在函数上注解，为 DELETE `path` 注册函数
 *
 * @attribute path 路径模式
 * @attribute produce 响应体格式，值为 json/text，默认为 text
 */
public macro Delete(attr: Tokens, input: Tokens) {
    input + parseFunc("Delete", attr, input)
}

/**
 * Patch 宏用于在函数上注解，为 PATCH `path` 注册函数
 *
 * @attribute path 路径模式
 * @attribute produce 响应体格式，值为 json/text，默认为 text
 */
public macro Patch(attr: Tokens, input: Tokens) {
    input + parseFunc("Patch", attr, input)
}

/**
 * Put 宏用于在函数上注解，为 PUT `path` 注册函数
 *
 * @attribute path 路径模式
 * @attribute produce 响应体格式，值为 json/text，默认为 text
 */
public macro Put(attr: Tokens, input: Tokens) {
    input + parseFunc("Put", attr, input)
}

/**
 * Head 宏用于在函数上注解，为 HEAD `path` 注册函数
 *
 * @attribute path 路径模式
 * @attribute produce 响应体格式，值为 json/text，默认为 text
 */
public macro Head(attr: Tokens, input: Tokens) {
    input + parseFunc("Head", attr, input)
}

/**
 * Handler 宏用于在函数上注解，为 `method path` 注册函数
 *
 * @attribute path 路径模式
 * @attribute methods 方法列表，如 `GET,PUT` 或 `GET`
 * @attribute produce 响应体格式，值为 json/text，默认为 text
 */
public macro Handler(attr: Tokens, input: Tokens) {
    input + parseFunc("Handler", attr, input)
}

/**
 * Middleware 宏用于在函数上注解，
 * 注册函数以拦截组处理器
 *
 * @attribute groups 组列表，如 `/a/b/c,/d/f` 或 `/a`
 */
public macro Middleware(attr: Tokens, input: Tokens) {
    input + parseMiddlewareFunc(attr, input)
}

/**
 * Middleware 宏用于在函数上注解，
 * 注册函数以拦截路由组处理器
 *
 */
public macro Middleware(input: Tokens) {
    input + parseMiddlewareFunc(None, input)
}
