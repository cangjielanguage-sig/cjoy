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
import std.fs.{Path}


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

/**
 * factory interface for creating file serve handlers
 */
public interface JoyFileHandlerFactory {
    /**
     * create a handler to serve a single file
     *
     * @param filePath: the path of the file to serve
     * @return the file serve handler
     */
    func createFileServeHandler(filePath: String): JoyRequestHandler

    /**
     * create a handler to serve a file system directory
     *
     * @param root: the root directory path
     * @param confg: the joy configuration
     * @return the file system serve handler
     */
    func createFileSystemServeHandler(root: Path, confg: JoyConfig): JoyRequestHandler

    /**
     * serve a file to the client
     *
     * @param ctx: the request context
     * @param filePath: the path of the file to serve
     */
    func serveFile(ctx: JoyContext, filePath: Path): Unit

    /**
     * serve a file as attachment for download
     *
     * @param ctx: the request context
     * @param filePath: the path of the file to download
     */
    func downloadFile(ctx: JoyContext, filePath: Path): Unit
}