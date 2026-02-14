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

/**
 * Default implementation of JoyFileHandlerFactory
 */
@Component[extends = ["JoyFileHandlerFactory"]]
class DefaultJoyFileHandlerFactory <: JoyFileHandlerFactory {
    /**
     * Creates a file serve handler for the given file path
     *
     * @param filePath The file path to serve
     * @return A JoyRequestHandler for serving the file
     */
    public func createFileServeHandler(filePath: String): JoyRequestHandler {
        JoyFileServeHandler(filePath)
    }

    /**
     * Creates a file system serve handler for the given root path
     *
     * @param root The root path of the file system to serve
     * @param confg The JoyConfig instance
     * @return A JoyRequestHandler for serving the file system
     */
    public func createFileSystemServeHandler(root: Path, confg: JoyConfig): JoyRequestHandler {
        JoyFileSystemServeHandler(root, confg)
    }

    /**
     * Serves a file from the given file path
     *
     * @param ctx The JoyContext instance
     * @param filePath The path of the file to serve
     */
    public func serveFile(ctx: JoyContext, filePath: Path): Unit {
        JoyFileServer.serveFile(ctx, filePath)
    }

    /**
     * Downloads a file as an attachment
     *
     * @param ctx The JoyContext instance
     * @param filePath The path of the file to download
     */
    public func downloadFile(ctx: JoyContext, filePath: Path): Unit {
        downloadAttachment(ctx, filePath)
    }
}

/**
 * JoyRequestHandler for serving a single file
 */
class JoyFileServeHandler <: JoyRequestHandler {
    /**
     * Creates a new JoyFileServeHandler instance
     *
     * @param filePath The path of the file to serve
     */
    JoyFileServeHandler(let filePath: String) {
    }

    /**
     * Handles the request to serve the file
     *
     * @param ctx The JoyContext instance
     */
    public func handle(ctx: JoyContext): Unit {
        JoyFileServer.serveFile(ctx, Path(filePath))
    }
}

/**
 * JoyRequestHandler for serving a file system directory
 */
class JoyFileSystemServeHandler <: JoyRequestHandler {
    /**
     * Creates a new JoyFileSystemServeHandler instance
     *
     * @param root The root path of the file system to serve
     * @param confg The JoyConfig instance
     */
    public JoyFileSystemServeHandler(let root: Path, let confg: JoyConfig) {}

    /**
     * Handles the request to serve a file from the file system
     *
     * @param ctx The JoyContext instance
     */
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
