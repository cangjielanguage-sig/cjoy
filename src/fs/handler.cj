/*
 * Copyright (c) 2026 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 *
 */

package cjoy.fs

import stdx.net.http.{HttpStatusCode}
import cjoy.framework.{JoyFileHandlerFactory, JoyRequestHandler, JoyConfig, JoyContext}
import std.fs.{Path, FileInfo, exists}
import cjoy.ioc.*
import cjoy.ioc.macros.Component
import cjoy.log.macros.*

@JoyCreateLogger("cjoy.eventbus")

@Component[extends = ["JoyFileHandlerFactory"]]
class DefaultJoyFileHandlerFactory <: JoyFileHandlerFactory {
    public func createFileServeHandler(filePath: String): JoyRequestHandler {
        JoyFileServeHandler(filePath)
    }

    public func createFileSystemServeHandler(root: Path, confg: JoyConfig): JoyRequestHandler {
        JoyFileSystemServeHandler(root, confg)
    }
}

class JoyFileServeHandler <: JoyRequestHandler {
    JoyFileServeHandler(let filePath: String) {
    }

    public func handle(ctx: JoyContext): Unit {
        JoyFileServer.serveFile(ctx, Path(filePath))
    }
}

class JoyFileSystemServeHandler <: JoyRequestHandler {
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
            @JoyLogWarn("url path contain `..`, path=${path}")
            ctx.status(HttpStatusCode.STATUS_BAD_REQUEST)
            return
        }

        let filePath = root.join(path).normalize()
        if (!exists(filePath)) {
            confg.notFoundHandler.handle(ctx)
            return
        }

        let fi = FileInfo(filePath)
        if (fi.isDirectory() || fi.isHidden() || !fi.canRead()) {
            @JoyLogWarn("forbidden to donwnload file ${filePath}")
            ctx.status(HttpStatusCode.STATUS_FORBIDDEN)
            return
        }

        let fp = filePath.toString()
        if (!fp.startsWith(root.toString())) {
            @JoyLogWarn("forbidden to donwnload file ${filePath}")
            ctx.status(HttpStatusCode.STATUS_FORBIDDEN)
            return
        }

        JoyFileServer.serveFile(ctx, filePath)
    }
}
