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

public interface JoyMiddlewareHandler {
    func next(handler: JoyRequestHandler): JoyRequestHandler
}

public class JoyMiddlewareFuncHandler <: JoyMiddlewareHandler {
    public JoyMiddlewareFuncHandler(let handler: (JoyRequestHandler) -> JoyRequestHandler) {}

    public func next(handler: JoyRequestHandler): JoyRequestHandler {
        this.next(handler)
    }
}