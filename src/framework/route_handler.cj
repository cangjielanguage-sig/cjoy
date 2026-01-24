/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.framework

import std.collection.{ArrayList}
import std.collection.concurrent.ConcurrentHashMap
import std.fs.{Path, FileInfo, exists}
import stdx.net.http.{HttpStatusCode, FileHandler}
import cjoy.log.macros.*

class JoyGroupRouteHandler <: JoyRequestHandler {
    static let INSTANCE = JoyGroupRouteHandler()

    public func handle(ctx: JoyContext): Unit {
        // default handle is return not found
        ctx.notFound()
    }
}

class JoyRequestHandlerWrapper <: JoyRequestHandlerChain & JoyRequestHandler {
    public JoyRequestHandlerWrapper(let handler: JoyRequestHandler, let mws: ArrayList<JoyMiddlewareHandler>) {}

    public func handle(ctx: JoyContext): Unit {
        let ctxHttp = (ctx as JoyHttpContext).getOrThrow()
        ctxHttp.resetHandleIndex()
        if (mws.isEmpty()) {
            handler.handle(ctx)
        } else {
            mws[ctxHttp.handleIndex].handle(ctx, this)
        }
    }

    public func next(ctx: JoyContext): Unit {
        let ctxHttp = (ctx as JoyHttpContext).getOrThrow()
        let idx = ctxHttp.addHandleIndex()
        if (idx < mws.size) {
            mws[idx].handle(ctx, this)
            return
        }
        handler.handle(ctx)
    }
}

public interface JoyFileHandlerFactory {
    func createFileServeHandler(filePath: String): JoyRequestHandler
    func createFileSystemServeHandler( root: Path, confg: JoyConfig): JoyRequestHandler
}