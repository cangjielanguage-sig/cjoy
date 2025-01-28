/*
 * Copyright (c) lanlingx 2024-present. All rights resvered.
 */

package cjoy

import std.collection.{forEach, ArrayList, HashMap}
import net.http.{NotFoundHandler, HttpStatusCode}

public interface JoyRequestHandler {
    /**
     * process the request and reply response using context api
     *
     * @param ctx: the context
     */
    func handle(ctx: JoyContext): Unit
}

public class JoyFuncHandler <: JoyRequestHandler {
    public JoyFuncHandler(let handler: (JoyContext) -> Unit) {}

    public func handle(ctx: JoyContext): Unit {
        this.handler(ctx)
    }
}

public class JoyNotFoundHandler <: JoyRequestHandler {
    public func handle(ctx: JoyContext): Unit {
        NotFoundHandler().handle(ctx.httpContext)
    }
}

public class JoyMethodNotAllowedHandler <: JoyRequestHandler {
    public func handle(ctx: JoyContext): Unit {
        let methods: Collection<String> = ctx.getCtxParm<Collection<String>>("methods").getOrThrow()
        methods |> forEach {val => ctx.header("Allow", val)}
        ctx.error(HttpStatusCode.STATUS_METHOD_NOT_ALLOWED)
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

public interface JoyRequestHandlerChain {
    func next(ctx: JoyContext): Unit
}

public interface JoyMiddlewareHandler {
    /**
     * process the request
     *
     * @param ctx: the context
     * @param chain: the chain of Middleware
     */
    func handle(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit
}

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
