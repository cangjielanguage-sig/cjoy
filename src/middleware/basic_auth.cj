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
import stdx.encoding.base64.fromBase64String
import cjoy.{JoyMiddlewareHandler, JoyRequestHandlerChain, JoyContext, JoyHttpConsts}
import cjoy.log.*

public type BasicAuthFilterFunc = (ctx: JoyContext) -> Bool

public type BasicAuthValidationFunc = (ctx: JoyContext, username: String, password: String) -> Bool

/**
 * the basic authorization
 */
public class BasicAuth <: JoyMiddlewareHandler {
    public BasicAuth(let realm: String, let creads: HashMap<String, String>,
        let valiateFunc!: ?BasicAuthValidationFunc = None, let filterFunc!: ?BasicAuthFilterFunc = None) {}

    public func handle(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
        if (let Some(fn) <- filterFunc) {
            if (fn(ctx)) {
                chain.next(ctx)
                return
            }
        }

        let (user, pwd, ok) = ctx.basicAuth()
        if (!ok) {
            basicAuthFailed(ctx)
            return
        }

        if (let Some(fn) <- valiateFunc) {
            if (!fn(ctx, user, pwd)) {
                basicAuthFailed(ctx)
                return
            }
            chain.next(ctx)
            return
        }

        let opwd = creads.get(user)
        if (opwd.isNone()) {
            basicAuthFailed(ctx)
            return
        }

        if (opwd.getOrThrow() != pwd) {
            basicAuthFailed(ctx)
            return
        }

        chain.next(ctx)
    }

    private func basicAuthFailed(ctx: JoyContext) {
        @LogError("[BasicAuth] auth failed, ${ctx.getClientIP()}, ${ctx.method} ${ctx.url}")
        ctx.header(JoyHttpConsts.HEADER_WWW_AUTHENTICATE, "Basic realm=${realm}")
        ctx.status(HttpStatusCode.STATUS_UNAUTHORIZED)
    }
}
