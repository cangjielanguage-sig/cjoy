/*
 * Copyright (c) lanlingx 2024-2024. All rights resvered.
 */

package cjoy

import std.collection.{ArrayList, HashMap, forEach}
import encoding.url.URL
import net.http.*

public interface JoyRouters {
    prop distributor: HttpRequestDistributor

    /**
     * appends a middleware handler to the middleware stack.
     *
     * The middleware stack for any router will execute before searching for a matching
     * route to a specific handler, which provides opportunity to respond early,
     * change the course of the request execution.
     */
    func use(mw: JoyMiddlewareHandler): JoyRouters
    func use(mw: (ctx: JoyContext, chain: JoyRequestHandlerChain) -> Unit): JoyRouters {
        use(JoyMiddlewareFuncHandler(mw))
    }

    /**
     * adds inline middlewares for an endpoint handler.
     */
    func apply(mw: JoyMiddlewareHandler): JoyRouters
    func apply(mw: (ctx: JoyContext, chain: JoyRequestHandlerChain) -> Unit): JoyRouters {
        apply(JoyMiddlewareFuncHandler(mw))
    }

    /**
     * creates a new inline router with a copy of middleware stack. it's useful
     * for a group of handlers along the same routing path that use an additional
     * set of middlewares.
     */
    func group(relativePath: String): JoyRouters
    func basePath(): String

    /**
     * adds the route `pattern` that matches `GET` http method to execute the `handler`.
     */
    func GET(pattern: String, handler: JoyRequestHandler): JoyRouters
    func GET(pattern: String, handler: (ctx: JoyContext) -> Unit): JoyRouters {
        GET(pattern, JoyFuncHandler(handler))
    }

    /**
     * adds the route `pattern` that matches `POST` http method to execute the `handler`.
     */
    func POST(pattern: String, handler: JoyRequestHandler): JoyRouters
    func POST(pattern: String, handler: (ctx: JoyContext) -> Unit): JoyRouters {
        POST(pattern, JoyFuncHandler(handler))
    }

    /**
     * adds the route `pattern` that matches `PUT` http method to execute the `handler`.
     */
    func PUT(pattern: String, handler: JoyRequestHandler): JoyRouters
    func PUT(pattern: String, handler: (ctx: JoyContext) -> Unit): JoyRouters {
        PUT(pattern, JoyFuncHandler(handler))
    }

    /**
     * adds the route `pattern` that matches `DELETE` http method to execute the `handler`.
     */
    func DELETE(pattern: String, handler: JoyRequestHandler): JoyRouters
    func DELETE(pattern: String, handler: (ctx: JoyContext) -> Unit): JoyRouters {
        DELETE(pattern, JoyFuncHandler(handler))
    }

    /**
     * adds the route `pattern` that matches `PATCH` http method to execute the `handler`.
     */
    func PATCH(pattern: String, handler: JoyRequestHandler): JoyRouters
    func PATCH(pattern: String, handler: (ctx: JoyContext) -> Unit): JoyRouters {
        PATCH(pattern, JoyFuncHandler(handler))
    }

    /**
     * adds the route `pattern` that matches `OPTION` http method to execute the `handler`.
     */
    func OPTION(pattern: String, handler: JoyRequestHandler): JoyRouters
    func OPTION(pattern: String, handler: (ctx: JoyContext) -> Unit): JoyRouters {
        OPTION(pattern, JoyFuncHandler(handler))
    }

    /**
     * adds the route `pattern` that matches `HEAD` http method to execute the `handler`.
     */
    func HEAD(pattern: String, handler: JoyRequestHandler): JoyRouters
    func HEAD(pattern: String, handler: (ctx: JoyContext) -> Unit): JoyRouters {
        HEAD(pattern, JoyFuncHandler(handler))
    }

    /**
     * adds the route `pattern` that matches `method` http method to execute the `handler`.
     */
    func handle(methods: Array<String>, pattern: String, handler: JoyRequestHandler): JoyRouters
    func handle(methods: Array<String>, pattern: String, handler: (ctx: JoyContext) -> Unit): JoyRouters {
        handle(methods, pattern, JoyFuncHandler(handler))
    }
}

class JoyRouteHandler <: HttpRequestHandler {
    public JoyRouteHandler(
        let handler: JoyRequestHandler,
        let paramMap: HashMap<String, String>,
        let config: JoyConfig
    ) {}

    public func handle(ctx: HttpContext): Unit {
        let joyCtx = JoyContext(ctx, paramMap, config)
        handler.handle(joyCtx)
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

class JoyMethodNotAllowedHandler <: HttpRequestHandler {
    public JoyMethodNotAllowedHandler(let methods: Collection<String>) {}

    public func handle(ctx: HttpContext): Unit {
        let rspBuilder = ctx.responseBuilder
        methods |> forEach {val => rspBuilder.header("Allow", val)}
        rspBuilder.status(HttpStatusCode.STATUS_METHOD_NOT_ALLOWED)
        rspBuilder.build()
    }
}

class TreeRouteDistributor <: HttpRequestDistributor & HttpRequestHandler {
    var _root: TreeNode<JoyRequestHandler> = TreeNode(NT_STATIC, b'\0', "")

    let _config: JoyConfig

    init(config: JoyConfig) {
        this._config = config
    }

    public func register(_: String, _: HttpRequestHandler): Unit {
        throw UnsupportedException("unsupported this method")
    }

    public func distribute(_: String): HttpRequestHandler {
        // redirect to handle method
        this
    }

    public func handle(ctx: HttpContext) {
        let handler = lookup(ctx.request)
        handler.handle(ctx)
    }

    private func lookup(req: HttpRequest): HttpRequestHandler {
        var path = if (_config.caseInsensitive) {
            req.url.path.toAsciiLower()
        } else {
            req.url.path
        }

        let ri: RouteInfo = RouteInfo()
        let (node, handler) = _root.findRouteHandler(ri, req.method, path)
        if (node.isNone()) {
            return NotFoundHandler()
        }

        if (handler.isNone()) {
            if (req.method == "OPTIONS") {
                return OptionsHandler()
            }
            if (ri.methodNotAllowed) {
                return JoyMethodNotAllowedHandler(ri.methodsAllowed)
            }
            return NotFoundHandler()
        }

        let paramMap: HashMap<String, String> = HashMap()
        if (!ri.routeParamKeys.isEmpty()) {
            if (ri.routeParamKeys.size != ri.routeParamValues.size) {
                throw Exception("parameter list length mismatch")
            }
            for (idx in 0..ri.routeParamKeys.size) {
                paramMap[ri.routeParamKeys[idx]] = ri.routeParamValues[idx]
            }
        }

        JoyRouteHandler(handler.getOrThrow(), paramMap, _config)
    }

    public func dump(): String {
        _root.dumpTree()
    }
}

class JoyRouteGroup <: JoyRouters {
    let _path: String
    let _distributor: TreeRouteDistributor
    let _middlewares: ArrayList<JoyMiddlewareHandler>
    let _applyMWs: ArrayList<JoyMiddlewareHandler> = ArrayList()
    let _groups: HashMap<String, JoyRouters> = HashMap()

    init(path: String, distributor: TreeRouteDistributor, middlewares: ArrayList<JoyMiddlewareHandler>) {
        _path = path
        _distributor = distributor
        _middlewares = middlewares
    }

    init(config: JoyConfig) {
        this("", TreeRouteDistributor(config), ArrayList())
    }

    public prop distributor: HttpRequestDistributor {
        get() {
            _distributor
        }
    }

    public func use(mw: JoyMiddlewareHandler): JoyRouters {
        _middlewares.add(mw)
        this
    }

    public func apply(mw: JoyMiddlewareHandler): JoyRouters {
        _applyMWs.add(mw)
        this
    }

    public func group(pattern: String): JoyRouters {
        if (pattern.isEmpty()) {
            throw IllegalArgumentException("group relativePath must not be empty")
        }
        checkPath(pattern)

        var path = _path + pattern
        // don't want trailing slash as all sub-paths start with slash
        if (path[path.size - 1] == b'/') {
            path = path[0..path.size - 1]
        }

        if (let Some(group) <- _groups.get(path)) {
            return group
        }

        let group = JoyRouteGroup(path, _distributor, ArrayList(_middlewares))
        _groups.add(path, group)
        group
    }

    private static func checkPath(path: String): Unit {
        if (path.size > 1 && path[0] != b'/') {
            throw IllegalArgumentException("path [$[path}] must start with slash")
        }
    }

    public func basePath(): String {
        _path
    }

    private func addOne(method: String, path: String, handler: JoyRequestHandler): Unit {
        let thePath = if (_distributor._config.caseInsensitive) {
            path.toAsciiLower()
        } else {
            path
        }
        _distributor._root.addRoute(method, thePath, handler)
    }

    private func addHandler(method: String, path: String, handler: JoyRequestHandler): Unit {
        checkPath(path)
        var thePath = _path + path
        if (thePath.isEmpty()) {
            throw IllegalArgumentException("cannot map an empty path")
        }

        if (_distributor._config.escapeAddedRoutes) {
            let escapedPath = unescapeSpecial(thePath)
            if (escapedPath != thePath) {
                addOne(method, escapedPath, handler)
            }
        }

        addOne(method, thePath, handler)
    }

    private static func unescapeSpecial(s: String): String {
        var res = s
        res = res.replace("/%2A", "/*")
        res = res.replace("/%5C:", "/\\:")
        // /\\: -> /\:
        res = res.replace("/%5C%5C:", "/%5C:")
        // /\* -> /*
        res = res.replace("/%5C%2A", "/%2A")
        // /\\* -> /\*
        res = res.replace("/%5C%5C%2A", "/%5C%2A")
        res
    }

    public func GET(pattern: String, handler: JoyRequestHandler): JoyRouters {
        handle(["GET"], pattern, handler)
        this
    }

    public func POST(pattern: String, handler: JoyRequestHandler): JoyRouters {
        handle(["POST"], pattern, handler)
        this
    }

    public func PUT(pattern: String, handler: JoyRequestHandler): JoyRouters {
        handle(["PUT"], pattern, handler)
        this
    }

    public func DELETE(pattern: String, handler: JoyRequestHandler): JoyRouters {
        handle(["DELETE"], pattern, handler)
        this
    }

    public func PATCH(pattern: String, handler: JoyRequestHandler): JoyRouters {
        handle(["PATCH"], pattern, handler)
        this
    }

    public func OPTION(pattern: String, handler: JoyRequestHandler): JoyRouters {
        handle(["OPTION"], pattern, handler)
        this
    }

    public func HEAD(pattern: String, handler: JoyRequestHandler): JoyRouters {
        handle(["HEAD"], pattern, handler)
        this
    }

    public func handle(methods: Array<String>, pattern: String, handler: JoyRequestHandler): JoyRouters {
        let mws: ArrayList<JoyMiddlewareHandler> = ArrayList(_middlewares)
        mws.add(all:_applyMWs)
        _applyMWs.clear()
        let wrapperHandler = JoyRequestHandlerWrapper(handler, mws)
        methods |> forEach {method => addHandler(method, pattern, wrapperHandler)}
        this
    }
}
