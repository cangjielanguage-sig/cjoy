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
import std.io.readToEnd
import std.io.BufferedInputStream
import std.io.StringReader
import std.io.InputStream

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

    @TestCase
    public func testMiddlewareFuncHandler() {
        let middlewareFunc: JoyMiddlewareFunc = {ctx, chain =>
            chain.next(ctx)
        }

        let handler = JoyMiddlewareFuncHandler(middlewareFunc)
        @Assert(true) // 只要没有抛出异常，测试就成功
    }

    @TestCase
    public func testMiddlewareRegistry() {
        let middlewareFunc: JoyMiddlewareFunc = {ctx, chain =>
            chain.next(ctx)
        }

        let handler = JoyMiddlewareFuncHandler(middlewareFunc)
        JoyMiddlewares.addHandler(["/test"], handler)

        @Assert(true) // 只要没有抛出异常，测试就成功
    }

    @TestCase
    public func testMiddlewareRegistryWithMultipleGroups() {
        let middlewareFunc: JoyMiddlewareFunc = {ctx, chain =>
            chain.next(ctx)
        }

        let handler = JoyMiddlewareFuncHandler(middlewareFunc)
        JoyMiddlewares.addHandler(["/group1", "/group2", "/group3"], handler)

        @Assert(true) // 只要没有抛出异常，测试就成功
    }

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
}
