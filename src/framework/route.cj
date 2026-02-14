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

import std.collection.{ArrayList, HashMap, forEach}
import std.fs.{canonicalize, FSException, exists, FileInfo}
import stdx.encoding.url.URL
import stdx.net.http.{HttpRequestDistributor, HttpRequestHandler, HttpRequest, HttpContext}
import cjoy.context.ServiceContainer
import cjoy.ioc.BeanFactoryManager
import cjoy.log.macros.*

/**
 * Router interface for defining and managing routes
 */
public interface JoyRouters {
    /**
     * Gets the distributor instance
     *
     * @return The distributor instance
     */
    prop distributor: HttpRequestDistributor

    /**
     * appends a middleware handler to the middleware stack.
     *
     * The middleware stack for any router will execute before searching for a matching
     * route to a specific handler, which provides opportunity to respond early,
     * change the course of the request execution.
     *
     * @param mws the array of middleware handlers to add
     * @return the current router instance for method chaining
     */
    func use(mws: Array<JoyMiddlewareHandler>): JoyRouters
    func use(mw: JoyMiddlewareFunc): JoyRouters {
        use(JoyMiddlewareFuncHandler(mw))
    }

    /**
     * adds inline middlewares for an endpoint handler.
     *
     * @param mws the array of middleware handlers to add
     * @return the current router instance for method chaining
     */
    func apply(mws: Array<JoyMiddlewareHandler>): JoyRouters
    func apply(mw: JoyMiddlewareFunc): JoyRouters {
        apply(JoyMiddlewareFuncHandler(mw))
    }

    /**
     * creates a new inline router with a copy of middleware stack. it's useful
     * for a group of handlers along the same routing path that use an additional
     * set of middlewares.
     *
     * @param relativePath the relative path for the new group
     * @return the new router group instance
     */
    func group(relativePath: String): JoyRouters

    /**
     * Finds a group by the full path
     *
     * @param path The full path of the group to find
     * @return The matching router group
     */
    func findGroup(path: String): JoyRouters

    /**
     * Recursively creates a set of routes split by '/'. Invoking createGroups("/a/b/c") is the same as
     * invoking group("/a").group("/b").group("/c")
     *
     * @param path The path to create groups from
     * @return The last created router group
     */
    func createGroups(path: String): JoyRouters

    /**
     * used to define routes with a common prefix inside the supplied function.
     * it reuses the group method to create a sub-router.
     *
     * @param relativePath the relative path for the route group
     * @param fn the function to define routes within the group
     * @return the created router group
     */
    func route(relativePath: String, fn: (router: JoyRouters) -> Unit): JoyRouters {
        let g = group(relativePath)
        fn(g)
        g
    }

    /**
     * Gets the route base prefix path
     *
     * @return The base prefix path
     */
    func basePath(): String

    /**
     * adds the route `pattern` that matches `GET` http method to execute the `handler`.
     *
     * @param pattern the route pattern
     * @param handler the request handler
     * @return the current router instance for method chaining
     */
    func get(pattern: String, handler: JoyRequestHandler): JoyRouters
    func get(pattern: String, handler: JoyRequestHandlerFunc): JoyRouters {
        get(pattern, JoyFuncHandler(handler))
    }

    /**
     * adds the route `pattern` that matches `POST` http method to execute the `handler`.
     *
     * @param pattern the route pattern
     * @param handler the request handler
     * @return the current router instance for method chaining
     */
    func post(pattern: String, handler: JoyRequestHandler): JoyRouters
    func post(pattern: String, handler: JoyRequestHandlerFunc): JoyRouters {
        post(pattern, JoyFuncHandler(handler))
    }

    /**
     * adds the route `pattern` that matches `PUT` http method to execute the `handler`.
     *
     * @param pattern the route pattern
     * @param handler the request handler
     * @return the current router instance for method chaining
     */
    func put(pattern: String, handler: JoyRequestHandler): JoyRouters
    func put(pattern: String, handler: JoyRequestHandlerFunc): JoyRouters {
        put(pattern, JoyFuncHandler(handler))
    }

    /**
     * adds the route `pattern` that matches `DELETE` http method to execute the `handler`.
     *
     * @param pattern the route pattern
     * @param handler the request handler
     * @return the current router instance for method chaining
     */
    func delete(pattern: String, handler: JoyRequestHandler): JoyRouters
    func delete(pattern: String, handler: JoyRequestHandlerFunc): JoyRouters {
        delete(pattern, JoyFuncHandler(handler))
    }

    /**
     * adds the route `pattern` that matches `PATCH` http method to execute the `handler`.
     *
     * @param pattern the route pattern
     * @param handler the request handler
     * @return the current router instance for method chaining
     */
    func patch(pattern: String, handler: JoyRequestHandler): JoyRouters
    func patch(pattern: String, handler: JoyRequestHandlerFunc): JoyRouters {
        patch(pattern, JoyFuncHandler(handler))
    }

    /**
     * adds the route `pattern` that matches `OPTIONS` http method to execute the `handler`.
     *
     * @param pattern the route pattern
     * @param handler the request handler
     * @return the current router instance for method chaining
     */
    func options(pattern: String, handler: JoyRequestHandler): JoyRouters
    func options(pattern: String, handler: JoyRequestHandlerFunc): JoyRouters {
        options(pattern, JoyFuncHandler(handler))
    }

    /**
     * adds the route `pattern` that matches `HEAD` http method to execute the `handler`.
     *
     * @param pattern the route pattern
     * @param handler the request handler
     * @return the current router instance for method chaining
     */
    func head(pattern: String, handler: JoyRequestHandler): JoyRouters
    func head(pattern: String, handler: JoyRequestHandlerFunc): JoyRouters {
        head(pattern, JoyFuncHandler(handler))
    }

    /**
     * adds the route `pattern` that matches `method` http method to execute the `handler`.
     *
     * @param methods the array of http methods
     * @param pattern the route pattern
     * @param handler the request handler
     * @return the current router instance for method chaining
     */
    func handle(methods: Array<String>, pattern: String, handler: JoyRequestHandler): JoyRouters
    func handle(methods: Array<String>, pattern: String, handler: JoyRequestHandlerFunc): JoyRouters {
        handle(methods, pattern, JoyFuncHandler(handler))
    }

    /**
     * Serves files with URL path `relativePath` from the given file system `root`.
     *
     * @param relativePath The relative URL path
     * @param root The local filesystem root directory
     * @return The current router instance for method chaining
     */
    func staticFs(relativePath: String, root: String): JoyRouters

    /**
     * Registers a single route with URL path `relativePath` to serve a single file of the local filesystem.
     *
     * @param relativePath The relative URL path
     * @param filepath The local filesystem file path
     * @return The current router instance for method chaining
     */
    func staticFile(relativePath: String, filepath: String): JoyRouters

    /**
     * Adds the route `pattern` that matches `GET` HTTP method to process websocket request.
     *
     * @param pattern The route pattern
     * @param handler The websocket handler
     * @return The current router instance for method chaining
     */
    func websocket(pattern: String, handler: JoyWebSocketHandler): JoyRouters

    /**
     * Dumps the route tree
     *
     * @return The string representation of the route tree
     */
    func dump(): String
}

class TreeRouteDistributor <: HttpRequestDistributor & HttpRequestHandler {
    var _root: TreeNode<JoyRequestHandler> = TreeNode(NT_STATIC, b'\0', "")
    let _config: JoyConfig
    let _services: ServiceContainer
    let _groups: HashMap<String, JoyRouters> = HashMap()

    init(config: JoyConfig, services: ServiceContainer) {
        _config = config
        _services = services
    }

    /**
     * registers a handler with the given name and handler instance
     *
     * @param _: the handler name
     * @param _: the handler instance
     * @throws UnsupportedException always thrown, as this method is not supported
     */
    public func register(_: String, _: HttpRequestHandler): Unit {
        throw UnsupportedException("unsupported this method")
    }

    /**
     * distributes the request to the appropriate handler
     *
     * @param _: the request path
     * @return this instance as the handler
     */
    public func distribute(_: String): HttpRequestHandler {
        // redirect to handle method
        this
    }

    /**
     * Handles the incoming HTTP request
     *
     * @param ctx The HTTP context
     */
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
            @JoyLogDebug("not found handler, method=${req.method}, path=${path}")
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

            @JoyLogDebug("not found handler, method=${req.method}, path=${path}")
            ri.handler = _config.notFoundHandler
            return ri
        }
        ri
    }

    /**
     * dump the route tree as a string for debugging
     *
     * @return the route tree structure string
     */
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

    init(config: JoyConfig, services: ServiceContainer) {
        this("", TreeRouteDistributor(config, services), ArrayList())
    }

    public prop distributor: HttpRequestDistributor {
        get() {
            _distributor
        }
    }

    /**
     * dump the route tree as a string for debugging
     *
     * @return the route tree structure string
     */
    public func dump(): String {
        _distributor._root.dumpTree()
    }

    /**
     * appends middleware handlers to the middleware stack
     *
     * @param mws the array of middleware handlers to add
     * @return the current router instance for method chaining
     */
    public func use(mws: Array<JoyMiddlewareHandler>): JoyRouters {
        mws |> forEach {mw => _middlewares.add(mw)}
        this
    }

    /**
     * adds inline middleware handlers for subsequent route registrations
     *
     * @param mws the array of middleware handlers to add
     * @return the current router instance for method chaining
     */
    public func apply(mws: Array<JoyMiddlewareHandler>): JoyRouters {
        mws |> forEach {mw => _applyMWs.add(mw)}
        this
    }

    /**
     * creates a new router group with a copy of the current middleware stack
     *
     * @param relativePath the relative path for the new group
     * @return the new router group instance
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

    /**
     * Finds the router group that matches the given path
     *
     * @param path The path to search for
     * @return The matching router group, or the current router if no match is found
     */
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

    /**
     * recursively creates a set of nested router groups from the given path
     *
     * @param path: the path to create groups from (e.g., "/a/b/c" creates three nested groups)
     * @return the last created router group
     */
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
        @JoyLogInfo("add route handler, path=${_path}${pattern}, methods=${methods}")
        this
    }

    private func groupHandle(methods: Array<String>, pattern: String, handler: JoyRequestHandler): JoyRouters {
        let wrapperHandler = JoyRequestHandlerWrapper(handler, _middlewares)
        methods |> forEach {method => addHandler(method, pattern, wrapperHandler)}
        @JoyLogInfo("add route route handler, path=${_path}${pattern}, methods=${methods}")
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

        let factory = getJoyFileHandlerFactory()
        handle([JoyHttpConsts.METHOD_GET, JoyHttpConsts.METHOD_HEAD], path, factory.createFileSystemServeHandler(fp, _distributor._config))
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

        let factory = getJoyFileHandlerFactory()
        handle([JoyHttpConsts.METHOD_GET, JoyHttpConsts.METHOD_HEAD], relativePath, factory.createFileServeHandler(fp.toString()))
        this
    }

    private func getJoyFileHandlerFactory(): JoyFileHandlerFactory {
        BeanFactoryManager.initAllBeans()
        BeanFactoryManager.getApplicationContext().getBean<JoyFileHandlerFactory>().getOrThrow()
    }

    public func websocket(pattern: String, handler: JoyWebSocketHandler): JoyRouters {
        handle([JoyHttpConsts.METHOD_GET], pattern, JoyWebSocketUpgradeHandler(handler))
        this
    }
}
