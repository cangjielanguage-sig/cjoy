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
 * 用于定义和管理路由的路由器接口
 */
public interface JoyRouters {
    /**
     * 获取分发器实例
     *
     * @return 分发器实例
     */
    prop distributor: HttpRequestDistributor

    /**
     * 将中间件处理器追加到中间件栈。
     *
     * 任何路由器的中间件栈都会在搜索匹配路由到特定处理器之前执行，
     * 这提供了提前响应、改变请求执行流程的机会。
     *
     * @param mws 要添加的中间件处理器数组
     * @return 当前路由器实例，用于方法链式调用
     */
    func use(mws: Array<JoyMiddlewareHandler>): JoyRouters
    func use(mw: JoyMiddlewareFunc): JoyRouters {
        use(JoyMiddlewareFuncHandler(mw))
    }

    /**
     * 为端点处理器添加内联中间件。
     *
     * @param mws 要添加的中间件处理器数组
     * @return 当前路由器实例，用于方法链式调用
     */
    func apply(mws: Array<JoyMiddlewareHandler>): JoyRouters
    func apply(mw: JoyMiddlewareFunc): JoyRouters {
        apply(JoyMiddlewareFuncHandler(mw))
    }

    /**
     * 创建一个带有中间件栈副本的新内联路由器。这对于使用额外中间件集合的
     * 同一路径上的一组处理器非常有用。
     *
     * @param relativePath 新组的相对路径
     * @return 新的路由器组实例
     */
    func group(relativePath: String): JoyRouters

    /**
     * 通过完整路径查找组
     *
     * @param path 要查找的组的完整路径
     * @return 匹配的路由器组
     */
    func findGroup(path: String): JoyRouters

    /**
     * 递归创建一组按 '/' 分割的路由。调用 createGroups("/a/b/c") 等同于
     * 调用 group("/a").group("/b").group("/c")
     *
     * @param path 用于创建组的路径
     * @return 最后创建的路由器组
     */
    func createGroups(path: String): JoyRouters

    /**
     * 用于在提供的函数内定义具有公共前缀的路由。
     * 它重用 group 方法来创建子路由器。
     *
     * @param relativePath 路由组的相对路径
     * @param fn 用于在组内定义路由的函数
     * @return 创建的路由器组
     */
    func route(relativePath: String, fn: (router: JoyRouters) -> Unit): JoyRouters {
        let g = group(relativePath)
        fn(g)
        g
    }

    /**
     * 获取路由基础前缀路径
     *
     * @return 基础前缀路径
     */
    func basePath(): String

    /**
     * 添加匹配 `GET` HTTP 方法的路由 `pattern` 来执行 `handler`。
     *
     * @param pattern 路由模式
     * @param handler 请求处理器
     * @return 当前路由器实例，用于方法链式调用
     */
    func get(pattern: String, handler: JoyRequestHandler): JoyRouters
    func get(pattern: String, handler: JoyRequestHandlerFunc): JoyRouters {
        get(pattern, JoyFuncHandler(handler))
    }

    /**
     * 添加匹配 `POST` HTTP 方法的路由 `pattern` 来执行 `handler`。
     *
     * @param pattern 路由模式
     * @param handler 请求处理器
     * @return 当前路由器实例，用于方法链式调用
     */
    func post(pattern: String, handler: JoyRequestHandler): JoyRouters
    func post(pattern: String, handler: JoyRequestHandlerFunc): JoyRouters {
        post(pattern, JoyFuncHandler(handler))
    }

    /**
     * 添加匹配 `PUT` HTTP 方法的路由 `pattern` 来执行 `handler`。
     *
     * @param pattern 路由模式
     * @param handler 请求处理器
     * @return 当前路由器实例，用于方法链式调用
     */
    func put(pattern: String, handler: JoyRequestHandler): JoyRouters
    func put(pattern: String, handler: JoyRequestHandlerFunc): JoyRouters {
        put(pattern, JoyFuncHandler(handler))
    }

    /**
     * 添加匹配 `DELETE` HTTP 方法的路由 `pattern` 来执行 `handler`。
     *
     * @param pattern 路由模式
     * @param handler 请求处理器
     * @return 当前路由器实例，用于方法链式调用
     */
    func delete(pattern: String, handler: JoyRequestHandler): JoyRouters
    func delete(pattern: String, handler: JoyRequestHandlerFunc): JoyRouters {
        delete(pattern, JoyFuncHandler(handler))
    }

    /**
     * 添加匹配 `PATCH` HTTP 方法的路由 `pattern` 来执行 `handler`。
     *
     * @param pattern 路由模式
     * @param handler 请求处理器
     * @return 当前路由器实例，用于方法链式调用
     */
    func patch(pattern: String, handler: JoyRequestHandler): JoyRouters
    func patch(pattern: String, handler: JoyRequestHandlerFunc): JoyRouters {
        patch(pattern, JoyFuncHandler(handler))
    }

    /**
     * 添加匹配 `OPTIONS` HTTP 方法的路由 `pattern` 来执行 `handler`。
     *
     * @param pattern 路由模式
     * @param handler 请求处理器
     * @return 当前路由器实例，用于方法链式调用
     */
    func options(pattern: String, handler: JoyRequestHandler): JoyRouters
    func options(pattern: String, handler: JoyRequestHandlerFunc): JoyRouters {
        options(pattern, JoyFuncHandler(handler))
    }

    /**
     * 添加匹配 `HEAD` HTTP 方法的路由 `pattern` 来执行 `handler`。
     *
     * @param pattern 路由模式
     * @param handler 请求处理器
     * @return 当前路由器实例，用于方法链式调用
     */
    func head(pattern: String, handler: JoyRequestHandler): JoyRouters
    func head(pattern: String, handler: JoyRequestHandlerFunc): JoyRouters {
        head(pattern, JoyFuncHandler(handler))
    }

    /**
     * 添加匹配 `method` HTTP 方法的路由 `pattern` 来执行 `handler`。
     *
     * @param methods HTTP 方法数组
     * @param pattern 路由模式
     * @param handler 请求处理器
     * @return 当前路由器实例，用于方法链式调用
     */
    func handle(methods: Array<String>, pattern: String, handler: JoyRequestHandler): JoyRouters
    func handle(methods: Array<String>, pattern: String, handler: JoyRequestHandlerFunc): JoyRouters {
        handle(methods, pattern, JoyFuncHandler(handler))
    }

    /**
     * 从给定的文件系统 `root` 提供 URL 路径为 `relativePath` 的文件。
     *
     * @param relativePath 相对 URL 路径
     * @param root 本地文件系统根目录
     * @return 当前路由器实例，用于方法链式调用
     */
    func staticFs(relativePath: String, root: String): JoyRouters

    /**
     * 注册单个路由，使用 URL 路径 `relativePath` 来提供本地文件系统的单个文件。
     *
     * @param relativePath 相对 URL 路径
     * @param filepath 本地文件系统文件路径
     * @return 当前路由器实例，用于方法链式调用
     */
    func staticFile(relativePath: String, filepath: String): JoyRouters

    /**
     * 添加匹配 `GET` HTTP 方法的路由 `pattern` 来处理 WebSocket 请求。
     *
     * @param pattern 路由模式
     * @param handler WebSocket 处理器
     * @return 当前路由器实例，用于方法链式调用
     */
    func websocket(pattern: String, handler: JoyWebSocketHandler): JoyRouters

    /**
     * 打印路由树
     *
     * @return 路由树的字符串表示
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
     * 使用给定名称和处理程序实例注册一个处理程序
     *
     * @param _: 处理程序名称
     * @param _: 处理程序实例
     * @throws UnsupportedException 始终抛出，因为此方法不被支持
     */
    public func register(_: String, _: HttpRequestHandler): Unit {
        throw UnsupportedException("unsupported this method")
    }

    /**
     * 将请求分发到适当的处理程序
     *
     * @param _: 请求路径
     * @return 返回自身作为处理程序
     */
    public func distribute(_: String): HttpRequestHandler {
        // redirect to handle method
        this
    }

    /**
     * 处理传入的 HTTP 请求
     *
     * @param ctx HTTP 上下文
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
        if (path != "/") {
            path = path.removeSuffix("/")
        }
        
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
     * 将路由树以字符串形式输出用于调试
     *
     * @return 路由树的结构字符串
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
     * 将路由树以字符串形式输出用于调试
     *
     * @return 路由树的结构字符串
     */
    public func dump(): String {
        _distributor._root.dumpTree()
    }

    /**
     * 将中间件处理器追加到中间件栈
     *
     * @param mws 要添加的中间件处理器数组
     * @return 当前路由器实例，支持方法链式调用
     */
    public func use(mws: Array<JoyMiddlewareHandler>): JoyRouters {
        mws |> forEach {mw => _middlewares.add(mw)}
        this
    }

    /**
     * 为后续路由注册添加内联中间件处理器
     *
     * @param mws 要添加的中间件处理器数组
     * @return 当前路由器实例，支持方法链式调用
     */
    public func apply(mws: Array<JoyMiddlewareHandler>): JoyRouters {
        mws |> forEach {mw => _applyMWs.add(mw)}
        this
    }

    /**
     * 创建一个带有当前中间件栈副本的新路由组
     *
     * @param relativePath 新组的相对路径
     * @return 新的路由组实例
     * @throws IllegalArgumentException 如果相对路径为空
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
     * 查找与给定路径匹配的路由组
     *
     * @param path 要搜索的路径
     * @return 匹配的路由组，如果未找到则返回当前路由
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
     * 递归从给定路径创建一组嵌套的路由组
     *
     * @param path: 用于创建分组的路径（示例："/a/b/c" 将创建三个嵌套分组）
     * @return 最后创建的路由组
     */
    public func createGroups(path: String): JoyRouters {
        checkPath(path)
        if (path.isEmpty() || path.size == 1) {
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
            if (!s.isEmpty()) {
                gr = gr.group("/" + s)
            }
        }
        gr
    }

    /**
     * @throws IllegalArgumentException 如果路径不是以斜杠结尾
     */
    private static func checkPath(path: String): Unit {
        if (path.size > 1 && path[0] != b'/') {
            throw IllegalArgumentException("path [${path}] must start with slash")
        }
        if (path.contains("//")) {
            throw IllegalArgumentException("path [${path}] must not contain consecutive slashes")
        }
    }

    /**
     * @throws IllegalArgumentException 如果分组路径已存在
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
        let thePath = if (path == "/") {
            path
        } else if (_distributor._config.caseInsensitive) {
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
        handle([JoyHttpConsts.METHOD_GET, JoyHttpConsts.METHOD_HEAD], path,
            factory.createFileSystemServeHandler(fp, _distributor._config))
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
        handle([JoyHttpConsts.METHOD_GET, JoyHttpConsts.METHOD_HEAD], relativePath,
            factory.createFileServeHandler(fp.toString()))
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
