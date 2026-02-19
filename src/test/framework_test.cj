/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
.
 */

package cjoy.test

import cjoy.*
import cjoy.json.*
import cjoy.macros.*
import cjoy.httpx.*
import cjoy.context.*
import stdx.encoding.url.*
import stdx.net.http.*
import std.unittest.testmacro.*

@Get[path = "/test_ok"]
func testOk(): String {
    "ok"
}

@Get[path = "/test_not_found"]
func testNotFound(ctx: JoyContext): Unit {
    ctx.notFound()
}

@Get[path = "/test_redirect"]
func testRedirect(ctx: JoyContext): Unit {
    ctx.redirect(301, "/test_ok")
}

@Get[path = "/test_json", produce = json]
func testJson(ctx: JoyContext): String {
    "{\"message\":\"hello\"}"
}

@Get[path = "/test_json_produce", produce = json]
func testJsonProduce(): HashMap<String, String> {
    HashMap<String, String>([("message", "hello")])
}

@Get[path = "/test_status"]
func testStatus(ctx: JoyContext): UInt16 {
    201
}

@Get[path = "/test_status_ctx"]
func testStatusCtx(ctx: JoyContext): String {
    ctx.status(202)
    "accepted"
}

@Get[path = "/test_header"]
func testHeader(ctx: JoyContext): String {
    ctx.header("X-Custom-Header", "custom-value")
    ctx.header("X-Another", "another-value")
    "ok"
}

@Get[path = "/test_content_type"]
func testContentType(ctx: JoyContext): String {
    ctx.contentType("text/html")
    "<html>Hello</html>"
}

@Get[path = "/test_cookie"]
func testCookie(ctx: JoyContext): String {
    let sessionId = ctx.getCookie("sessionId") ?? "not-found"
    sessionId
}

@Get[path = "/test_set_cookie"]
func testSetCookie(ctx: JoyContext): Unit {
    let cookie = Cookie("session", "abc123", maxAge: 3600)
    ctx.cookie(cookie)
}

@Get[path = "/test_param/{id}"]
func testPathParam(@PathParam id: Int32): String {
    id.toString()
}

@Get[path = "/test_query"]
func testQueryParam(@QueryParam name: String): String {
    name
}

@Post[path = "/test_post_form"]
func testPostForm(@PostFormParam value: String): String {
    value
}

@Get[path = "/test_get_form"]
func testGetForm(@QueryParam value: String): String {
    value
}

@Get[path = "/test_remote_ip"]
func testRemoteIp(ctx: JoyContext): String {
    ctx.getRemoteIP()
}

@Get[path = "/test_client_ip"]
func testClientIp(ctx: JoyContext): String {
    ctx.getClientIP()
}

@Get[path = "/test_path"]
func testPath(ctx: JoyContext): String {
    ctx.path
}

@Get[path = "/test_method"]
func testMethod(ctx: JoyContext): String {
    ctx.method
}

@Get[path = "/test_url"]
func testUrl(ctx: JoyContext): String {
    ctx.url.toString()
}

@Get[path = "/test_get_header"]
func testGetHeader(@HeaderParam[name = "X-Test-Header", default = "default"] header: String): String {
    header
}

@Get[path = "/test_multi/{id}", produce = json]
func testMulti(
    @PathParam id: String,
    @QueryParam q: String,
    @HeaderParam[name = "X-Token", default = ""] token: String
): HashMap<String, String> {
    HashMap<String, String>([("id", id), ("q", q), ("token", token)])
}

@Get[path = "/group1/test_group1"]
func testGroup1(): String {
    "group1"
}

@Get[path = "/group2/test_group2"]
func testGroup2(): String {
    "group2"
}

@Middleware[groups="/group1,/group2"]
func group1Mw(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
    chain.next(ctx)
}

@Test
public class FrameworkTestCaseSuit {
    var _instance: ?Joy = None
    let _ctx = MapContext()
    let _client = JoyHttpClientService("http://127.0.0.1:18883/")

    @BeforeAll
    func setup() {
        spawn {
            let joy = Joy.default()
            let router = joy.router
            router.group("/api/v1")
            _instance = joy
            JoyHandlers.registerTo(joy)
            joy.run("127.0.0.1", 18883)
        }
        sleep(Duration.second)
    }

    @AfterAll
    func tearDown() {
        _client.destroy()
        _instance?.shutdown()
    }

    /**
     * 测试基本请求响应 - 验证简单的 GET 请求和响应
     */
    @TestCase
    public func testOk() {
        let rsp = _client.get(_ctx, "/test_ok")
        assertResponse(rsp, "ok")
    }

    private func assertResponse(rsp: JoyHttpResponse): Unit {
        @Assert(rsp.status, 200)
    }

    private func assertResponse(rsp: JoyHttpResponse, expected: String): Unit {
        @Assert(rsp.status, 200)
        @Assert(rsp.text, expected)
    }

    /**
     * 测试未找到资源 - 验证访问不存在的路由会返回 404 状态码
     */
    @TestCase
    public func testNotFound() {
        let rsp = _client.get(_ctx, "/not_found")
        @Assert(rsp.status, 404)
    }

    /**
     * 测试自定义 NotFound 处理器 - 验证自定义的 404 处理器功能
     */
    @TestCase
    public func testNotFoundHandler() {
        let rsp = _client.get(_ctx, "/test_not_found")
        @Assert(rsp.status, 404)
    }

    /**
     * 测试重定向功能 - 验证 HTTP 重定向功能
     */
    @TestCase
    public func testRedirect() {
        let rsp = _client.get(_ctx, "/test_redirect")
        @Assert(rsp.status, 200)
        //let location = rsp.headers.getFirst("Location")
        //@Assert(location.getOrThrow(), "/test_ok")
    }

    /**
     * 测试 JSON 响应 - 验证返回 JSON 响应的功能
     */
    @TestCase
    public func testJson() {
        let rsp = _client.get(_ctx, "/test_json")
        assertResponse(rsp)
        @Assert(rsp.headers.getFirst("Content-Type").getOrThrow().contains("application/json"), true)
        @Assert(rsp.text, "{\"message\":\"hello\"}")
    }

    /**
     * 测试 JSON 响应自动转换 - 验证返回对象自动转换为 JSON 的功能
     */
    @TestCase
    public func testJsonProduce() {
        let rsp = _client.get(_ctx, "/test_json_produce")
        assertResponse(rsp)
        @Assert(rsp.headers.getFirst("Content-Type").getOrThrow().contains("application/json"), true)
        @Assert(rsp.text, "{\"message\":\"hello\"}")
    }

    /**
     * 测试自定义状态码 - 验证返回自定义 HTTP 状态码的功能
     */
    @TestCase
    public func testStatus() {
        let rsp = _client.get(_ctx, "/test_status")
        @Assert(rsp.status, 201)
    }

    /**
     * 测试通过上下文设置状态码 - 验证通过 JoyContext 设置响应状态码的功能
     */
    @TestCase
    public func testStatusCtx() {
        let rsp = _client.get(_ctx, "/test_status_ctx")
        @Assert(rsp.text, "accepted")
        @Assert(rsp.status, 202)
    }

    /**
     * 测试自定义响应头 - 验证设置和获取自定义响应头的功能
     */
    @TestCase
    public func testHeader() {
        let rsp = _client.get(_ctx, "/test_header")
        assertResponse(rsp)
        @Assert(rsp.headers.getFirst("X-Custom-Header").getOrThrow(), "custom-value")
        @Assert(rsp.headers.getFirst("X-Another").getOrThrow(), "another-value")
    }

    /**
     * 测试内容类型设置 - 验证设置响应 Content-Type 头的功能
     */
    @TestCase
    public func testContentType() {
        let rsp = _client.get(_ctx, "/test_content_type")
        assertResponse(rsp)
        @Assert(rsp.headers.getFirst("Content-Type").getOrThrow(), "text/html")
    }

    /**
     * 测试 Cookie 读取 - 验证从请求中读取 Cookie 的功能
     */
    @TestCase
    public func testCookie() {
         let req = JoyHttpRequest.of("/test_cookie")
            .get()
            .header("cookie", "sessionId=test123")
            .body("id=1")
        let rsp = _client.send(_ctx,  req)
        assertResponse(rsp, "test123")
    }

    /**
     * 测试 Cookie 设置 - 验证在响应中设置 Cookie 的功能
     */
    @TestCase
    public func testSetCookie() {
        let rsp = _client.get(_ctx, "/test_set_cookie")
        @Assert(rsp.status, 200)
        let setCookie = rsp.headers.getFirst("Set-Cookie")
        @Assert(setCookie.isSome(), true)
        @Assert(setCookie.getOrThrow().contains("session=abc123"), true)
    }

    /**
     * 测试路径参数 - 验证从 URL 路径中提取参数的功能
     */
    @TestCase
    public func testPathParam() {
        let rsp = _client.get(_ctx, "/test_param/123")
        assertResponse(rsp, "123")
    }

    /**
     * 测试查询参数 - 验证从 URL 查询字符串中提取参数的功能
     */
    @TestCase
    public func testQueryParam() {
        let rsp = _client.get(_ctx, "/test_query?name=test")
        assertResponse(rsp, "test")
    }

    /**
     * 测试 POST 表单数据 - 验证处理 POST 请求中的表单数据
     */
    @TestCase
    public func testPostForm() {
        let form = Form()
        form.add("value", "test-value")
        let rsp = _client.postform(_ctx, "/test_post_form", form)
        assertResponse(rsp, "test-value")
    }

    /**
     * 测试 GET 请求表单数据 - 验证处理 GET 请求中的查询参数作为表单数据
     */
    @TestCase
    public func testGetForm() {
        let rsp = _client.get(_ctx, "/test_get_form?value=test-value")
        assertResponse(rsp, "test-value")
    }

    /**
     * 测试获取远程 IP 地址 - 验证获取请求的远程 IP 地址功能
     */
    @TestCase
    public func testRemoteIp() {
        let rsp = _client.get(_ctx, "/test_remote_ip")
        assertResponse(rsp, "127.0.0.1")
    }

    /**
     * 测试获取客户端 IP 地址 - 验证获取请求的客户端 IP 地址功能
     */
    @TestCase
    public func testClientIp() {
        let rsp = _client.get(_ctx, "/test_client_ip")
        assertResponse(rsp, "127.0.0.1")
    }

    /**
     * 测试获取请求路径 - 验证获取当前请求路径的功能
     */
    @TestCase
    public func testPath() {
        let rsp = _client.get(_ctx, "/test_path")
        assertResponse(rsp, "/test_path")
    }

    /**
     * 测试获取请求方法 - 验证获取当前请求方法的功能
     */
    @TestCase
    public func testMethod() {
        let rsp = _client.get(_ctx, "/test_method")
        assertResponse(rsp, "GET")
    }

    /**
     * 测试获取完整 URL - 验证获取当前请求完整 URL 的功能
     */
    @TestCase
    public func testUrl() {
        let rsp = _client.get(_ctx, "/test_url?test=1")
        @Assert(rsp.status, 200)
        @Assert(rsp.text.contains("/test_url"), true)
    }

    /**
     * 测试获取请求头部 - 验证从请求中获取指定头部的功能
     */
    @TestCase
    public func testGetHeader() {
        let req = JoyHttpRequest.of("/test_get_header").header("X-Test-Header", "test-value")
        let rsp = _client.send(_ctx, req)
        assertResponse(rsp, "test-value")
    }

    /**
     * 测试复合参数绑定 - 验证同时绑定路径参数、查询参数和头部参数的功能
     */
    @TestCase
    public func testMulti() {
        let req = JoyHttpRequest.of("/test_multi/123?q=test").header("X-Token", "token123")
        let rsp = _client.send(_ctx, req)
        @Assert(rsp.status, 200)
        let body = rsp.text
        @Assert(body.contains("\"id\":\"123\""), true)
        @Assert(body.contains("\"q\":\"test\""), true)
        @Assert(body.contains("\"token\":\"token123\""), true)
    }

    /**
     * 测试路由分组 - 验证路由分组功能和分组中间件
     */
    @TestCase
    public func testGroupRoutes() {
        let rsp1 = _client.get(_ctx, "/group1/test_group1")
        assertResponse(rsp1, "group1")

        let rsp2 = _client.get(_ctx, "/group2/test_group2")
        assertResponse(rsp2, "group2")
    }
}
