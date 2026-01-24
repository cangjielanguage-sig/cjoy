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

import std.time.DateTime
import stdx.log.Logger
import cjoy.{JoyMiddlewareHandler, JoyRequestHandlerChain, JoyContext, JoyRequestFilterFunc}
import cjoy.log.LogTool

/**
 * access log middleware for logging HTTP request information
 */
public class AccessLog <: JoyMiddlewareHandler {
    private let _logger: Logger
    private let _filterFn: ?JoyRequestFilterFunc

    public init(logger!: ?Logger = None, filterFn!: ?JoyRequestFilterFunc = None) {
        if (let Some(l) <- logger) {
            _logger = l
        } else {
            _logger = LogTool.logger
        }
        _filterFn = filterFn
    }

    public func handle(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
        if (_filterFn?(ctx) ?? false) {
            chain.next(ctx)
            return
        }

        let start = DateTime.now()
        try {
            chain.next(ctx)
        } finally {
            let clientIp = ctx.getClientIP()
            let cost = (DateTime.now().toUnixTimeStamp() - start.toUnixTimeStamp())
            _logger.info("[AccessLog] ${clientIp} ${ctx.method} ${ctx.url} ${ctx.respStatus} ${cost}")
        }
    }
}
