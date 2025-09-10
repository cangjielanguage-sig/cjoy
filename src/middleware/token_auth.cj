/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.middleware

import std.collection.HashMap
import stdx.net.http.HttpStatusCode
import cjoy.{JoyMiddlewareHandler, JoyRequestHandlerChain, JoyContext, JoyHttpConsts, JoyRequestHandler, 
    JoyRequestHandlerFunc, JoyFuncHandler, JoyRequestFilterFunc}
import cjoy.log.LogTool

// the validate function 
public type TokenAuthValidatorFunc = (ctx: JoyContext, token: String) -> Bool

// the authentication function
type AuthFunc = (ctx: JoyContext) -> Bool

// Verify a single token
public class SingleTokenAuthValidator {
    public SingleTokenAuthValidator(let token: String) {
    }

    public func validate(ctx: JoyContext, token: String): Bool {
        this.token == token
    }
}

// the default authentication failure handler 
class DefaultAuthFailureHandler <: JoyRequestHandler {
    static let INSTANCE = DefaultAuthFailureHandler()

    public func handle(ctx: JoyContext): Unit {
        LogTool.error("[TokenAuth] auth failed, ${ctx.getClientIP()}, ${ctx.method} ${ctx.url}")
        ctx.status(HttpStatusCode.STATUS_UNAUTHORIZED)
    }
}

/**
 * token authentication middleware
 */
public class TokenAuth <: JoyMiddlewareHandler {
    private let _errorHandler: JoyRequestHandler
    private let _successHandler: ?JoyRequestHandler
    private let _filterHandler: ?JoyRequestFilterFunc
    private let _authFunc: AuthFunc

    /**
     * @param validator: a function which validates token
     * @param lookupKey: a string in the form of "<source>:<name>" that is used to extract key from the request.
     *      Possible values:
     *       - "header:<name>"
     *       - "query:<name>"
     *       - "form:<name>"
     *       - "param:<name>"
     *       - "cookie:<name>"
     * @param errorHandler: a function which is executed for an invalid key.
     * @param successHandler: a function which is executed for a valid key.
     * @param authSchema: be used in the Authorization header.
     * @param filterHandler: a function to skip middleware.
     */
    public init(validator: TokenAuthValidatorFunc, lookupKey!: String = "header:Authorization",
        errorHandler!: ?JoyRequestHandlerFunc = None, successHandler!: ?JoyRequestHandlerFunc = None,
        authSchema!: String = "Bearer", filterHandler!: ?JoyRequestFilterFunc = None) {
        _errorHandler = if (let Some(h) <- errorHandler) {
            JoyFuncHandler(h)
        } else {
            DefaultAuthFailureHandler.INSTANCE
        }

        _successHandler = if (let Some(h) <- successHandler) {
            JoyFuncHandler(h)
        } else {
            None
        }

        _filterHandler = filterHandler
        _authFunc = createAuthFunc(validator, lookupKey, authSchema)
    }

    public init(token: String, lookupKey!: String = "header:Authorization",
        errorHandler!: ?JoyRequestHandlerFunc = None, successHandler!: ?JoyRequestHandlerFunc = None,
        authSchema!: String = "Bearer", filterHandler!: ?JoyRequestFilterFunc = None) {
        this(SingleTokenAuthValidator(token).validate, lookupKey: lookupKey, errorHandler: errorHandler,
            successHandler: successHandler, authSchema: authSchema, filterHandler: filterHandler)
    }

    public func handle(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
        if (let Some(fn) <- _filterHandler) {
            if (fn(ctx)) {
                chain.next(ctx)
                return
            }
        }

        if (_authFunc(ctx)) {
            _successHandler?.handle(ctx)
            chain.next(ctx)
            return
        } else {
            _errorHandler.handle(ctx)
        }
    }

    private static func createAuthFunc(validator: TokenAuthValidatorFunc, lookupKey: String, authSchema: String): AuthFunc {
        let sn = lookupKey.split(":")
        if (sn.size != 2) {
            throw IllegalArgumentException("lookupKey format must be <source>:<name>")
        }
        match (sn[0]) {
            case "header" => {
                ctx: JoyContext =>
                let value = ctx.getHeader(sn[1])
                if (let Some(v) <- value) {
                    if (!authSchema.isEmpty()) {
                        if (!v.startsWith("${authSchema} ")) {
                            return false
                        }
                        return validator(ctx, v[(authSchema.size + 1)..])
                    }
                    return validator(ctx, v)
                }
                return false
            }
            case "query" => {
                ctx: JoyContext =>
                let value = ctx.getQuery(sn[1])
                if (let Some(v) <- value) {
                    return validator(ctx, v)
                }
                return false
            }
            case "param" => {
                ctx: JoyContext =>
                let value = ctx.getParam(sn[1])
                if (let Some(v) <- value) {
                    return validator(ctx, v)
                }
                return false
            }
            case "form" => {
                ctx: JoyContext =>
                let value = ctx.getPostForm(sn[1])
                if (let Some(v) <- value) {
                    return validator(ctx, v)
                }
                return false
            }
            case "cookie" => {
                ctx: JoyContext =>
                let value = ctx.getCookie(sn[1])
                if (let Some(v) <- value) {
                    return validator(ctx, v)
                }
                return false
            }
            case _ => throw IllegalArgumentException(
                "lookupKey format must be <source>:<name>, source must be one of [header, query, form, param, cookie]")
        }
    }
}
