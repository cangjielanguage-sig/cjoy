/*
 * Copyright (c) lanlingx 2024-present. All rights resvered.
 */

package cjoy

import std.collection.forEach
import net.http.{NotFoundHandler, HttpStatusCode}

public interface JoyRequestHandler {
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

public interface JoyRequestHandlerChain {
    func next(ctx: JoyContext): Unit
}

public interface JoyMiddlewareHandler {
    func handle(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit
}

public class JoyMiddlewareFuncHandler <: JoyMiddlewareHandler {
    public JoyMiddlewareFuncHandler(let handler: (JoyContext, JoyRequestHandlerChain) -> Unit) {}

    public func handle(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
        this.handler(ctx, chain)
    }
}
