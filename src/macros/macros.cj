/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

macro package cjoy.macros

import std.ast.Tokens
import cjoy.macros.generate.{parseParam, ParamCatgory, parseFunc, MethodCatgory, parseMiddlewareFunc}

// reimport the dependent
public import std.convert.Parsable
public import cjoy.{JoyHandlers, JoyRequestHandler, JoyMiddlewares, JoyMiddlewareHandler, JoyRequestHandlerChain}
public import cjoy.bind.api.{JoyBindable, JoyBindSource}

/**
 * PathParam macro is used for annotation at the paramter of function
 * which value from named paramter in url path.
 *
 * @attribute name: the name of paramter in url path
 */
public macro PathParam(attr: Tokens, input: Tokens) {
    parseParam(ParamCatgory.PC_PATH, attr, input)
    input
}

/**
 * PathParam macro is used for annotation at the paramter of function
 * which value from named paramter in url path.
 * The paramter name of function is the same as named paramter in path.
 *
 */
public macro PathParam(input: Tokens) {
    parseParam(ParamCatgory.PC_PATH, input)
    input
}

/**
 * QueryParam macro is used for annotation at the paramter of function
 * which value from named paramter in url query.
 *
 * @attribute name: the name of paramter in url query
 * @attribute default: the default value of parameter
 */
public macro QueryParam(attr: Tokens, input: Tokens) {
    parseParam(ParamCatgory.PC_QUERY, attr, input)
    input
}

/**
 * QueryParam macro is used for annotation at the paramter of function
 * which value from named paramter in url query.
 * The paramter name of function is the same as paramter name in query.
 *
 */
public macro QueryParam(input: Tokens) {
    parseParam(ParamCatgory.PC_QUERY, input)
    input
}

/**
 * QueryParam macro is used for annotation at the paramter of function
 * which value from paramters in url query.
 *
 */
public macro QueryBindParam(input: Tokens) {
    parseParam(ParamCatgory.PC_QUERY_BIND, input)
    input
}

/**
 * PostFormParam macro is used for annotation at the paramter of function
 * which value from named paramter in encoded url or post form.
 *
 * @attribute name: the name of paramter in encoded url or post form
 * @attribute default: the default value of parameter
 */
public macro PostFormParam(attr: Tokens, input: Tokens) {
    parseParam(ParamCatgory.PC_POSTFORM, attr, input)
    input
}

/**
 * PostFormParam macro is used for annotation at the paramter of function
 * which value from named paramter in encoded url or post form.
 * The paramter name of function is the same as paramter name in encoded url or post form.
 *
 */
public macro PostFormParam(input: Tokens) {
    parseParam(ParamCatgory.PC_POSTFORM, input)
    input
}

/**
 * PostFormParam macro is used for annotation at the paramter of function
 * which value from paramters in encoded url or post form. 
 */
public macro PostFormBindParam(input: Tokens) {
    parseParam(ParamCatgory.PC_POSTFORM_BIND, input)
    input
}

/**
 * HeaderParam macro is used for annotation at the paramter of function
 * which value from named paramter in header.
 *
 * @attribute name: the name of paramter in header
 * @attribute default: the default value of parameter
 */
public macro HeaderParam(attr: Tokens, input: Tokens) {
    parseParam(ParamCatgory.PC_HEADER, attr, input)
    input
}

/**
 * HeaderParam macro is used for annotation at the paramter of function
 * which value from named paramter in header.
 * The paramter name of function is the same as paramter name in header.
 *
 */
public macro HeaderParam(input: Tokens) {
    parseParam(ParamCatgory.PC_HEADER, input)
    input
}

/**
 * HeaderParam macro is used for annotation at the paramter of function
 * which value from paramters in header.
 *
 */
public macro HeaderBindParam(input: Tokens) {
    parseParam(ParamCatgory.PC_HEADER_BIND, input)
    input
}

/**
 * ContextParam macro is used for annotation at the paramter of function
 * which value from named paramter in context.
 *
 * @attribute name: the name of paramter in context
 */
public macro ContextParam(attr: Tokens, input: Tokens) {
    parseParam(ParamCatgory.PC_CONTEXT, attr, input)
    input
}

/**
 * ContextParam macro is used for annotation at the paramter of function
 * which value from named paramter in context.
 * The paramter name of function is the same as paramter name in context.
 *
 */
public macro ContextParam(input: Tokens) {
    parseParam(ParamCatgory.PC_CONTEXT, input)
    input
}

/**
 * CookieParam macro is used for annotation at the paramter of function
 * which value from named paramter in cookie.
 *
 * @attribute name: the name of paramter in cookie
 * @attribute default: the default value of parameter
 */
public macro CookieParam(attr: Tokens, input: Tokens) {
    parseParam(ParamCatgory.PC_COOKIE, attr, input)
    input
}

/**
 * CookieParam macro is used for annotation at the paramter of function
 * which value from named paramter in cookie.
 * The paramter name of function is the same as paramter name in cookie.
 *
 */
public macro CookieParam(input: Tokens) {
    parseParam(ParamCatgory.PC_COOKIE, input)
    input
}

/**
 * BodyParam macro is used for annotation at the paramter of function
 * which value from body.
 *
 */
public macro BodyParam(attr: Tokens, input: Tokens) {
    parseParam(ParamCatgory.PC_BODY, attr, input)
    input
}

/**
 * BodyParam macro is used for annotation at the paramter of function
 * which value from body.
 *
 */
public macro BodyParam(input: Tokens) {
    parseParam(ParamCatgory.PC_BODY, input)
    input
}

/**
 * Get macro is used for annotation at the function, register the funtion for GET `path`
 *
 * @attribute path: the path pattern
 * @attribute produce: the format of reponse body, value is json/text, default is text
 */
public macro Get(attr: Tokens, input: Tokens) {
    input + parseFunc("Get", MethodCatgory.MC_GET, attr, input)
}

/**
 * Post macro is used for annotation at the function, register the funtion for POST `path`
 *
 * @attribute path: the path pattern
 * @attribute produce: the format of reponse body, value is json/text, default is text
 */
public macro Post(attr: Tokens, input: Tokens) {
    input + parseFunc("Post", MethodCatgory.MC_POST, attr, input)
}

/**
 * Delete macro is used for annotation at the function, register the funtion for DELETE `path`
 *
 * @attribute path: the path pattern
 * @attribute produce: the format of reponse body, value is json/text, default is text
 */
public macro Delete(attr: Tokens, input: Tokens) {
    input + parseFunc("Delete", MethodCatgory.MC_DELETE, attr, input)
}

/**
 * Patch macro is used for annotation at the function, register the funtion for PATCH `path`
 *
 * @attribute path: the path pattern
 * @attribute produce: the format of reponse body, value is json/text, default is text
 */
public macro Patch(attr: Tokens, input: Tokens) {
    input + parseFunc("Patch", MethodCatgory.MC_PATCH, attr, input)
}

/**
 * Put macro is used for annotation at the function, register the funtion for PUT `path`
 *
 * @attribute path: the path pattern
 * @attribute produce: the format of reponse body, value is json/text, default is text
 */
public macro Put(attr: Tokens, input: Tokens) {
    input + parseFunc("Put", MethodCatgory.MC_PUT, attr, input)
}

/**
 * Head macro is used for annotation at the function, register the funtion for HEAD `path`
 *
 * @attribute path: the path pattern
 * @attribute produce: the format of reponse body, value is json/text, default is text
 */
public macro Head(attr: Tokens, input: Tokens) {
    input + parseFunc("Head", MethodCatgory.MC_HEAD, attr, input)
}

/**
 * Handler macro is used for annotation at the function, register the funtion for `method path`
 *
 * @attribute path: the path pattern
 * @attribute methods: the method list, like `GET,PUT` or `GET`
 * @attribute produce: the format of reponse body, value is json/text, default is text
 */
public macro Handler(attr: Tokens, input: Tokens) {
    input + parseFunc("Handler", MethodCatgory.MC_HANDLER, attr, input)
}

/**
 * Methods macro is used for annotation at the function,
 * register the funtion to intercept group handler
 *
 * @attribute groups: the group list, like `/a/b/c,/d/f` or `/a`
 */
public macro Middleware(attr: Tokens, input: Tokens) {
    input + parseMiddlewareFunc(attr, input)
}

/**
 * Methods macro is used for annotation at the function,
 * register the funtion to intercept route group handler
 *
 */
public macro Middleware(input: Tokens) {
    input + parseMiddlewareFunc(None, input)
}
