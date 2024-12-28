/*
* Copyright (c) lanlingx 2024-2024. All rights resvered.
*/

package cjoy

import std.collection.{ArrayList, HashMap, forEach}
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

class JoyRouteHandler <: HttpRequestHandler  {
    public JoyRouteHandler(
        let handler: JoyRequestHandler, 
        let paramMap: HashMap<String, String>, 
        let config: JoyConfig) {}

    public func handle(ctx: HttpContext) : Unit {
        let joyCtx = JoyContext(ctx, paramMap, config)
        handler.handle(joyCtx)
    }
}

class JoyRequestHandlerWrapper <: JoyRequestHandlerChain & JoyRequestHandler {
    private var _idx: Int = 0

    public JoyRequestHandlerWrapper(let handler: JoyRequestHandler, let mws: ArrayList<JoyMiddlewareHandler>) {}

    public func handle(ctx: JoyContext): Unit {
        if (mws.isEmpty()) {
            handler.handle(ctx)
        } else {
            mws[_idx].handle(ctx, this)
        }
    }

    public func next(ctx: JoyContext): Unit {
        _idx+=1
        if (_idx < mws.size) {
            mws[_idx].handle(ctx, this)
            return
        }
        handler.handle(ctx)
    }
}

class JoyMethodNotAllowedHandler <: HttpRequestHandler {
    public JoyMethodNotAllowedHandler(let methods: Collection<String>) {}
    
    public func handle(ctx: HttpContext): Unit {
        let rspBuilder = ctx.responseBuilder
        methods |> forEach { val => rspBuilder.header("Allow", val) }
        rspBuilder.status(HttpStatusCode.STATUS_METHOD_NOT_ALLOWED)
        rspBuilder.build()
    }
}

class TreeRouteDistributor <: HttpRequestDistributor & HttpRequestHandler{
    var _root: Node<JoyRequestHandler> = Node("/", STATIC)
    public let config: JoyConfig

    init(config: JoyConfig) {
        this.config = config
    }

    public func register(_: String, _: HttpRequestHandler): Unit {
        throw UnsupportedException("unsupported this method")
    }

    public func distribute(_: String): HttpRequestHandler {
        // redirect to handle method
        this
    }

    public func handle(ctx: HttpContext)  {
        let handler = lookup(ctx.request)
        handler.handle(ctx)
    }

    private func lookup(req: HttpRequest): HttpRequestHandler {
        var path = if (config.caseInsensitive) { req.url.path.toAsciiLower() } else { req.url.path }

        var pathLen = path.size
        var trailingSlash = path[pathLen-1] == b'/' && pathLen > 1
        if (trailingSlash && config.redirectTrailingSlash) {
            path = path[0..path.size-1]
        }

        let (node, handler ,params) = _root.search(req.method, path[1..path.size])
        if (node.isNone()) {
            return NotFoundHandler()
        }
        let tnode = node.getOrThrow()

        if (handler.isNone()) {
            if (req.method == "OPTIONS") {
                return OptionsHandler()
            }
            return JoyMethodNotAllowedHandler(tnode._leafHandlers.keys())
        }

        if (!tnode.isCatchAll()) {
            if (trailingSlash != tnode._addSlash) {
                // something
            }
        }

        let paramMap: HashMap<String, String> = HashMap()
        if (!params.isEmpty()) {
            if (params.size != tnode._leafParamNames.size) {
                throw Exception("parameter list length mismatch")
            }
            for (idx in 0..params.size) {
                paramMap[tnode._leafParamNames[params.size - idx -1]] = params[idx]
            }
        }

        JoyRouteHandler(handler.getOrThrow(), paramMap, config)
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
        get() { _distributor }
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
        if (path[path.size -1] == b'/') {
            path = path[0..path.size-1]
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

    private func addOne(method: String, path: String, addSlash: Bool, handler: JoyRequestHandler): Unit {
        let thePath = if (_distributor.config.caseInsensitive) { path.toAsciiLower() } else { path }
        let node = _distributor._root.addPath(thePath[1..thePath.size], ArrayList<String>(), false)
        if (addSlash) {
            node._addSlash = true
        }
        node.setHandler(method, handler, false)

        if (_distributor.config.headCanUseGet && method == "GET" && node._leafHandlers.get("HEAD").isNone()) {
            node.setHandler("HEAD", handler, true)
        }
    }

    private func addHandler(method: String, path: String, handler: JoyRequestHandler): Unit {
        var addSlash = false
        checkPath(path)
	    var thePath = _path + path
        if (thePath.isEmpty()) {
            throw IllegalArgumentException("cannot map an empty path")
        }

        if (thePath.size > 1 && thePath[thePath.size-1] == b'/' && _distributor.config.redirectTrailingSlash) {
            addSlash = true
            thePath = thePath[0..thePath.size-1]
        }

	    if (_distributor.config.escapeAddedRoutes) {
            let escapedPath = unescapeSpecial(thePath)
            if (escapedPath != thePath) {
                addOne(method, escapedPath, addSlash, handler)
            }
	    }

	    addOne(method, thePath, addSlash, handler)
    }

    private static func unescapeSpecial(s:String): String {
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
        methods |> forEach { method => addHandler(method, relativePath, wrapperHandler) }
        this
    }
}