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
 * JoyFileHandlerFactory 的默认实现
 */
@Component[extends = ["JoyFileHandlerFactory"]]
class DefaultJoyFileHandlerFactory <: JoyFileHandlerFactory {
    /**
     * 为给定文件路径创建文件服务处理器
     *
     * @param filePath 要服务的文件路径
     * @return 用于服务文件的 JoyRequestHandler
     */
    public func createFileServeHandler(filePath: String): JoyRequestHandler {
        JoyFileServeHandler(filePath)
    }

    /**
     * 为给定根路径创建文件系统服务处理器
     *
     * @param root 要服务的文件系统根路径
     * @param confg JoyConfig 实例
     * @return 用于服务文件系统的 JoyRequestHandler
     */
    public func createFileSystemServeHandler(root: Path, confg: JoyConfig): JoyRequestHandler {
        JoyFileSystemServeHandler(root, confg)
    }

    /**
     * 从给定文件路径提供文件服务
     *
     * @param ctx JoyContext 实例
     * @param filePath 要服务的文件路径
     */
    public func serveFile(ctx: JoyContext, filePath: Path): Unit {
        JoyFileServer.serveFile(ctx, filePath)
    }

    /**
     * 将文件作为附件下载
     *
     * @param ctx JoyContext 实例
     * @param filePath 要下载的文件路径
     */
    public func downloadFile(ctx: JoyContext, filePath: Path): Unit {
        downloadAttachment(ctx, filePath)
    }
}

/**
 * 用于服务单个文件的 JoyRequestHandler
 */
class JoyFileServeHandler <: JoyRequestHandler {
    /**
     * 创建新的 JoyFileServeHandler 实例
     *
     * @param filePath 要服务的文件路径
     */
    JoyFileServeHandler(let filePath: String) {
    }

    /**
     * 处理服务文件的请求
     *
     * @param ctx JoyContext 实例
     */
    public func handle(ctx: JoyContext): Unit {
        JoyFileServer.serveFile(ctx, Path(filePath))
    }
}

/**
 * 用于服务文件系统目录的 JoyRequestHandler
 */
class JoyFileSystemServeHandler <: JoyRequestHandler {
    /**
     * 创建新的 JoyFileSystemServeHandler 实例
     *
     * @param root 要服务的文件系统根路径
     * @param confg JoyConfig 实例
     */
    public JoyFileSystemServeHandler(let root: Path, let confg: JoyConfig) {}

    /**
     * 处理文件系统请求
     *
     * @param ctx JoyContext 实例
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
