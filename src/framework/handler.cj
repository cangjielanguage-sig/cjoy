/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to terms and conditions of Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.framework

import std.collection.{forEach, ArrayList}
import stdx.net.http.{notFound, HttpStatusCode, OptionsHandler}
import cjoy.ioc.{BeanFactoryManager}

/**
 * 用于处理 HTTP 请求的请求处理器接口
 */
public interface JoyRequestHandler {
    /**
     * 使用上下文 API 处理请求并回复响应
     *
     * @param ctx 请求/响应上下文
     */
    func handle(ctx: JoyContext): Unit
}

/**
 * 请求处理器函数的类型别名
 */
public type JoyRequestHandlerFunc = (ctx: JoyContext) -> Unit

/**
 * 请求过滤器函数的类型别名，返回 true 以继续链
 */
public type JoyRequestFilterFunc = (ctx: JoyContext) -> Bool

/**
 * 基于函数的请求处理器实现
 */
public class JoyFuncHandler <: JoyRequestHandler {
    /**
     * 创建新的 JoyFuncHandler
     *
     * @param handler 处理器函数
     */
    public JoyFuncHandler(let handler: JoyRequestHandlerFunc) {}

    /**
     * 使用处理器函数处理请求
     *
     * @param ctx 请求/响应上下文
     */
    public func handle(ctx: JoyContext): Unit {
        this.handler(ctx)
    }
}

/**
 * 默认的 404 Not Found 请求处理器
 */
public class JoyNotFoundHandler <: JoyRequestHandler {
    public func handle(ctx: JoyContext): Unit {
        notFound(ctx.httpContext)
    }
}

/**
 * 默认的 405 Method Not Allowed 请求处理器
 */
public class JoyMethodNotAllowedHandler <: JoyRequestHandler {
    public func handle(ctx: JoyContext): Unit {
        if (let Some(methods) <- ctx.getCtxParam<Collection<String>>("methods")) {
            let allow = String.join(methods.toArray(), delimiter: ",")
            ctx.header(JoyHttpConsts.HEADER_ALLOW, allow)
        }
        ctx.status(HttpStatusCode.STATUS_METHOD_NOT_ALLOWED)
    }
}

/**
 * 默认的 OPTIONS 请求处理器
 */
class JoyOptionsHandler <: JoyRequestHandler {
    static let INSTANCE = JoyOptionsHandler()

    public func handle(ctx: JoyContext): Unit {
        if (let Some(methods) <- ctx.getCtxParam<Collection<String>>("methods")) {
            let allow = String.join(methods.toArray(), delimiter: ",")
            ctx.header(JoyHttpConsts.HEADER_ALLOW, allow)
        }
        ctx.ok()
    }
}

/**
 * 用于注册路由处理器的处理器注册表
 */
public class JoyHandlers {
    private static let HANDLERS: ArrayList<(String, Array<String>, JoyRequestHandler)> = ArrayList()

    /**
     * 为由宏生成的代码添加处理器
     *
     * @param path 路由路径
     * @param methods HTTP 方法
     * @param handler 请求处理器
     */
    public static func addHandler(path: String, methods: Array<String>, handler: JoyRequestHandler): Unit {
        HANDLERS.add((path, methods, handler))
    }

    /**
     * 为由宏生成的代码添加处理器函数
     *
     * @param path 路由路径
     * @param methods HTTP 方法
     * @param handler 请求处理器函数
     */
    public static func addHandler(path: String, methods: Array<String>, handler: JoyRequestHandlerFunc): Unit {
        HANDLERS.add((path, methods, JoyFuncHandler(handler)))
    }

    /**
     * 将所有处理器注册到 Joy 引擎实例
     *
     * @param joy Joy 引擎实例
     */
    public static func registerTo(joy: Joy): Unit {
        // 依赖注入类需要先初始化
        BeanFactoryManager.initAllBeans()

        for (it in HANDLERS) {
            let (path, methods, handler) = it
            let rg = joy.router.findGroup(path)
            let rpath = path[rg.basePath().size..path.size]
            rg.handle(methods, rpath, handler)
        }
    }
}
