package cjoy

import std.collection.{ArrayList, HashMap}
import net.http.{HttpRequestDistributor, HttpRequestHandler, NotFoundHandler, HttpStatusCode}

public interface JoyRouters {
    func use(mw: JoyMiddlewareHandler): JoyRouters
    func use(mw: (handler: JoyRequestHandler)-> JoyRequestHandler): JoyRouters{
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

    func staticFile(relativePath: String, filePath: String): JoyRouters
    func staticAll(relativePath: String, rootPath: String): JoyRouters
}


class LookupResult  {
	var statusCode: UInt16 = HttpStatusCode.STATUS_NOT_FOUND
	var handler: ?JoyRequestHandler = None
	// Params represents the key value pairs of the path parameters.
	var params: HashMap<String, String> = HashMap()
     // Only has a value when StatusCode is MethodNotAllowed.
	var leafHandler: HashMap<String, JoyRequestHandler> = HashMap()
}

class TreeMux <: HttpRequestDistributor {
    var _root: Node<JoyRequestHandler> = Node("/", STATIC)
    public let config: JoyConfig

    init(config: JoyConfig) {
        this.config = config
    }

    public func register(path: String, handler: HttpRequestHandler): Unit {
       
    }

    public func distribute(path: String): HttpRequestHandler {
        return NotFoundHandler()
    }

    private func lookup(path: String): LookupResult {
        let result: LookupResult = LookupResult()

        result
    }
}

class JoyRouteGroup <: JoyRouters {
    let _stack: ArrayList<JoyMiddlewareHandler>
    let _path: String
    let _mux: TreeMux

    init(path: String, mux: TreeMux, stack: ArrayList<JoyMiddlewareHandler>) {
        _path = path
        _mux = mux
        _stack = stack
    }

    init(config: JoyConfig) {
        this("", TreeMux(config), ArrayList())
    }

    public func use(mw: JoyMiddlewareHandler): JoyRouters { 
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
        JoyRouteGroup(path, _mux, ArrayList(_stack))
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
        let thePath =  if (_mux.config.caseInsensitive) {
            path.toAsciiLower()
        } else {
            path
        }

        let node = _mux._root.addPath(thePath[1..thePath.size], ArrayList<String>(), false)
        if (addSlash) {
            node._addSlash = true
        }
        node.setHandler(method, handler, false)

        if (_mux.config.headCanUseGet && method == "GET" && node._leafHandlers.get("HEAD").isNone()) {
            node.setHandler("HEAD", handler, true)
        }
    }

    private func addFullStackHandler(method: String, path: String, handler: JoyRequestHandler): Unit {
        var addSlash = false
        checkPath(path)
	    var thePath = _path + path
        if (thePath.isEmpty()) {
            throw IllegalArgumentException("Cannot map an empty path")
        }

        if (thePath.size > 1 && thePath[thePath.size-1] == b'/' && _mux.config.redirectTrailingSlash) {
            addSlash = true
            thePath = thePath[0..thePath.size-1]
        }

	    if (_mux.config.escapeAddedRoutes) {
            let escapedPath = unescapeSpecial(thePath)
            if (escapedPath != thePath) {
                addOne(method, escapedPath, addSlash, handler)
            }
	    }

	    addOne(method, thePath, addSlash, handler)
    }

    private static func unescapeSpecial(s:String): String {
        s
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
        let h = if (_stack.size > 0 ) {
		    handlerWithMiddlewares(handler)
	    } else {
            handler
        }

        for(method in methods) {
            addFullStackHandler(method, relativePath, handler)
        }
        this
    }

    private func handlerWithMiddlewares(handler: JoyRequestHandler): JoyRequestHandler {
        var res: JoyRequestHandler = handler
        for (i in _stack.size..0) {
            res = _stack[i].next(res)
        }
        return res
    }

    public func staticFile(relativePath: String, filePath: String): JoyRouters {
        this
    }

    public func staticAll(relativePath: String, rootPath: String): JoyRouters {
        this
    }
}