/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.framework

import std.collection.{forEach, HashMap}

/**
 * Request handler chain interface for managing middleware execution
 */
public interface JoyRequestHandlerChain {
    /**
     * Moves to the next handler in the chain
     *
     * @param ctx Request/response context
     */
    func next(ctx: JoyContext): Unit
}

/**
 * Request middleware handler interface for processing HTTP requests
 */
public interface JoyMiddlewareHandler {
    /**
     * Processes the request and optionally passes it to the next middleware in the chain
     *
     * @param ctx Request/response context
     * @param chain Middleware chain for passing the request to the next handler
     */
    func handle(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit
}

/**
 * Type alias for middleware function
 */
public type JoyMiddlewareFunc = (ctx: JoyContext, chain: JoyRequestHandlerChain) -> Unit

/**
 * Function-based middleware handler implementation
 */
public class JoyMiddlewareFuncHandler <: JoyMiddlewareHandler {
    /**
     * Creates a new JoyMiddlewareFuncHandler
     *
     * @param handler The middleware function
     */
    public JoyMiddlewareFuncHandler(let handler: JoyMiddlewareFunc) {}

    /**
     * Processes the request using the middleware function
     *
     * @param ctx Request/response context
     * @param chain Middleware chain for passing the request to the next handler
     */
    public func handle(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
        this.handler(ctx, chain)
    }
}

/**
 * Middleware handler registry for registering route handlers
 */
public class JoyMiddlewares {
    private static let MIDDLEWARES: HashMap<String, JoyMiddlewareHandler> = HashMap()

    /**
     * Adds a middleware handler for code generation by macros
     *
     * @param groups Array of group paths to register the middleware with
     * @param mw Middleware handler to add
     */
    public static func addHandler(groups: Array<String>, mw: JoyMiddlewareHandler): Unit {
        groups |> forEach {group => MIDDLEWARES.add(group, mw)}
    }

    /**
     * Registers all middleware handlers to the Joy engine instance
     *
     * @param joy Joy engine instance to register middleware with
     */
    public static func registerTo(joy: Joy): Unit {
        for ((path, handler) in MIDDLEWARES) {
            let r = joy.router.createGroups(path)
            r.use(handler)
        }
    }
}
