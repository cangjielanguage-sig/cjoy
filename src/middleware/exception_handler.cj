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
import cjoy.{JoyMiddlewareHandler, JoyRequestHandlerChain, JoyContext}
import cjoy.validation.JoyValidationException

public class ExceptionHandler <: JoyMiddlewareHandler {
    public func handle(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
        try {
            chain.next(ctx)
        } catch (ex: Exception) {
            if (ctx.config.enableDebugLog) {
                ex.printStackTrace()
            }
            ctx.logger.error("handle request occurs an error, message=${ex.message}")
            match (ex) {
                case e: NoneValueException =>
                    // for Option.getOrThrow, Parable.parse
                    ctx.error(HttpStatusCode.STATUS_BAD_REQUEST)
                case e: IllegalArgumentException =>
                    ctx.error(HttpStatusCode.STATUS_BAD_REQUEST)
                case e: JoyValidationException =>
                    ctx.json(HttpStatusCode.STATUS_BAD_REQUEST, e.toMap())
                case _ => 
                    ctx.error(HttpStatusCode.STATUS_INTERNAL_SERVER_ERROR)
            }
        }
    }
}
