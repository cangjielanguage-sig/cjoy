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

import std.collection.{forEach, HashMap}

/**
 * 请求处理器链接口，用于管理中间件执行
 */
public interface JoyRequestHandlerChain {
    /**
     * 移动到链中的下一个处理器
     *
     * @param ctx 请求/响应上下文
     */
    func next(ctx: JoyContext): Unit
}

/**
 * 请求中间件处理器接口，用于处理 HTTP 请求
 */
public interface JoyMiddlewareHandler {
    /**
     * 处理请求并可选择将其传递给链中的下一个中间件
     *
     * @param ctx 请求/响应上下文
     * @param chain 用于将请求传递给下一个处理器的中间件链
     */
    func handle(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit
}

/**
 * 中间件函数的类型别名
 */
public type JoyMiddlewareFunc = (ctx: JoyContext, chain: JoyRequestHandlerChain) -> Unit

/**
 * 基于函数的中间件处理器实现
 */
public class JoyMiddlewareFuncHandler <: JoyMiddlewareHandler {
    /**
     * 创建新的 JoyMiddlewareFuncHandler
     *
     * @param handler 中间件函数
     */
    public JoyMiddlewareFuncHandler(let handler: JoyMiddlewareFunc) {}

    /**
     * 使用中间件函数处理请求
     *
     * @param ctx 请求/响应上下文
     * @param chain 用于将请求传递给下一个处理器的中间件链
     */
    public func handle(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
        this.handler(ctx, chain)
    }
}

/**
 * 中间件处理器注册表，用于注册路由处理器
 */
public class JoyMiddlewares {
    private static let MIDDLEWARES: HashMap<String, JoyMiddlewareHandler> = HashMap()

    /**
     * 为由宏生成的代码添加中间件处理器
     *
     * @param groups 要注册中间件的组路径数组
     * @param mw 要添加的中间件处理器
     */
    public static func addHandler(groups: Array<String>, mw: JoyMiddlewareHandler): Unit {
        groups |> forEach {group => MIDDLEWARES.add(group, mw)}
    }

    /**
     * 将所有中间件处理器注册到 Joy 引擎实例
     *
     * @param joy 要注册中间件的 Joy 引擎实例
     */
    public static func registerTo(joy: Joy): Unit {
        for ((path, handler) in MIDDLEWARES) {
            let r = joy.router.createGroups(path)
            r.use(handler)
        }
    }
}
