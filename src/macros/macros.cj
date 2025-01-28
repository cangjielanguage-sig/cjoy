/*
 * Copyright (c) lanlingx 2025-present. All rights resvered.
 */

macro package cjoy.macros

import std.ast.*
import cjoy.macros.generate.{parseParam, ParamCatgory, parseFunc, MethodCatgory, parseMiddlewareFunc}

// reimport the dependent
public import std.convert.*
public import cjoy.{JoyHandlers, JoyRequestHandler, JoyMiddlewares, JoyMiddlewareHandler, JoyRequestHandlerChain}

public macro PathParam(attr: Tokens, input: Tokens) {
    parseParam("PathParam", ParamCatgory.PC_PATH, attr, input)
    input
}

public macro PathParam(input: Tokens) {
    parseParam("PathParam", ParamCatgory.PC_PATH, input)
    input
}

public macro QueryParam(attr: Tokens, input: Tokens) {
    parseParam("QueryParam", ParamCatgory.PC_QUERY, attr, input)
    input
}

public macro QueryParam(input: Tokens) {
    parseParam("QueryParam", ParamCatgory.PC_QUERY, input)
    input
}

public macro PostFormParam(attr: Tokens, input: Tokens) {
    parseParam("PostForm", ParamCatgory.PC_POSTFORM, attr, input)
    input
}

public macro PostFormParam(input: Tokens) {
    parseParam("PostForm", ParamCatgory.PC_POSTFORM, input)
    input
}

public macro HeaderParam(attr: Tokens, input: Tokens) {
    parseParam("HeaderParam", ParamCatgory.PC_HEADER, attr, input)
    input
}

public macro HeaderParam(input: Tokens) {
    parseParam("HeaderParam", ParamCatgory.PC_HEADER, input)
    input
}

public macro ContextParam(attr: Tokens, input: Tokens) {
    parseParam("ContextParam", ParamCatgory.PC_CONTEXT, attr, input)
    input
}

public macro ContextParam(input: Tokens) {
    parseParam("ContextParam", ParamCatgory.PC_CONTEXT, input)
    input
}

public macro CookieParam(attr: Tokens, input: Tokens) {
    parseParam("CookieParam", ParamCatgory.PC_COOKIE, attr, input)
    input
}

public macro CookieParam(input: Tokens) {
    parseParam("CookieParam", ParamCatgory.PC_COOKIE, input)
    input
}

public macro BodyParam(attr: Tokens, input: Tokens) {
    parseParam("BodyParam", ParamCatgory.PC_BODY, attr, input)
    input
}

public macro BodyParam(input: Tokens) {
    parseParam("BodyParam", ParamCatgory.PC_BODY, input)
    input
}

public macro Get(attr: Tokens, input: Tokens) {
    input + parseFunc("Get", MethodCatgory.MC_GET, attr, input)
}

public macro Post(attr: Tokens, input: Tokens) {
    input + parseFunc("Post", MethodCatgory.MC_POST, attr, input)
}

public macro Delete(attr: Tokens, input: Tokens) {
    input + parseFunc("Delete", MethodCatgory.MC_DELETE, attr, input)
}

public macro Patch(attr: Tokens, input: Tokens) {
    input + parseFunc("Patch", MethodCatgory.MC_PATCH, attr, input)
}

public macro Put(attr: Tokens, input: Tokens) {
    input + parseFunc("Put", MethodCatgory.MC_PUT, attr, input)
}

public macro Head(attr: Tokens, input: Tokens) {
    input + parseFunc("Head", MethodCatgory.MC_HEAD, attr, input)
}

public macro Methods(attr: Tokens, input: Tokens) {
    input + parseFunc("Methods", MethodCatgory.MC_METHODS, attr, input)
}

public macro Middleware(attr: Tokens, input: Tokens) {
    input + parseMiddlewareFunc(attr, input)
}

public macro Middleware(input: Tokens) {
    input + parseMiddlewareFunc(None, input)
}
