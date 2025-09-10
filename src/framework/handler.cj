/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.framework

import std.collection.{forEach, ArrayList, HashMap}
import stdx.net.http.{notFound, HttpStatusCode, OptionsHandler}

/**
 * the interface of request handler
 */
public interface JoyRequestHandler {
    /**
     * process the request and reply response using context api
     *
     * @param ctx: the context
     */
    func handle(ctx: JoyContext): Unit
}

// the request handler function
public type JoyRequestHandlerFunc = (ctx: JoyContext) -> Unit

// the filter function 
public type JoyRequestFilterFunc = (ctx: JoyContext) -> Bool

public class JoyFuncHandler <: JoyRequestHandler {
    public JoyFuncHandler(let handler: JoyRequestHandlerFunc) {}

    public func handle(ctx: JoyContext): Unit {
        this.handler(ctx)
    }
}

public class JoyNotFoundHandler <: JoyRequestHandler {
    public func handle(ctx: JoyContext): Unit {
        notFound(ctx.httpContext)
    }
}

public class JoyMethodNotAllowedHandler <: JoyRequestHandler {
    public func handle(ctx: JoyContext): Unit {
        let methods: Collection<String> = ctx.getCtxParam<Collection<String>>("methods").getOrThrow()
        methods |> forEach {val => ctx.header(JoyHttpConsts.HEADER_ALLOW, val)}
        ctx.status(HttpStatusCode.STATUS_METHOD_NOT_ALLOWED)
    }
}

class JoyOptionsHandler <: JoyRequestHandler {
    static let INSTANCE = JoyOptionsHandler()

    public func handle(ctx: JoyContext): Unit {
        OptionsHandler().handle(ctx.httpContext)
    }
}

public class JoyHandlers {
    private static let HANDLERS: ArrayList<(String, Array<String>, JoyRequestHandler)> = ArrayList()

    /**
     * add the handler for generate code by macros
     *
     * @param path: the path
     * @param methods: the methods
     * @param handler: the handler
     */
    public static func addHandler(path: String, methods: Array<String>, handler: JoyRequestHandler) {
        HANDLERS.add((path, methods, handler))
    }

    /**
     * register the handlers to joy instance
     *
     * @param joy: the instance of joy
     */
    public static func registerTo(joy: Joy): Unit {
        for (it in HANDLERS) {
            let (path, methods, handler) = it
            let rg = joy.router.findGroup(path)
            let rpath = path[rg.basePath().size..path.size]
            rg.handle(methods, rpath, handler)
        }
    }
}

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
    public JoyMiddlewareFuncHandler(let handler: (JoyContext, JoyRequestHandlerChain) -> Unit) {}

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
    public static func addHandler(groups: Array<String>, mw: JoyMiddlewareHandler) {
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
