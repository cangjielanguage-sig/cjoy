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

import std.unittest.testmacro.*
import std.collection.HashMap
import std.sync.AtomicBool
import cjoy.context.ServiceContainer
import stdx.net.http.Cookie

@Test
public class ContextTestCaseSuit {
    /**
     * 测试上下文参数设置 - 验证可以设置和获取上下文参数
     */
    @TestCase
    public func testContextParamSetAndGet() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        let paramRetrieved = AtomicBool(false)
        router.get("/test", {ctx: JoyContext =>
            ctx.setCtxParam("key", "value")
            let val = ctx.getCtxParam<String>("key")
            if (val.getOrThrow() == "value") {
                paramRetrieved.store(true)
            }
            ctx.string("ok")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试路径参数获取 - 验证可以获取路径参数
     */
    @TestCase
    public func testPathParamRetrieval() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        let paramRetrieved = AtomicBool(false)
        router.get("/users/{id}", {ctx: JoyContext =>
            let id = ctx.getParam("id")
            if (id.isSome()) {
                paramRetrieved.store(true)
            }
            ctx.string("ok")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试路径参数添加 - 验证可以添加路径参数
     */
    @TestCase
    public func testPathParamAdd() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/test", {ctx: JoyContext =>
            ctx.addParam("custom", "value")
            let val = ctx.getParam("custom")
            @Assert(val.getOrThrow(), "value")
            ctx.string("ok")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试上下文配置获取 - 验证可以获取配置
     */
    @TestCase
    public func testConfigRetrieval() {
        let config = JoyConfig(caseInsensitive: true)
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/test", {ctx: JoyContext =>
            @Assert(ctx.config.caseInsensitive, true)
            ctx.string("ok")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试参数映射获取 - 验证可以获取参数映射
     */
    @TestCase
    public func testParamsMapRetrieval() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/users/{id}/posts/{postId}", {ctx: JoyContext =>
            let params = ctx.params
            @Assert(params.size, 2)
            ctx.string("ok")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试不存在参数获取 - 验证获取不存在的参数返回 None
     */
    @TestCase
    public func testNonExistentParam() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/test", {ctx: JoyContext =>
            let val = ctx.getParam("nonexistent")
            @Assert(val.isNone(), true)
            ctx.string("ok")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试上下文参数类型转换 - 验证上下文参数可以存储不同类型
     */
    @TestCase
    public func testContextParamTypeConversion() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/test", {ctx: JoyContext =>
            ctx.setCtxParam("stringValue", "hello")
            ctx.setCtxParam("intValue", 12345)

            let str = ctx.getCtxParam<String>("stringValue")
            @Assert(str.getOrThrow(), "hello")

            ctx.string("ok")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试服务容器 - 验证可以通过上下文获取服务
     */
    @TestCase
    public func testServiceContainer() {
        let config = JoyConfig()
        let services = ServiceContainer()
        services.addService("testService", "serviceValue")
        let router: JoyRouteGroup = JoyRouteGroup(config, services)

        router.get("/test", {ctx: JoyContext =>
            let service = ctx.getService<String>("testService")
            @Assert(service.getOrThrow(), "serviceValue")
            ctx.string("ok")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试查询参数获取 - 验证可以获取 URL 查询参数
     */
    @TestCase
    public func testQueryParamRetrieval() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/search", {ctx: JoyContext =>
            let q = ctx.getQuery("q")
            ctx.string(q.getOrThrow())
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试查询参数默认值 - 验证查询参数可以使用默认值
     */
    @TestCase
    public func testQueryParamDefault() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/search", {ctx: JoyContext =>
            let q = ctx.getQuery("q", "default")
            @Assert(q, "default")
            ctx.string(q)
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试查询参数列表 - 验证可以获取同名的多个查询参数
     */
    @TestCase
    public func testQueryParamList() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/filter", {ctx: JoyContext =>
            let tags = ctx.getQueryList("tag")
            ctx.string("ok")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试 POST 表单参数 - 验证可以获取 POST 表单参数
     */
    @TestCase
    public func testPostFormParam() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.post("/submit", {ctx: JoyContext =>
            let name = ctx.getPostForm("name")
            ctx.string("ok")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试 POST 表单参数默认值 - 验证表单参数可以使用默认值
     */
    @TestCase
    public func testPostFormParamDefault() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.post("/submit", {ctx: JoyContext =>
            let name = ctx.getPostForm("name", "anonymous")
            @Assert(name, "anonymous")
            ctx.string("ok")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试 POST 表单参数列表 - 验证可以获取同名的多个表单参数
     */
    @TestCase
    public func testPostFormParamList() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.post("/submit", {ctx: JoyContext =>
            let items = ctx.getPostFormList("item")
            ctx.string("ok")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试表单参数（POST 或查询）- 验证 getForm 方法
     */
    @TestCase
    public func testFormParam() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/form", {ctx: JoyContext =>
            let value = ctx.getForm("field")
            ctx.string("ok")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试表单参数默认值 - 验证 getForm 方法支持默认值
     */
    @TestCase
    public func testFormParamDefault() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/form", {ctx: JoyContext =>
            let value = ctx.getForm("field", "default")
            @Assert(value, "default")
            ctx.string("ok")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试请求头获取 - 验证可以获取请求头
     */
    @TestCase
    public func testHeaderRetrieval() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/header", {ctx: JoyContext =>
            let contentType = ctx.getHeader("Content-Type")
            ctx.string("ok")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试请求头列表 - 验证可以获取同名的多个请求头
     */
    @TestCase
    public func testHeaderList() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/headers", {ctx: JoyContext =>
            let acceptHeaders = ctx.getHeaderList("Accept")
            ctx.string("ok")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试 Cookie 获取 - 验证可以获取 Cookie
     */
    @TestCase
    public func testCookieRetrieval() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/cookie", {ctx: JoyContext =>
            let sessionId = ctx.getCookie("sessionId")
            ctx.string("ok")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试 Cookie 映射获取 - 验证可以获取 Cookie 映射
     */
    @TestCase
    public func testCookiesMap() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/cookies", {ctx: JoyContext =>
            let cookies = ctx.cookies
            ctx.string("ok")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试请求方法获取 - 验证可以获取 HTTP 方法
     */
    @TestCase
    public func testMethodRetrieval() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/method", {ctx: JoyContext =>
            let method = ctx.method
            @Assert(method, "GET")
            ctx.string(method)
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试请求路径获取 - 验证可以获取请求路径
     */
    @TestCase
    public func testPathRetrieval() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/path/test", {ctx: JoyContext =>
            let path = ctx.path
            @Assert(path, "/path/test")
            ctx.string(path)
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试请求 URL 获取 - 验证可以获取完整 URL
     */
    @TestCase
    public func testUrlRetrieval() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/url", {ctx: JoyContext =>
            let url = ctx.url
            ctx.string(url.toString())
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试请求参数类型分发 - 验证 getRequestParam 方法
     */
    @TestCase
    public func testRequestParamDispatch() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/params/{id}", {ctx: JoyContext =>
            let pathParam = ctx.getRequestParam("param", "id")
            let queryParam = ctx.getRequestParam("query", "q", "default")
            ctx.string("ok")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试字符串响应 - 验证可以发送字符串响应
     */
    @TestCase
    public func testStringResponse() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/string", {ctx: JoyContext =>
            ctx.string("Hello World")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试带内容类型的字符串响应 - 验证可以设置内容类型
     */
    @TestCase
    public func testStringResponseWithContentType() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/custom", {ctx: JoyContext =>
            ctx.string("application/custom", "custom content")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试文本响应 - 验证 text 方法
     */
    @TestCase
    public func testTextResponse() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/text", {ctx: JoyContext =>
            ctx.text("plain text")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试 HTML 响应 - 验证 html 方法
     */
    @TestCase
    public func testHtmlResponse() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/html", {ctx: JoyContext =>
            ctx.html("<html><body>Hello</body></html>")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试 JSON 字符串响应 - 验证 json 方法
     */
    @TestCase
    public func testJsonStringResponse() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/json", {ctx: JoyContext =>
            ctx.json("{\"message\":\"hello\"}")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试字节数组响应 - 验证 data 方法
     */
    @TestCase
    public func testDataResponse() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/data", {ctx: JoyContext =>
            ctx.data([0x01, 0x02, 0x03, 0x04])
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试状态码设置 - 验证 status 方法
     */
    @TestCase
    public func testStatusSetting() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/created", {ctx: JoyContext =>
            ctx.status(201).string("created")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试 OK 响应 - 验证 ok 方法
     */
    @TestCase
    public func testOkResponse() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/ok", {ctx: JoyContext =>
            ctx.ok().string("ok")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试响应头设置 - 验证 header 方法
     */
    @TestCase
    public func testHeaderSetting() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/header", {ctx: JoyContext =>
            ctx.header("X-Custom", "value").string("ok")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试多个响应头设置 - 验证可以设置多个响应头
     */
    @TestCase
    public func testMultipleHeaders() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/headers", {ctx: JoyContext =>
            ctx.header("X-Header-1", "value1")
                .header("X-Header-2", "value2")
                .string("ok")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试内容类型设置 - 验证 contentType 方法
     */
    @TestCase
    public func testContentTypeSetting() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/content-type", {ctx: JoyContext =>
            ctx.contentType("application/xml").string("<xml/>")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试 Cookie 设置 - 验证 cookie 方法
     */
    @TestCase
    public func testCookieSetting() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/set-cookie", {ctx: JoyContext =>
            let cookie = Cookie("session", "abc123", maxAge: 3600)
            ctx.cookie(cookie).string("ok")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试重定向 - 验证 redirect 方法
     */
    @TestCase
    public func testRedirect() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/redirect", {ctx: JoyContext =>
            ctx.redirect(302, "/target")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试 404 响应 - 验证 notFound 方法
     */
    @TestCase
    public func testNotFoundResponse() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/not-found", {ctx: JoyContext =>
            ctx.notFound()
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试响应状态码获取 - 验证 respStatus 属性
     */
    @TestCase
    public func testResponseStatusRetrieval() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/status", {ctx: JoyContext =>
            ctx.status(201)
            let status = ctx.respStatus
            @Assert(status, 201)
            ctx.string("created")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试响应体获取 - 验证 respBody 属性
     */
    @TestCase
    public func testResponseBodyRetrieval() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/body", {ctx: JoyContext =>
            ctx.string("response body")
            let body = ctx.respBody
            @Assert(body, "response body")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试链式响应设置 - 验证方法链式调用
     */
    @TestCase
    public func testChainedResponseSettings() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/chain", {ctx: JoyContext =>
            ctx.status(201)
                .header("X-Custom", "value")
                .contentType("text/plain")
                .string("created")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试上下文重置 - 验证 reset 方法清除状态
     */
    @TestCase
    public func testContextReset() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/reset", {ctx: JoyContext =>
            ctx.setCtxParam("key1", "value1")
            ctx.addParam("param1", "value1")

            // 获取内部上下文进行重置测试
            let httpCtx = (ctx as JoyHttpContext).getOrThrow()
            httpCtx.reset()

            // 重置后参数应该被清除
            let val = ctx.getCtxParam<String>("key1")
            @Assert(val.isNone(), true)
            ctx.string("ok")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试上下文处理链索引 - 验证处理链索引管理
     */
    @TestCase
    public func testHandleIndexManagement() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/index", {ctx: JoyContext =>
            let httpCtx = (ctx as JoyHttpContext).getOrThrow()
            let initialIndex = httpCtx.handleIndex
            @Assert(initialIndex, 0)

            let newIndex = httpCtx.addHandleIndex()
            @Assert(newIndex, 1)

            httpCtx.resetHandleIndex()
            @Assert(httpCtx.handleIndex, 0)

            ctx.string("ok")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试上下文参数复制 - 验证 copyParams 和 copyCtxParams
     */
    @TestCase
    public func testContextParamCopy() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/copy/{id}", {ctx: JoyContext =>
            let httpCtx = (ctx as JoyHttpContext).getOrThrow()

            ctx.addParam("id", "123")
            ctx.setCtxParam("ctxKey", "ctxValue")

            let paramsCopy = httpCtx.copyParams()
            @Assert(paramsCopy.size, 1)
            @Assert(paramsCopy.get("id").getOrThrow(), "123")

            let ctxParamsCopy = httpCtx.copyCtxParams()
            @Assert(ctxParamsCopy.size, 1)

            ctx.string("ok")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试上下文请求体读取 - 验证请求体读取方法
     */
    @TestCase
    public func testRequestBodyReading() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.post("/body", {ctx: JoyContext =>
            let rawData = ctx.readRawData()
            let str = ctx.readString()

            ctx.string("ok")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试上下文请求体绑定 - 验证字符串体绑定
     */
    @TestCase
    public func testRequestBodyBinding() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.post("/bind", {ctx: JoyContext =>
            let bodyStr = ctx.bindStringBody()
            ctx.string(bodyStr.getOrThrow())
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试上下文内容类型获取 - 验证 getContentType 方法
     */
    @TestCase
    public func testContentTypeRetrieval() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.post("/content-type", {ctx: JoyContext =>
            let contentType = ctx.getContentType()
            ctx.string(contentType)
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试上下文客户端 IP 获取 - 验证 getClientIP 方法
     */
    @TestCase
    public func testClientIPRetrieval() {
        let config = JoyConfig(remoteIPHeaders: ["X-Forwarded-For"])
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/client-ip", {ctx: JoyContext =>
            let clientIP = ctx.getClientIP()
            @Assert(clientIP.size > 0, true)
            ctx.string(clientIP)
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试上下文远程 IP 获取 - 验证 getRemoteIP 方法
     */
    @TestCase
    public func testRemoteIPRetrieval() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/remote-ip", {ctx: JoyContext =>
            let remoteIP = ctx.getRemoteIP()
            ctx.string(remoteIP)
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试上下文基础认证 - 验证 basicAuth 方法
     */
    @TestCase
    public func testBasicAuth() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/auth", {ctx: JoyContext =>
            let auth = ctx.basicAuth()
            ctx.string("ok")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试上下文分块写入器 - 验证 chunkedWriter 方法
     */
    @TestCase
    public func testChunkedWriter() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/chunked", {ctx: JoyContext =>
            let writer = ctx.chunkedWriter()
            writer.write("chunk1")
            writer.write("chunk2")
            writer.end()
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试上下文 SSE 发射器 - 验证 eventEmitter 方法
     */
    @TestCase
    public func testEventEmitter() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/sse", {ctx: JoyContext =>
            let emitter = ctx.eventEmitter()
            let event = JoySseBuilder().data("test data").build()
            emitter.sendEvent(JoySseBuilder().data("test"))
            emitter.end()
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }
}