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

import std.collection.{forEach, ArrayList, HashMap}

/**
 * the interface of request handler chain
 */
public interface JoyRequestHandlerChain {
    /**
     * move next handler
     *
     * @param ctx: the context
     */
    func next(ctx: JoyContext): Unit
}

/**
 * the interface of request middleware handler
 */
public interface JoyMiddlewareHandler {
    /**
     * process the request
     *
     * @param ctx: the context
     * @param chain: the chain of Middleware
     */
    func handle(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit
}

public type JoyMiddlewareFunc = (ctx: JoyContext, chain: JoyRequestHandlerChain) -> Unit

public class JoyMiddlewareFuncHandler <: JoyMiddlewareHandler {
    public JoyMiddlewareFuncHandler(let handler: JoyMiddlewareFunc) {}

    public func handle(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
        this.handler(ctx, chain)
    }
}

public class JoyMiddlewares {
    private static let MIDDLEWARES: HashMap<String, JoyMiddlewareHandler> = HashMap()

    /**
     * add the handler for generate code by macros
     *
     * @param group: the path of group
     * @param mw: the middleware hander
     */
    public static func addHandler(groups: Array<String>, mw: JoyMiddlewareHandler): Unit {
        groups |> forEach {group => MIDDLEWARES.add(group, mw)}
    }

    /**
     * register the middleware handlers to joy instance
     *
     * @param joy: the instance of joy
     */
    public static func registerTo(joy: Joy): Unit {
        for ((path, handler) in MIDDLEWARES) {
            let r = joy.router.createGroups(path)
            r.use(handler)
        }
    }
}
