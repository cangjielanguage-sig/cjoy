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

import std.collection.HashMap
import stdx.net.http.HttpStatusCode
import cjoy.{JoyMiddlewareHandler, JoyRequestHandlerChain, JoyContext, JoyHttpConsts}
import cjoy.log.macros.*

 /**
 * 用于过滤是否需要基本认证的函数类型
 */
public type BasicAuthFilterFunc = (ctx: JoyContext) -> Bool

/**
 * 用于验证用户名和密码的函数类型
 */
public type BasicAuthValidationFunc = (ctx: JoyContext, username: String, password: String) -> Bool

/**
 * 基本认证中间件
 */
public class BasicAuth <: JoyMiddlewareHandler {
    public BasicAuth(let realm: String, let creds: HashMap<String, String>,
        let validateFunc!: ?BasicAuthValidationFunc = None, let filterFunc!: ?BasicAuthFilterFunc = None) {}

    public func handle(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
        if (let Some(fn) <- filterFunc) {
            if (fn(ctx)) {
                chain.next(ctx)
                return
            }
        }

        let authInfo = ctx.basicAuth()
        if (authInfo.isNone()) {
            basicAuthFailed(ctx)
            return
        }

        let (user, pwd) = authInfo.getOrThrow()
        if (let Some(fn) <- validateFunc) {
            if (!fn(ctx, user, pwd)) {
                basicAuthFailed(ctx)
                return
            }
            chain.next(ctx)
            return
        }

        let opwd = creds.get(user)
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
        @JoyLogError("[BasicAuth] auth failed, ${ctx.getClientIP()}, ${ctx.method} ${ctx.url}")
        ctx.header(JoyHttpConsts.HEADER_WWW_AUTHENTICATE, "Basic realm=\"${realm}\"")
        ctx.status(HttpStatusCode.STATUS_UNAUTHORIZED)
    }
}
