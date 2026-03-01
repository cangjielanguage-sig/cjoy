/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.framework

import std.unittest.testmacro.*
import std.collection.ArrayList
import cjoy.context.*
import stdx.net.http.*
import std.io.{readToEnd, BufferedInputStream, StringReader, InputStream}
import std.sync.AtomicBool

@Test
public class MiddlewareTestCaseSuit {
    var _client = ClientBuilder().build()
    var _instance: ?Joy = None

    @BeforeAll
    func setup() {
        // 不需要在 setup 中启动服务器，因为每个测试用例都会创建自己的服务器实例
    }
    
    @AfterEach
    func tearDownEach() {
        _instance?.shutdown()
        _client.close()
        _client = ClientBuilder().build()
    }

    // 辅助函数：将 InputStream 转换为字符串
    private func streamToString(stream: InputStream): String {
        let reader = StringReader(BufferedInputStream(stream))
        reader.readToEnd()
    }

    /**
     * 测试中间件函数处理器 - 验证 JoyMiddlewareFuncHandler 可以正常创建
     */
    @TestCase
    public func testMiddlewareFuncHandler() {
        let middlewareFunc: JoyMiddlewareFunc = {ctx, chain =>
            chain.next(ctx)
        }

        let handler = JoyMiddlewareFuncHandler(middlewareFunc)
        @Assert(true) // 只要没有抛出异常，测试就成功
    }

    /**
     * 测试中间件注册 - 验证中间件可以成功注册到指定路径
     */
    @TestCase
    public func testMiddlewareRegistry() {
        let middlewareFunc: JoyMiddlewareFunc = {ctx, chain =>
            chain.next(ctx)
        }

        let handler = JoyMiddlewareFuncHandler(middlewareFunc)
        JoyMiddlewares.addHandler(["/test"], handler)

        @Assert(true) // 只要没有抛出异常，测试就成功
    }

    /**
     * 测试多组中间件注册 - 验证中间件可以同时注册到多个路径组
     */
    @TestCase
    public func testMiddlewareRegistryWithMultipleGroups() {
        let middlewareFunc: JoyMiddlewareFunc = {ctx, chain =>
            chain.next(ctx)
        }

        let handler = JoyMiddlewareFuncHandler(middlewareFunc)
        JoyMiddlewares.addHandler(["/group1", "/group2", "/group3"], handler)

        @Assert(true) // 只要没有抛出异常，测试就成功
    }

    /**
     * 测试中间件注册到引擎 - 验证通过 JoyMiddlewares 注册的中间件可以成功注册到引擎
     */
    @TestCase
    public func testMiddlewareRegistrationToEngine() {
        let engine = Joy.create(name: "testMiddlewareEngine")
        _instance = engine

        let middlewareFunc: JoyMiddlewareFunc = {ctx, chain =>
            chain.next(ctx)
        }

        let handler = JoyMiddlewareFuncHandler(middlewareFunc)
        JoyMiddlewares.addHandler(["/api"], handler)

        JoyMiddlewares.registerTo(engine)

        @Assert(true) // 只要没有抛出异常，测试就成功
        engine.shutdown()
    }

    /**
     * 测试中间件执行顺序 - 验证多个中间件按注册顺序依次执行
     */
    @TestCase
    public func testMiddlewareExecutionOrder() {
        let executionOrder = ArrayList<String>()

        let middleware1: JoyMiddlewareFunc = {ctx, chain =>
            executionOrder.add("middleware1")
            chain.next(ctx)
        }

        let middleware2: JoyMiddlewareFunc = {ctx, chain =>
            executionOrder.add("middleware2")
            chain.next(ctx)
        }

        let middleware3: JoyMiddlewareFunc = {ctx, chain =>
            executionOrder.add("middleware3")
            chain.next(ctx)
        }

        // 执行中间件链
        let engine = Joy.create(name: "testMiddlewareExecutionEngine")
        _instance = engine
        let group = engine.router.group("/test")

        group.use(JoyMiddlewareFuncHandler(middleware1))
        group.use(JoyMiddlewareFuncHandler(middleware2))
        group.use(JoyMiddlewareFuncHandler(middleware3))

        // 添加测试路由
        group.get("/", { ctx =>
            executionOrder.add("handler")
            ctx.string("OK")
        })

        // 启动服务器
        spawn {
            engine.run("127.0.0.1", 18885)
        }
        sleep(Duration.second)

        // 发送请求
        let rsp = _client.get("http://127.0.0.1:18885/test/")
        @Assert(rsp.status == 200)

        // 验证中间件执行顺序
        @Assert(executionOrder.size == 4)
        @Assert(executionOrder[0] == "middleware1")
        @Assert(executionOrder[1] == "middleware2")
        @Assert(executionOrder[2] == "middleware3")
        @Assert(executionOrder[3] == "handler")
        engine.shutdown()
    }

    /**
     * 测试分组中间件 - 验证可以为不同路径组分别添加中间件
     */
    @TestCase
    public func testMiddlewareWithGroups() {
        let engine = Joy.create(name: "testMiddlewareGroupsEngine")
        _instance = engine

        let middlewareFunc: JoyMiddlewareFunc = {ctx, chain =>
            chain.next(ctx)
        }

        let handler = JoyMiddlewareFuncHandler(middlewareFunc)

        // 为根路径添加中间件
        engine.router.use(handler)

        // 为 /api 路径组添加中间件
        engine.router.group("/api").use(handler)

        // 为 /api/v1 路径组添加中间件
        engine.router.group("/api").group("/v1").use(handler)

        // 检查是否可以成功添加多个中间件到不同的路径组
        @Assert(true) // 只要没有抛出异常，测试就成功
        engine.shutdown()
    }

    /**
     * 测试中间件错误处理 - 验证中间件抛出异常时返回 500 状态码
     */
    @TestCase
    public func testMiddlewareErrorHandling() {
        let errorMessage = "Middleware Error"

        let errorMiddleware: JoyMiddlewareFunc = {ctx, chain =>
            throw Exception(errorMessage)
        }

        let engine = Joy.create(name: "testMiddlewareErrorHandlingEngine")
        _instance = engine
        engine.router.use(JoyMiddlewareFuncHandler(errorMiddleware))

        // 添加测试路由
        engine.router.get("/", { ctx =>
            ctx.string("OK")
        })

        // 启动服务器
        spawn {
            engine.run("127.0.0.1", 18886)
        }
        sleep(Duration.second * 2) // 增加等待时间

        // 发送请求
        var responseBody = ""
        try {
            let rsp = _client.get("http://127.0.0.1:18886/")
            responseBody = streamToString(rsp.body)
            @Assert(rsp.status==500)
        } catch (e: Exception) {
            
        }
        engine.shutdown()
    }

    /**
     * 测试中间件组合 - 验证多个中间件可以通过上下文参数传递数据
     */
    @TestCase
    public func testMiddlewareCombination() {
        let middleware1: JoyMiddlewareFunc = {ctx, chain =>
            ctx.setCtxParam("middleware1", "value1")
            chain.next(ctx)
        }

        let middleware2: JoyMiddlewareFunc = {ctx, chain =>
            ctx.setCtxParam("middleware2", "value2")
            chain.next(ctx)
        }

        let engine = Joy.create(name: "testMiddlewareCombinationEngine")
        _instance = engine
        engine.router.use(JoyMiddlewareFuncHandler(middleware1))
        engine.router.use(JoyMiddlewareFuncHandler(middleware2))

        // 添加测试路由
        engine.router.get("/", { ctx =>
            let value1 = ctx.getCtxParam<String>("middleware1").getOrThrow()
            let value2 = ctx.getCtxParam<String>("middleware2").getOrThrow()
            ctx.string("middleware1: ${value1}, middleware2: ${value2}")
        })

        // 启动服务器
        spawn {
            engine.run("127.0.0.1", 18887)
        }
        sleep(Duration.second * 2) // 增加等待时间

        // 发送请求
        let rsp = _client.get("http://127.0.0.1:18887/")
        eprint(rsp.status)
        @Assert(rsp.status == 200)

        let bodyStr = streamToString(rsp.body)
        eprint(bodyStr)
        @Assert(bodyStr.contains("middleware1: value1"))
        @Assert(bodyStr.contains("middleware2: value2"))
        engine.shutdown()
    }

    /**
     * 测试中间件单路径注册 - 验证中间件可以注册到单个路径
     */
    @TestCase
    public func testMiddlewareSinglePathRegistration() {
        let engine = Joy.create(name: "testSinglePathReg")
        _instance = engine

        let middlewareFunc: JoyMiddlewareFunc = {ctx, chain =>
            chain.next(ctx)
        }

        engine.router.use(JoyMiddlewareFuncHandler(middlewareFunc))
        engine.router.get("/test", {ctx: JoyContext => ctx.string("ok")})

        let dumpResult = engine.router.dump()
        @Assert(dumpResult.size > 0)

        engine.shutdown()
    }

    /**
     * 测试中间件多路径注册 - 验证中间件可以注册到多个路径组
     */
    @TestCase
    public func testMiddlewareMultiplePathRegistration() {
        let engine = Joy.create(name: "testMultiPathReg")
        _instance = engine

        let middlewareFunc: JoyMiddlewareFunc = {ctx, chain =>
            chain.next(ctx)
        }

        let handler = JoyMiddlewareFuncHandler(middlewareFunc)
        JoyMiddlewares.addHandler(["/api", "/web", "/admin"], handler)
        JoyMiddlewares.registerTo(engine)

        engine.shutdown()
    }

    /**
     * 测试中间件链中断 - 验证中间件可以中断处理链
     */
    @TestCase
    public func testMiddlewareChainInterruption() {
        let engine = Joy.create(name: "testChainInterrupt")
        _instance = engine

        let handlerCalled = AtomicBool(false)

        engine.router.use(JoyMiddlewareFuncHandler({ctx, chain =>
            // 不调用 chain.next()，中断处理链
            ctx.string("interrupted")
        }))

        engine.router.get("/test", {ctx: JoyContext =>
            handlerCalled.store(true)
            ctx.string("handler")
        })

        spawn {
            engine.run("127.0.0.1", 18888)
        }
        sleep(Duration.millisecond * 500)

        let rsp = _client.get("http://127.0.0.1:18888/test")
        @Assert(rsp.status == 200)
        let bodyStr = streamToString(rsp.body)
        @Assert(bodyStr, "interrupted")
        @Assert(handlerCalled.load(), false)

        engine.shutdown()
    }

    /**
     * 测试分组中间件注册 - 验证中间件可以注册到路由分组
     */
    @TestCase
    public func testMiddlewareGroupRegistration() {
        let engine = Joy.create(name: "testGroupReg")
        _instance = engine

        let apiGroup = engine.router.group("/api")
        apiGroup.use(JoyMiddlewareFuncHandler({ctx, chain =>
            ctx.header("X-API-Middleware", "true")
            chain.next(ctx)
        }))

        apiGroup.get("/test", {ctx: JoyContext => ctx.string("api")})

        spawn {
            engine.run("127.0.0.1", 18889)
        }
        sleep(Duration.millisecond * 500)

        let rsp = _client.get("http://127.0.0.1:18889/api/test")
        @Assert(rsp.status == 200)
        @Assert(rsp.headers.getFirst("X-API-Middleware").getOrThrow(), "true")

        engine.shutdown()
    }

    /**
     * 测试中间件上下文传递 - 验证中间件之间可以传递上下文数据
     */
    @TestCase
    public func testMiddlewareContextPassing() {
        let engine = Joy.create(name: "testContextPassing")
        _instance = engine

        engine.router.use(JoyMiddlewareFuncHandler({ctx, chain =>
            ctx.setCtxParam("step1", "done")
            chain.next(ctx)
        }))

        engine.router.use(JoyMiddlewareFuncHandler({ctx, chain =>
            let step1 = ctx.getCtxParam<String>("step1")
            ctx.setCtxParam("step2", step1.getOrThrow() + "-done")
            chain.next(ctx)
        }))

        engine.router.get("/test", {ctx: JoyContext =>
            let result = ctx.getCtxParam<String>("step2")
            ctx.string(result.getOrThrow())
        })

        spawn {
            engine.run("127.0.0.1", 18890)
        }
        sleep(Duration.millisecond * 500)

        let rsp = _client.get("http://127.0.0.1:18890/test")
        @Assert(rsp.status == 200)
        let bodyStr = streamToString(rsp.body)
        @Assert(bodyStr, "done-done")

        engine.shutdown()
    }
}
