/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.middleware

import stdx.net.http.HttpStatusCode
import cjoy.{JoyMiddlewareHandler, JoyRequestHandlerChain, JoyContext, JoyHttpConsts, JoyRequestHandler, 
    JoyRequestHandlerFunc, JoyFuncHandler, JoyRequestFilterFunc}
import cjoy.log.macros.*

// the validate function 
public type TokenAuthValidatorFunc = (ctx: JoyContext, token: String) -> Bool

// the authentication function
type AuthFunc = (ctx: JoyContext) -> Bool

// Predefined tokens
class PredefinedTokenAuthValidator {
    public PredefinedTokenAuthValidator(let tokens: Array<String>) {
    }

    public func validate(_: JoyContext, token: String): Bool {
        this.tokens.contains(token)
    }
}

// the default authentication failure handler 
class DefaultAuthFailureHandler <: JoyRequestHandler {
    static let INSTANCE = DefaultAuthFailureHandler()

    public func handle(ctx: JoyContext): Unit {
        @JoyLogError("[TokenAuth] auth failed, ${ctx.getClientIP()}, ${ctx.method} ${ctx.url}")
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
     * @param errorHandleFunc: a function which is executed for an invalid key.
     * @param successHandleFunc: a function which is executed for a valid key.
     * @param authSchema: be used in the Authorization header.
     * @param filterHandleFunc: a function to skip middleware.
     */
    public init(validator: TokenAuthValidatorFunc, lookupKey!: String = "header:Authorization",
        errorHandleFunc!: ?JoyRequestHandlerFunc = None, successHandleFunc!: ?JoyRequestHandlerFunc = None,
        authSchema!: String = "Bearer", filterHandleFunc!: ?JoyRequestFilterFunc = None) {
        _errorHandler = if (let Some(h) <- errorHandleFunc) {
            JoyFuncHandler(h)
        } else {
            DefaultAuthFailureHandler.INSTANCE
        }

        _successHandler = if (let Some(h) <- successHandleFunc) {
            JoyFuncHandler(h)
        } else {
            None
        }

        _filterHandler = filterHandleFunc
        _authFunc = createAuthFunc(validator, lookupKey, authSchema)
    }

    public init(tokens: Array<String>, lookupKey!: String = "header:Authorization",
        errorHandleFunc!: ?JoyRequestHandlerFunc = None, successHandleFunc!: ?JoyRequestHandlerFunc = None,
        authSchema!: String = "Bearer", filterHandleFunc!: ?JoyRequestFilterFunc = None) {
        this(PredefinedTokenAuthValidator(tokens).validate, lookupKey: lookupKey, errorHandleFunc: errorHandleFunc,
            successHandleFunc: successHandleFunc, authSchema: authSchema, filterHandleFunc: filterHandleFunc)
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

    /**
     * @throws IllegalArgumentException
     */
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
            case "query" | "param" | "form" | "cookie" => {
                ctx: JoyContext =>
                    let value = ctx.getRequestParam(sn[0], sn[1])
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
