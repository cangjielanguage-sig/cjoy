/*
 * Copyright (c) lanlingx 2025-present. All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy

import std.collection.{ArrayList, HashMap, forEach}
import std.collection.concurrent.ConcurrentHashMap
import std.fs.*
import net.http.*


/**
* the instance of class will add to object pool
*/
class JoyRouteHandler <: HttpRequestHandler {
    var handler: JoyRequestHandler // JoyRequestHandlerWrapper
    let paramMap: HashMap<String, String>
    let ctxParamMap: HashMap<String, Any>
    let joyCtx: JoyContext

    init(config: JoyConfig) {
        this.handler = unsafe { zeroValue<JoyRequestHandler>() }
        this.paramMap = HashMap()
        this.ctxParamMap = HashMap()
        this.joyCtx = JoyContext(unsafe { zeroValue<HttpContext>() }, paramMap, config, ctxParamMap)
    }

    public func handle(ctx: HttpContext): Unit {
        this.joyCtx._httpContext = ctx
        handler.handle(this.joyCtx)
    }

    /**
    * reset when get from the object pool 
    */
    static func reset(obj: JoyRouteHandler): JoyRouteHandler {
        obj.paramMap.clear()
        obj.ctxParamMap.clear()
        obj.joyCtx.reset()
        return obj
    }
}

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
        ctx._handlerIndex = 0
        if (mws.isEmpty()) {
            handler.handle(ctx)
        } else {
            mws[ctx._handlerIndex].handle(ctx, this)
        }
    }

    public func next(ctx: JoyContext): Unit {
        ctx._handlerIndex += 1
        if (ctx._handlerIndex < mws.size) {
            mws[ctx._handlerIndex].handle(ctx, this)
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
            confg.logger.warn("[JoyFileSystemServeHandler#handle] url path contain `..`, path=${path}")
            ctx.error(HttpStatusCode.STATUS_BAD_REQUEST)
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
                    confg.logger.warn("[JoyFileSystemServeHandler#handle] forbidden to donwnload file ${fp}")
                    ctx.error(HttpStatusCode.STATUS_FORBIDDEN)
                    return
                }
                if (!fp.startsWith(root.toString())) {
                    confg.logger.warn("[JoyFileSystemServeHandler#handle] forbidden to donwnload file ${fp}")
                    ctx.error(HttpStatusCode.STATUS_FORBIDDEN)
                    return
                }

                let fh = FileHandler(fp)
                cache.putIfAbsent(fp, fh)
                fh.handle(ctx.httpContext)
        }
    }
}
