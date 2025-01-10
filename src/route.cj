/*
 * Copyright (c) lanlingx 2024-2024. All rights resvered.
 */

package cjoy

import std.collection.{ArrayList, HashMap, forEach}
import encoding.url.URL
import net.http.*

public interface JoyRouters {
    prop distributor: HttpRequestDistributor

    func use(mw: JoyMiddlewareHandler): JoyRouters
    func use(mw: (ctx: JoyContext, chain: JoyRequestHandlerChain) -> Unit): JoyRouters {
        use(JoyMiddlewareFuncHandler(mw))
    }

    func group(relativePath: String): JoyRouters
    func basePath(): String

    func GET(relativePath: String, handler: JoyRequestHandler): JoyRouters
    func GET(relativePath: String, handler: (ctx: JoyContext) -> Unit): JoyRouters {
        GET(relativePath, JoyFuncHandler(handler))
    }

    func POST(relativePath: String, handler: JoyRequestHandler): JoyRouters
    func POST(relativePath: String, handler: (ctx: JoyContext) -> Unit): JoyRouters {
        POST(relativePath, JoyFuncHandler(handler))
    }

    func PUT(relativePath: String, handler: JoyRequestHandler): JoyRouters
    func PUT(relativePath: String, handler: (ctx: JoyContext) -> Unit): JoyRouters {
        PUT(relativePath, JoyFuncHandler(handler))
    }

    func DELETE(relativePath: String, handler: JoyRequestHandler): JoyRouters
    func DELETE(relativePath: String, handler: (ctx: JoyContext) -> Unit): JoyRouters {
        DELETE(relativePath, JoyFuncHandler(handler))
    }

    func PATCH(relativePath: String, handler: JoyRequestHandler): JoyRouters
    func PATCH(relativePath: String, handler: (ctx: JoyContext) -> Unit): JoyRouters {
        PATCH(relativePath, JoyFuncHandler(handler))
    }

    func OPTION(relativePath: String, handler: JoyRequestHandler): JoyRouters
    func OPTION(relativePath: String, handler: (ctx: JoyContext) -> Unit): JoyRouters {
        OPTION(relativePath, JoyFuncHandler(handler))
    }

    func HEAD(relativePath: String, handler: JoyRequestHandler): JoyRouters
    func HEAD(relativePath: String, handler: (ctx: JoyContext) -> Unit): JoyRouters {
        HEAD(relativePath, JoyFuncHandler(handler))
    }

    func handle(method: Array<String>, relativePath: String, handler: JoyRequestHandler): JoyRouters
    func handle(method: Array<String>, relativePath: String, handler: (ctx: JoyContext) -> Unit): JoyRouters {
        handle(method, relativePath, JoyFuncHandler(handler))
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
        _middlewares.append(mw)
        this
    }

    public func group(relativePath: String): JoyRouters {
        if (relativePath.isEmpty()) {
            throw IllegalArgumentException("group relativePath must not be empty")
        }
        checkPath(relativePath)

        var path = _path + relativePath
        // don't want trailing slash as all sub-paths start with slash
        if (path[path.size - 1] == b'/') {
            path = path[0..path.size - 1]
        }
        JoyRouteGroup(path, _distributor, ArrayList(_middlewares))
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

    public func GET(relativePath: String, handler: JoyRequestHandler): JoyRouters {
        handle(["GET"], relativePath, handler)
        this
    }

    public func POST(relativePath: String, handler: JoyRequestHandler): JoyRouters {
        handle(["POST"], relativePath, handler)
        this
    }

    public func PUT(relativePath: String, handler: JoyRequestHandler): JoyRouters {
        handle(["PUT"], relativePath, handler)
        this
    }

    public func DELETE(relativePath: String, handler: JoyRequestHandler): JoyRouters {
        handle(["DELETE"], relativePath, handler)
        this
    }

    public func PATCH(relativePath: String, handler: JoyRequestHandler): JoyRouters {
        handle(["PATCH"], relativePath, handler)
        this
    }

    public func OPTION(relativePath: String, handler: JoyRequestHandler): JoyRouters {
        handle(["OPTION"], relativePath, handler)
        this
    }

    public func HEAD(relativePath: String, handler: JoyRequestHandler): JoyRouters {
        handle(["HEAD"], relativePath, handler)
        this
    }

    public func handle(methods: Array<String>, relativePath: String, handler: JoyRequestHandler): JoyRouters {
        let wrapperHandler = JoyRequestHandlerWrapper(handler, ArrayList(_middlewares))
        methods |> forEach {method => addHandler(method, relativePath, wrapperHandler)}
        this
    }
}
