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
import cjoy.{JoyMiddlewareHandler, JoyRequestHandlerChain, JoyContext}
import cjoy.validation.JoyValidationException
import cjoy.log.macros.*

/**
 * covering catch all exception
 */
public class ExceptionHandler <: JoyMiddlewareHandler {
    public func handle(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
        try {
            chain.next(ctx)
        } catch (ex: Exception) {
            @JoyLogError("handle request occurs an error, message=${ex.message}")
            match (ex) {
                case _: NoneValueException =>
                    // for Option.getOrThrow, Parable.parse
                    ctx.status(HttpStatusCode.STATUS_BAD_REQUEST)
                case _: IllegalArgumentException => ctx.status(HttpStatusCode.STATUS_BAD_REQUEST)
                case e: JoyValidationException => ctx.status(HttpStatusCode.STATUS_BAD_REQUEST).json(e.toMap())
                case _ => ctx.status(HttpStatusCode.STATUS_INTERNAL_SERVER_ERROR)
            }
        }
    }
}
