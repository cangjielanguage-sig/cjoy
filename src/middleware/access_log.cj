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

import std.time.DateTime
import stdx.log.Logger
import cjoy.{JoyMiddlewareHandler, JoyRequestHandlerChain, JoyContext}
import cjoy.log.LogTool

public type LogFilterFunc = (ctx: JoyContext) -> Bool

public class AccessLog <: JoyMiddlewareHandler {
    private let _logger: Logger
    private let _filterFn: ?LogFilterFunc

    public init(logger!: ?Logger = None, filterFn!: ?LogFilterFunc = None) {
        if (let Some(l) <- logger) {
            _logger = l
        } else {
            _logger = LogTool.logger
        }
        _filterFn = filterFn
    }

    public func handle(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
        let start = DateTime.now()
        try {
            chain.next(ctx)
        } finally {
            if (_filterFn?(ctx) ?? false) {
                return
            }

            let clintIp = ctx.getClientIP()
            let cost = (DateTime.now().toUnixTimeStamp() - start.toUnixTimeStamp()).toMicroseconds()
            _logger.info("[AccessLog] ${clintIp} ${ctx.method} ${ctx.httpContext.request.url} ${ctx.respStatus} ${cost}ms")
        }
    }
}
