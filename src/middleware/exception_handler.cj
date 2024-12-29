/*
 * Copyright (c) lanlingx 2024-2024. All rights resvered.
 */

package cjoy.middleware

import std.collection.HashMap
import net.http.HttpStatusCode
import cjoy.{JoyMiddlewareHandler, JoyRequestHandlerChain, JoyContext}

public class ExceptinHandler <: JoyMiddlewareHandler {
    public func handle(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
        try {
            chain.next(ctx)
        } catch (ex: Exception) {
            if (ctx.config.enableDebugLog) {
                ex.printStackTrace()
            }
            ctx.logger.error("handle request occurs an error, message=${ex.message}")
            ctx.error(HttpStatusCode.STATUS_INTERNAL_SERVER_ERROR)
        }
    }
}
