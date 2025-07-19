/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.framework

import std.collection.{ArrayList, HashMap, forEach}
import std.collection.concurrent.ConcurrentHashMap
import std.fs.{Path, FileInfo, exists}
import stdx.net.http.{HttpRequestHandler, HttpStatusCode, FileHandler, HttpContext}
import cjoy.log.LogTool

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

class JoyFileServeHandler <: JoyRequestHandler {
    let fileHandler: FileHandler

    public init(filepth: String) {
        fileHandler = FileHandler(filepth)
    }

    public func handle(ctx: JoyContext): Unit {
        fileHandler.handle(ctx.httpContext)
    }
}

class JoyFileSystemServeHandler <: JoyRequestHandler {
    private let cache: ConcurrentHashMap<String, FileHandler> = ConcurrentHashMap()

    public JoyFileSystemServeHandler(let root: Path, let confg: JoyConfig) {}

    public func handle(ctx: JoyContext): Unit {
        let pathOpt = ctx.getParam("*")
        if (let Some(path) <- pathOpt) {
            serves(ctx, path)
        } else {
            confg.notFoundHandler.handle(ctx)
        }
    }

    private func serves(ctx: JoyContext, path: String): Unit {
        if (path.contains("..")) {
            LogTool.warn("[JoyFileSystemServeHandler#handle] url path contain `..`, path=${path}")
            ctx.status(HttpStatusCode.STATUS_BAD_REQUEST)
            return
        }

        let filePath = root.join(path).normalize()
        if (!exists(filePath)) {
            confg.notFoundHandler.handle(ctx)
            return
        }

        let fp = filePath.toString()
        match (cache.get(fp)) {
            case Some(v) => v.handle(ctx.httpContext)
            case _ =>
                let fi = FileInfo(filePath)
                if (fi.isDirectory() || fi.isHidden() || !fi.canRead()) {
                    LogTool.warn("[JoyFileSystemServeHandler#handle] forbidden to donwnload file ${fp}")
                    ctx.status(HttpStatusCode.STATUS_FORBIDDEN)
                    return
                }
                if (!fp.startsWith(root.toString())) {
                    LogTool.warn("[JoyFileSystemServeHandler#handle] forbidden to donwnload file ${fp}")
                    ctx.status(HttpStatusCode.STATUS_FORBIDDEN)
                    return
                }

                let fh = FileHandler(fp)
                cache.addIfAbsent(fp, fh)
                fh.handle(ctx.httpContext)
        }
    }
}
