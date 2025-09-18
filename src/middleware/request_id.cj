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

import std.convert.Formattable
import std.sync.AtomicUInt64
import cjoy.{JoyMiddlewareHandler, JoyRequestHandlerChain, JoyContext}
import cjoy.utils.secureRandStr

const requestIdCtxKey = "__request_id__"

/**
 * get request id from context
 */
public func getRequestId(ctx: JoyContext): ?String {
    ctx.getCtxParam(requestIdCtxKey)
}

/**
 * the request id middleware, it will obtain or generate one request id
 */
public class RequestId <: JoyMiddlewareHandler {
    private let _prefix: String
    private let _headerName: String
    private let _id: AtomicUInt64 = AtomicUInt64(0)

    public init(prefix!: String = "", headerName!: String = "X-Request-Id") {
        _prefix = if (prefix != "") {
            prefix
        } else {
            secureRandStr(8)
        }
        _headerName = headerName
    }

    public func handle(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
        let reqId = ctx.getHeader(_headerName)
        if (let Some(id) <- reqId) {
            ctx.setCtxParam(requestIdCtxKey, id)
        } else {
            let id = "${_prefix}-${_id.fetchAdd(1).format("06")}"
            ctx.setCtxParam(requestIdCtxKey, id)
            ctx.header(_headerName, id)
        }

        chain.next(ctx)
    }
}
