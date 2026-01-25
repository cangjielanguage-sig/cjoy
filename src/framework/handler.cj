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

import std.collection.{forEach, ArrayList}
import stdx.net.http.{notFound, HttpStatusCode, OptionsHandler}
import cjoy.ioc.{BeanFactoryManager}

/**
 * the interface of request handler
 */
public interface JoyRequestHandler {
    /**
     * process the request and reply response using context api
     *
     * @param ctx: the context
     */
    func handle(ctx: JoyContext): Unit
}

// the request handler function
public type JoyRequestHandlerFunc = (ctx: JoyContext) -> Unit

// the request filter function 
public type JoyRequestFilterFunc = (ctx: JoyContext) -> Bool

/**
 * function based request handler implementation
 */
public class JoyFuncHandler <: JoyRequestHandler {
    /**
     * create a new JoyFuncHandler
     *
     * @param handler: the handler function
     */
    public JoyFuncHandler(let handler: JoyRequestHandlerFunc) {}

    /**
     * process request using handler function
     *
     * @param ctx: the context
     */
    public func handle(ctx: JoyContext): Unit {
        this.handler(ctx)
    }
}

/**
 * default 404 not found handler
 */
public class JoyNotFoundHandler <: JoyRequestHandler {
    public func handle(ctx: JoyContext): Unit {
        notFound(ctx.httpContext)
    }
}

/**
 * default 405 method not allowed handler
 */
public class JoyMethodNotAllowedHandler <: JoyRequestHandler {
    public func handle(ctx: JoyContext): Unit {
        let methods: Collection<String> = ctx.getCtxParam<Collection<String>>("methods").getOrThrow()
        methods |> forEach {val => ctx.header(JoyHttpConsts.HEADER_ALLOW, val)}
        ctx.status(HttpStatusCode.STATUS_METHOD_NOT_ALLOWED)
    }
}

/**
 * default options handler
 */
class JoyOptionsHandler <: JoyRequestHandler {
    static let INSTANCE = JoyOptionsHandler()

    public func handle(ctx: JoyContext): Unit {
        OptionsHandler().handle(ctx.httpContext)
    }
}

/**
 * handler registry for registering route handlers
 */
public class JoyHandlers {
    private static let HANDLERS: ArrayList<(String, Array<String>, JoyRequestHandler)> = ArrayList()

    /**
     * add the handler for generate code by macros
     *
     * @param path: the path
     * @param methods: the methods
     * @param handler: the handler
     */
    public static func addHandler(path: String, methods: Array<String>, handler: JoyRequestHandler): Unit {
        HANDLERS.add((path, methods, handler))
    }

    /**
     * add handler function for generate code by macros
     *
     * @param path: the path
     * @param methods: the http methods
     * @param handler: the handler function
     */
    public static func addHandler(path: String, methods: Array<String>, handler: JoyRequestHandlerFunc): Unit {
        HANDLERS.add((path, methods, JoyFuncHandler(handler)))
    }

    /**
     * register the handlers to joy instance
     *
     * @param joy: the instance of joy
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