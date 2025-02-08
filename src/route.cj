/*
 * Copyright (c) lanlingx 2024-present. All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy

import std.collection.{ArrayList, HashMap, forEach}
import std.fs.*
import std.objectpool.ObjectPool 
import encoding.url.URL
import net.http.*
import log.Logger

/**
* the inferface of router
*/
public interface JoyRouters {
    /**
     * return the distributor instance
     */
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
    func findGroup(path: String): JoyRouters
    func createGroups(path: String): JoyRouters
    func basePath(): String

    /**
     * adds the route `pattern` that matches `GET` http method to execute the `handler`.
     */
    func get(pattern: String, handler: JoyRequestHandler): JoyRouters
    func get(pattern: String, handler: (ctx: JoyContext) -> Unit): JoyRouters {
        get(pattern, JoyFuncHandler(handler))
    }

    /**
     * adds the route `pattern` that matches `POST` http method to execute the `handler`.
     */
    func post(pattern: String, handler: JoyRequestHandler): JoyRouters
    func post(pattern: String, handler: (ctx: JoyContext) -> Unit): JoyRouters {
        post(pattern, JoyFuncHandler(handler))
    }

    /**
     * adds the route `pattern` that matches `PUT` http method to execute the `handler`.
     */
    func put(pattern: String, handler: JoyRequestHandler): JoyRouters
    func put(pattern: String, handler: (ctx: JoyContext) -> Unit): JoyRouters {
        put(pattern, JoyFuncHandler(handler))
    }

    /**
     * adds the route `pattern` that matches `DELETE` http method to execute the `handler`.
     */
    func delete(pattern: String, handler: JoyRequestHandler): JoyRouters
    func delete(pattern: String, handler: (ctx: JoyContext) -> Unit): JoyRouters {
        delete(pattern, JoyFuncHandler(handler))
    }

    /**
     * adds the route `pattern` that matches `PATCH` http method to execute the `handler`.
     */
    func patch(pattern: String, handler: JoyRequestHandler): JoyRouters
    func patch(pattern: String, handler: (ctx: JoyContext) -> Unit): JoyRouters {
        patch(pattern, JoyFuncHandler(handler))
    }

    /**
     * adds the route `pattern` that matches `OPTIONS` http method to execute the `handler`.
     */
    func options(pattern: String, handler: JoyRequestHandler): JoyRouters
    func options(pattern: String, handler: (ctx: JoyContext) -> Unit): JoyRouters {
        options(pattern, JoyFuncHandler(handler))
    }

    /**
     * adds the route `pattern` that matches `HEAD` http method to execute the `handler`.
     */
    func head(pattern: String, handler: JoyRequestHandler): JoyRouters
    func head(pattern: String, handler: (ctx: JoyContext) -> Unit): JoyRouters {
        head(pattern, JoyFuncHandler(handler))
    }

    /**
     * adds the route `pattern` that matches `method` http method to execute the `handler`.
     */
    func handle(methods: Array<String>, pattern: String, handler: JoyRequestHandler): JoyRouters
    func handle(methods: Array<String>, pattern: String, handler: (ctx: JoyContext) -> Unit): JoyRouters {
        handle(methods, pattern, JoyFuncHandler(handler))
    }

    /**
     * serves files with url path `relativePath` from the given file system `root`.
     */
    func staticFs(relativePath: String, root: String): JoyRouters

    /*
     * registers a single route with url path `relativePath` to serve a single file of the local filesystem.
     */
    func staticFile(relativePath: String, filepath: String): JoyRouters

    /**
    * adds the route `pattern` that matches `GET` http method to process websocket reqeuest.
    */
    func websocket(pattern: String, handler: JoyWebSocketHandler): JoyRouters

    /**
     * dump the route tree
     */
    func dump(): String
}

class TreeRouteDistributor <: HttpRequestDistributor & HttpRequestHandler {
    var _root: TreeNode<JoyRequestHandler> = TreeNode(NT_STATIC, b'\0', "")
    let _config: JoyConfig
    let _groups: HashMap<String, JoyRouters> = HashMap()
    let _handlerPool: ObjectPool<JoyRouteHandler>

    init(config: JoyConfig) {
        this._config = config
        this._handlerPool = ObjectPool({ => JoyRouteHandler(config) }, resetFunc: JoyRouteHandler.reset)
    }

    public func register(_: String, _: HttpRequestHandler): Unit {
        throw UnsupportedException("unsupported this method")
    }

    public func distribute(_: String): HttpRequestHandler {
        // redirect to handle method
        this
    }

    public func handle(ctx: HttpContext) {
        let handler = _handlerPool.get()
        try {
            lookup(ctx.request, handler)
            handler.handle(ctx)
        } finally {
            _handlerPool.put(handler)
        }
    }

    private func lookup(req: HttpRequest, obj: JoyRouteHandler): Unit {
        var path = if (_config.caseInsensitive) {
            req.url.path.toAsciiLower()
        } else {
            req.url.path
        }

        let ri: RouteInfo = RouteInfo()
        _config.logger.debug("[TreeRouteDistributor#lookup] finding handler, method=${req.method}, path=${path}")
        var (node, handler) = _root.findRouteHandler(ri, req.method, path)
        if (node.isNone()) {
            _config.logger.debug("[TreeRouteDistributor#lookup] not found handler, method=${req.method}, path=${path}")
            obj.handler = _config.notFoundHandler
            return
        }

        if (handler.isNone()) {
            if (req.method == "OPTIONS") {
                obj.handler = JoyOptionsHandler.INSTANCE
                return
            }
            
            if (ri.methodNotAllowed) {
                obj.ctxParamMap.add("methods", ri.methodsAllowed)
                obj.handler = _config.methodNotAllowedHandler
                return
            }

            _config.logger.debug("[TreeRouteDistributor#lookup] not found handler, method=${req.method}, path=${path}")
            obj.handler = _config.notFoundHandler
            return
        }

        if (!ri.routeParamKeys.isEmpty()) {
            if (ri.routeParamKeys.size != ri.routeParamValues.size) {
                throw Exception("parameter list length mismatch")
            }
            for (idx in 0..ri.routeParamKeys.size) {
                obj.paramMap[ri.routeParamKeys[idx]] = ri.routeParamValues[idx]
            }
        }

        obj.handler = handler.getOrThrow()
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
    let _logger: Logger

    init(path: String, distributor: TreeRouteDistributor, middlewares: ArrayList<JoyMiddlewareHandler>) {
        _path = path
        _distributor = distributor
        _middlewares = middlewares
        _logger = distributor._config.logger
    }

    init(config: JoyConfig) {
        this("", TreeRouteDistributor(config), ArrayList())
    }

    public prop distributor: HttpRequestDistributor {
        get() {
            _distributor
        }
    }

    public func dump(): String {
        _distributor._root.dumpTree()
    }

    public func use(mw: JoyMiddlewareHandler): JoyRouters {
        _middlewares.add(mw)
        this
    }

    public func apply(mw: JoyMiddlewareHandler): JoyRouters {
        _applyMWs.add(mw)
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

        if (let Some(group) <- _distributor._groups.get(path)) {
            return group
        }

        let group = JoyRouteGroup(path, _distributor, ArrayList(_middlewares))
        group.setGroupDefaultHandler()
        _distributor._groups.add(path, group)
        group
    }

    private func findGroupByPath(path: String): ?JoyRouters {
        _distributor._groups.get(path)
    }

    public func findGroup(path: String): JoyRouters {
        var router: JoyRouters = this
        var search = path

        while (!search.isEmpty()) {
            let found = findGroupByPath(search)
            if (let Some(f) <- found) {
                router = f
                break
            } else {
                let idx = search.lastIndexOf(b'/').getOrDefault({=> -1})
                if (!search.isEmpty() && idx > 0) {
                    search = search[0..idx]
                } else if (idx <= 0) {
                    break
                }
            }
        }

        router
    }

    public func createGroups(path: String): JoyRouters {
        checkPath(path)
        if (path.size == 1) {
            return this
        }

        let xpath = if (path[path.size - 1] == b'/') {
            path[1..path.size - 1]
        } else {
            path[1..path.size]
        }

        let segs = xpath.split("/")
        var gr: JoyRouters = this
        for (s in segs) {
            gr = gr.group("/" + s)
        }
        gr
    }

    private static func checkPath(path: String): Unit {
        if (path.size > 1 && path[0] != b'/') {
            throw IllegalArgumentException("path [$[path}] must start with slash")
        }
    }

    private func setGroupDefaultHandler(): Unit {
        if (_distributor._root.findPattern(_path + "*") || _distributor._root.findPattern(_path + "/*")) {
            throw IllegalArgumentException("a handler on an existing path, `${_path}`")
        }

        let allMethods = ["GET", "POST", "DELETE", "PUT", "PATCH", "HEAD", "OPTIONS"]
        groupHandle(allMethods, "", JoyGroupRouteHandler.INSTANCE)
        var xpattern = "/"
        groupHandle(allMethods, xpattern, JoyGroupRouteHandler.INSTANCE)
        xpattern = xpattern + "*"
        groupHandle(allMethods, xpattern, JoyGroupRouteHandler.INSTANCE)
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
        // /\* -> /*
        res = res.replace("/%5C%2A", "/%2A")
        // /\\* -> /\*
        res = res.replace("/%5C%5C%2A", "/%5C%2A")
        res
    }

    public func get(pattern: String, handler: JoyRequestHandler): JoyRouters {
        handle(["GET"], pattern, handler)
        this
    }

    public func post(pattern: String, handler: JoyRequestHandler): JoyRouters {
        handle(["POST"], pattern, handler)
        this
    }

    public func put(pattern: String, handler: JoyRequestHandler): JoyRouters {
        handle(["PUT"], pattern, handler)
        this
    }

    public func delete(pattern: String, handler: JoyRequestHandler): JoyRouters {
        handle(["DELETE"], pattern, handler)
        this
    }

    public func patch(pattern: String, handler: JoyRequestHandler): JoyRouters {
        handle(["PATCH"], pattern, handler)
        this
    }

    public func options(pattern: String, handler: JoyRequestHandler): JoyRouters {
        handle(["OPTIONS"], pattern, handler)
        this
    }

    public func head(pattern: String, handler: JoyRequestHandler): JoyRouters {
        handle(["HEAD"], pattern, handler)
        this
    }

    public func handle(methods: Array<String>, pattern: String, handler: JoyRequestHandler): JoyRouters {
        let mws: ArrayList<JoyMiddlewareHandler> = ArrayList(_middlewares)
        mws.add(all: _applyMWs)
        _applyMWs.clear()
        let wrapperHandler = JoyRequestHandlerWrapper(handler, mws)
        methods |> forEach {method => addHandler(method, pattern, wrapperHandler)}
        _logger.debug("[Routers#handle] add route handler, pattern=${pattern}, methods=${methods}")
        this
    }

    private func groupHandle(methods: Array<String>, pattern: String, handler: JoyRequestHandler): JoyRouters {
        let wrapperHandler = JoyRequestHandlerWrapper(handler, _middlewares)
        methods |> forEach {method => addHandler(method, pattern, wrapperHandler)}
        _logger.debug("[Routers#groupHandle] add groute route handler, pattern=${pattern}, methods=${methods}")
        this
    }

    public func staticFs(relativePath: String, root: String): JoyRouters {
        let fp = canonicalize(root)
        if (!exists(fp)) {
            throw FSException("not existed file system root, root=${root}")
        }

        let path = if (relativePath[relativePath.size - 1] == b'/') {
            relativePath + "*"
        } else {
            relativePath + "/*"
        }

        handle(["GET"], path, JoyFileSystemServeHandler(fp, _distributor._config))
        this
    }

    public func staticFile(relativePath: String, filepath: String): JoyRouters {
        let fp = canonicalize(filepath)
        if (!exists(fp)) {
            throw FSException("not existed file, filepath=${filepath}")
        }

        let fi = FileInfo(fp)
        if (fi.isDirectory() || fi.isHidden() || !fi.canRead()) {
            throw FSException("invalid file, filepath=${filepath}")
        }

        handle(["GET"], relativePath, JoyFileServeHandler(fp.toString()))
        this
    }

    public func websocket(pattern: String, handler: JoyWebSocketHandler): JoyRouters {
        handle(["GET"], pattern, JoyWebSocketUpgradeHandler(handler))
        this
    }
}
