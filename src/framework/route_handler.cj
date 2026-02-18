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
        // 默认处理是返回未找到
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
 * 用于创建文件服务处理程序的工厂接口
 */
public interface JoyFileHandlerFactory {
    /**
     * 为提供单个文件创建处理程序
     *
     * @param filePath: 要提供服务的文件路径
     * @return 文件服务处理程序
     */
    func createFileServeHandler(filePath: String): JoyRequestHandler

    /**
     * 为提供文件系统目录创建处理程序
     *
     * @param root: 根目录路径
     * @param confg: Joy 配置
     * @return 文件系统服务处理程序
     */
    func createFileSystemServeHandler(root: Path, confg: JoyConfig): JoyRequestHandler

    /**
     * 将文件提供给客户端
     *
     * @param ctx: 请求上下文
     * @param filePath: 要提供服务的文件路径
     */
    func serveFile(ctx: JoyContext, filePath: Path): Unit

    /**
     * 以附件形式提供下载文件
     *
     * @param ctx: 请求上下文
     * @param filePath: 要下载的文件路径
     */
    func downloadFile(ctx: JoyContext, filePath: Path): Unit
}
