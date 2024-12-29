/*
 * Copyright (c) lanlingx 2024-2024. All rights resvered.
 */

package cjoy

public interface JoyRequestHandler {
    func handle(ctx: JoyContext): Unit
}

public class JoyFuncHandler <: JoyRequestHandler {
    public JoyFuncHandler(let handler: (JoyContext) -> Unit) {}

    public func handle(ctx: JoyContext): Unit {
        this.handler(ctx)
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
