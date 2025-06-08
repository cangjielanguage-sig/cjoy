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
import cjoy.{JoyMiddlewareHandler, JoyRequestHandlerChain, JoyContext}

public class BasicAuth <: JoyMiddlewareHandler {
    public BasicAuth(let realm: String, let creads: HashMap<String, String>) {}

    public func handle(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
        let (user, pwd, ok) = basicAuth(ctx)
        if (!ok) {
            basicAuthFailed(ctx)
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

    private func basicAuth(ctx: JoyContext): (String, String, Bool) {
        let auth = ctx.getHeader("Authorization")
        if (auth.isNone()) {
            return ("", "", false)
        }

        let b64 = auth.getOrThrow().split(" ")
        if (b64.size != 2 || b64[0].trimAscii() != 'Basic') {
            return ("", "", false)
        }

        let decode = fromBase64String(b64[1])
        if (decode.isNone()) {
            return ("", "", false)
        }

        let upStr = String.fromUtf8(decode.getOrThrow())
        let up = upStr.split(":")
        if (up.size != 2) {
            return ("", "", false)
        }

        (up[0], up[1], true)
    }

    private func basicAuthFailed(ctx: JoyContext) {
        ctx.header("WWW-Authenticate", "Basic realm=${realm}").error(HttpStatusCode.STATUS_UNAUTHORIZED)
    }
}
