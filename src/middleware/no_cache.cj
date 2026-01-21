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

import cjoy.{JoyMiddlewareHandler, JoyRequestHandlerChain, JoyContext, JoyHttpConsts}

/**
 * disable http cache
 */
public class NoCache <: JoyMiddlewareHandler {
    private let _etags = [JoyHttpConsts.HEADER_ETAG, JoyHttpConsts.HEADER_IF_MODIFIED_SINCE,
        JoyHttpConsts.HEADER_IF_MATCH, JoyHttpConsts.HEADER_IF_NONE_MATCH, JoyHttpConsts.HEADER_IF_RANGE,
        "If-Unmodified-Since"]

    public func handle(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
        let headers = ctx.httpContext.request.headers
        for (h in _etags) {
            if (headers.getFirst(h).isSome()) {
                headers.del(h)
            }
        }

        ctx.header(JoyHttpConsts.HEADER_EXPIRES, "Thu, 01 Jan 1970 00:00:00 GMT")
        ctx.header(JoyHttpConsts.HEADER_CACHE_CONTROL,
            "no-cache, no-store, no-transform, must-revalidate, private, max-age=0")
        ctx.header(JoyHttpConsts.HEADER_PRAGMA, "no-cache")
        ctx.header("X-Accel-Expires", "0")
        chain.next(ctx)
    }
}
