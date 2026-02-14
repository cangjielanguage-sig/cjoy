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
 * Request handler interface for processing HTTP requests
 */
public interface JoyRequestHandler {
    /**
     * Processes request and replies with response using context API
     *
     * @param ctx Request/response context
     */
    func handle(ctx: JoyContext): Unit
}

/**
 * Type alias for request handler function
 */
public type JoyRequestHandlerFunc = (ctx: JoyContext) -> Unit

/**
 * Type alias for request filter function that returns true to continue chain
 */
public type JoyRequestFilterFunc = (ctx: JoyContext) -> Bool

/**
 * function based request handler implementation
 */
public class JoyFuncHandler <: JoyRequestHandler {
    /**
     * Creates a new JoyFuncHandler
     *
     * @param handler Handler function
     */
    public JoyFuncHandler(let handler: JoyRequestHandlerFunc) {}

    /**
     * Processes request using the handler function
     *
     * @param ctx Request/response context
     */
    public func handle(ctx: JoyContext): Unit {
        this.handler(ctx)
    }
}

/**
 * Default 404 Not Found request handler
 */
public class JoyNotFoundHandler <: JoyRequestHandler {
    public func handle(ctx: JoyContext): Unit {
        notFound(ctx.httpContext)
    }
}

/**
 * Default 405 Method Not Allowed request handler
 */
public class JoyMethodNotAllowedHandler <: JoyRequestHandler {
    public func handle(ctx: JoyContext): Unit {
        let methods: Collection<String> = ctx.getCtxParam<Collection<String>>("methods").getOrThrow()
        methods |> forEach {val => ctx.header(JoyHttpConsts.HEADER_ALLOW, val)}
        ctx.status(HttpStatusCode.STATUS_METHOD_NOT_ALLOWED)
    }
}

/**
 * Default OPTIONS request handler
 */
class JoyOptionsHandler <: JoyRequestHandler {
    static let INSTANCE = JoyOptionsHandler()

    public func handle(ctx: JoyContext): Unit {
        OptionsHandler().handle(ctx.httpContext)
    }
}

/**
 * Handler registry for registering route handlers
 */
public class JoyHandlers {
    private static let HANDLERS: ArrayList<(String, Array<String>, JoyRequestHandler)> = ArrayList()

    /**
     * Adds a handler for code generation by macros
     *
     * @param path Route path
     * @param methods HTTP methods
     * @param handler Request handler
     */
    public static func addHandler(path: String, methods: Array<String>, handler: JoyRequestHandler): Unit {
        HANDLERS.add((path, methods, handler))
    }

    /**
     * Adds a handler function for code generation by macros
     *
     * @param path Route path
     * @param methods HTTP methods
     * @param handler Request handler function
     */
    public static func addHandler(path: String, methods: Array<String>, handler: JoyRequestHandlerFunc): Unit {
        HANDLERS.add((path, methods, JoyFuncHandler(handler)))
    }

    /**
     * Registers all handlers to the Joy engine instance
     *
     * @param joy Joy engine instance
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
