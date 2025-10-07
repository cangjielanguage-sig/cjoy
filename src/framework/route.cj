/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.framework

import std.collection.{ArrayList, HashMap, forEach}
import std.fs.{canonicalize, FSException, exists, FileInfo}
import stdx.encoding.url.URL
import stdx.net.http.{HttpRequestDistributor, HttpRequestHandler, HttpRequest, HttpContext}
import cjoy.context.ServiceConainter
import cjoy.log.*

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
    func use(mws: Array<JoyMiddlewareHandler>): JoyRouters
    func use(mw: JoyMiddlewareFunc): JoyRouters {
        use(JoyMiddlewareFuncHandler(mw))
    }

    /**
     * adds inline middlewares for an endpoint handler.
     */
    func apply(mws: Array<JoyMiddlewareHandler>): JoyRouters
    func apply(mw: JoyMiddlewareFunc): JoyRouters {
        apply(JoyMiddlewareFuncHandler(mw))
    }

    /**
     * creates a new inline router with a copy of middleware stack. it's useful
     * for a group of handlers along the same routing path that use an additional
     * set of middlewares.
     */
    func group(relativePath: String): JoyRouters

    /**
     * find group by the full path
     */
    func findGroup(path: String): JoyRouters

    /**
     * recursive creates a set of routes split by '/', invoke createGroups("/a/b/c") method is same as
     * invoke group("/a").group("/b").group("/c")
     */
    func createGroups(path: String): JoyRouters

    /**
     * used to define routes with a common prefix inside the supplied function.
     * it reuses the group method to create a sub-router.
     */
    func route(relativePath: String, fn: (router: JoyRouters) -> Unit): JoyRouters {
        let g = group(relativePath)
        fn(g)
        g
    }

    /**
     * return the route base prefix path
     */
    func basePath(): String

    /**
     * adds the route `pattern` that matches `GET` http method to execute the `handler`.
     */
    func get(pattern: String, handler: JoyRequestHandler): JoyRouters
    func get(pattern: String, handler: JoyRequestHandlerFunc): JoyRouters {
        get(pattern, JoyFuncHandler(handler))
    }

    /**
     * adds the route `pattern` that matches `POST` http method to execute the `handler`.
     */
    func post(pattern: String, handler: JoyRequestHandler): JoyRouters
    func post(pattern: String, handler: JoyRequestHandlerFunc): JoyRouters {
        post(pattern, JoyFuncHandler(handler))
    }

    /**
     * adds the route `pattern` that matches `PUT` http method to execute the `handler`.
     */
    func put(pattern: String, handler: JoyRequestHandler): JoyRouters
    func put(pattern: String, handler: JoyRequestHandlerFunc): JoyRouters {
        put(pattern, JoyFuncHandler(handler))
    }

    /**
     * adds the route `pattern` that matches `DELETE` http method to execute the `handler`.
     */
    func delete(pattern: String, handler: JoyRequestHandler): JoyRouters
    func delete(pattern: String, handler: JoyRequestHandlerFunc): JoyRouters {
        delete(pattern, JoyFuncHandler(handler))
    }

    /**
     * adds the route `pattern` that matches `PATCH` http method to execute the `handler`.
     */
    func patch(pattern: String, handler: JoyRequestHandler): JoyRouters
    func patch(pattern: String, handler: JoyRequestHandlerFunc): JoyRouters {
        patch(pattern, JoyFuncHandler(handler))
    }

    /**
     * adds the route `pattern` that matches `OPTIONS` http method to execute the `handler`.
     */
    func options(pattern: String, handler: JoyRequestHandler): JoyRouters
    func options(pattern: String, handler: JoyRequestHandlerFunc): JoyRouters {
        options(pattern, JoyFuncHandler(handler))
    }

    /**
     * adds the route `pattern` that matches `HEAD` http method to execute the `handler`.
     */
    func head(pattern: String, handler: JoyRequestHandler): JoyRouters
    func head(pattern: String, handler: JoyRequestHandlerFunc): JoyRouters {
        head(pattern, JoyFuncHandler(handler))
    }

    /**
     * adds the route `pattern` that matches `method` http method to execute the `handler`.
     */
    func handle(methods: Array<String>, pattern: String, handler: JoyRequestHandler): JoyRouters
    func handle(methods: Array<String>, pattern: String, handler: JoyRequestHandlerFunc): JoyRouters {
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
    let _services: ServiceConainter
    let _groups: HashMap<String, JoyRouters> = HashMap()

    init(config: JoyConfig, services: ServiceConainter) {
        _config = config
        _services = services
    }

    /**
     * @throws UnsupportedException not supportd register any handler using the func
     */
    public func register(_: String, _: HttpRequestHandler): Unit {
        throw UnsupportedException("unsupported this method")
    }

    public func distribute(_: String): HttpRequestHandler {
        // redirect to handle method
        this
    }

    public func handle(ctx: HttpContext): Unit {
        let target: RouteInfo<JoyRequestHandler> = lookup(ctx.request)
        let ctxParamMap = if (target.methodNotAllowed) {
            HashMap<String, Any>([("methods", target.methodsAllowed)])
        } else {
            HashMap<String, Any>()
        }
        let joyCtx = JoyHttpContext(_services, ctx, target.getParams(), _config, ctxParamMap)
        target.handler?.handle(joyCtx)
    }

    private func lookup(req: HttpRequest): RouteInfo<JoyRequestHandler> {
        var path = if (_config.caseInsensitive) {
            req.url.path.toAsciiLower()
        } else {
            req.url.path
        }
        path = path.removeSuffix("/")

        let ri: RouteInfo<JoyRequestHandler> = RouteInfo()
        var node = _root.findRouteHandler(ri, req.method, path)
        if (node.isNone()) {
            @LogDebug("not found handler, method=${req.method}, path=${path}")
            ri.handler = _config.notFoundHandler
            return ri
        }

        if (ri.handler.isNone()) {
            if (req.method == JoyHttpConsts.METHOD_OPTIONS) {
                ri.handler = JoyOptionsHandler.INSTANCE
                return ri
            }

            if (ri.methodNotAllowed) {
                ri.handler = _config.methodNotAllowedHandler
                return ri
            }

            @LogDebug("not found handler, method=${req.method}, path=${path}")
            ri.handler = _config.notFoundHandler
            return ri
        }
        ri
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

    init(path: String, distributor: TreeRouteDistributor, middlewares: ArrayList<JoyMiddlewareHandler>) {
        _path = path
        _distributor = distributor
        _middlewares = middlewares
    }

    init(config: JoyConfig, services: ServiceConainter) {
        this("", TreeRouteDistributor(config, services), ArrayList())
    }

    public prop distributor: HttpRequestDistributor {
        get() {
            _distributor
        }
    }

    public func dump(): String {
        _distributor._root.dumpTree()
    }

    public func use(mws: Array<JoyMiddlewareHandler>): JoyRouters {
        mws |> forEach {mw => _middlewares.add(mw)}
        this
    }

    public func apply(mws: Array<JoyMiddlewareHandler>): JoyRouters {
        mws |> forEach {mw => _applyMWs.add(mw)}
        this
    }

    /**
     * @throws IllegalArgumentException if the relative path is empty
     */
    public func group(relativePath: String): JoyRouters {
        if (relativePath.isEmpty()) {
            throw IllegalArgumentException("group relativePath must not be empty")
        }
        checkPath(relativePath)

        var path = _path + relativePath
        // don't want trailing slash as all sub-paths start with slash
        path = path.removeSuffix("/")

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
                let idx = search.lastIndexOf(b'/') ?? -1
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

    /**
     * @throws IllegalArgumentException if the path not is end with slash
     */
    private static func checkPath(path: String): Unit {
        if (path.size > 1 && path[0] != b'/') {
            throw IllegalArgumentException("path [${path}] must start with slash")
        }
    }

    /**
     * @throws IllegalArgumentException if the group path has existed
     */
    private func setGroupDefaultHandler(): Unit {
        if (_distributor._root.findPattern(_path + "*") || _distributor._root.findPattern(_path + "/*")) {
            throw IllegalArgumentException("a handler on an existing path, `${_path}`")
        }

        let allMethods = [JoyHttpConsts.METHOD_GET, JoyHttpConsts.METHOD_POST, JoyHttpConsts.METHOD_DELETE,
            JoyHttpConsts.METHOD_PUT, JoyHttpConsts.METHOD_PATCH, JoyHttpConsts.METHOD_HEAD,
            JoyHttpConsts.METHOD_OPTIONS]
        groupHandle(allMethods, "", JoyGroupRouteHandler.INSTANCE)
        var xpattern = "/"
        xpattern = xpattern + "*"
        groupHandle(allMethods, xpattern, JoyGroupRouteHandler.INSTANCE)
    }

    public func basePath(): String {
        _path
    }

    private func addOne(method: String, path: String, handler: JoyRequestHandler): Unit {
        let thePath = if (_distributor._config.caseInsensitive) {
            path.toAsciiLower().removeSuffix("/")
        } else {
            path.removeSuffix("/")
        }
        _distributor._root.addRoute(method, thePath, handler)
    }

    /**
     * @throws IllegalArgumentException if the path is empty
     */
    private func addHandler(method: String, path: String, handler: JoyRequestHandler): Unit {
        checkPath(path)
        var thePath = _path + path
        if (thePath.isEmpty()) {
            throw IllegalArgumentException("cannot add a handle for an empty path")
        }

        if (_distributor._config.escapeAddedRoutes) {
            let escapedPath = unescapeSpecial(thePath)
            if (thePath != escapedPath) {
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
        handle([JoyHttpConsts.METHOD_GET], pattern, handler)
        this
    }

    public func post(pattern: String, handler: JoyRequestHandler): JoyRouters {
        handle([JoyHttpConsts.METHOD_POST], pattern, handler)
        this
    }

    public func put(pattern: String, handler: JoyRequestHandler): JoyRouters {
        handle([JoyHttpConsts.METHOD_PUT], pattern, handler)
        this
    }

    public func delete(pattern: String, handler: JoyRequestHandler): JoyRouters {
        handle([JoyHttpConsts.METHOD_DELETE], pattern, handler)
        this
    }

    public func patch(pattern: String, handler: JoyRequestHandler): JoyRouters {
        handle([JoyHttpConsts.METHOD_PATCH], pattern, handler)
        this
    }

    public func options(pattern: String, handler: JoyRequestHandler): JoyRouters {
        handle([JoyHttpConsts.METHOD_OPTIONS], pattern, handler)
        this
    }

    public func head(pattern: String, handler: JoyRequestHandler): JoyRouters {
        handle([JoyHttpConsts.METHOD_HEAD], pattern, handler)
        this
    }

    public func handle(methods: Array<String>, pattern: String, handler: JoyRequestHandler): JoyRouters {
        let mws: ArrayList<JoyMiddlewareHandler> = ArrayList(_middlewares)
        mws.add(all: _applyMWs)
        _applyMWs.clear()
        let wrapperHandler = JoyRequestHandlerWrapper(handler, mws)
        methods |> forEach {method => addHandler(method, pattern, wrapperHandler)}
        @LogInfo("add route handler, path=${_path}${pattern}, methods=${methods}")
        this
    }

    private func groupHandle(methods: Array<String>, pattern: String, handler: JoyRequestHandler): JoyRouters {
        let wrapperHandler = JoyRequestHandlerWrapper(handler, _middlewares)
        methods |> forEach {method => addHandler(method, pattern, wrapperHandler)}
        @LogInfo("add route route handler, path=${_path}${pattern}, methods=${methods}")
        this
    }

    public func staticFs(relativePath: String, root: String): JoyRouters {
        let fp = canonicalize(root)
        if (!exists(fp)) {
            throw FSException("not existed file system root, root=${root}")
        }

        let fi = FileInfo(fp)
        if (!fi.isDirectory() || !fi.canRead()) {
            throw FSException("invalid file system root, root=${root}")
        }

        let path = if (relativePath[relativePath.size - 1] == b'/') {
            relativePath + "*"
        } else {
            relativePath + "/*"
        }

        handle([JoyHttpConsts.METHOD_GET], path, JoyFileSystemServeHandler(fp, _distributor._config))
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

        handle([JoyHttpConsts.METHOD_GET], relativePath, JoyFileServeHandler(fp.toString()))
        this
    }

    public func websocket(pattern: String, handler: JoyWebSocketHandler): JoyRouters {
        handle([JoyHttpConsts.METHOD_GET], pattern, JoyWebSocketUpgradeHandler(handler))
        this
    }
}
