/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.test

import std.io.*
import stdx.net.http.*
import cjoy.*
import cjoy.json.*
import cjoy.macros.*
import cjoy.middleware.TokenAuth

@Get[path = "/token_auth/query"]
private func auth1(ctx: JoyContext): String {
    "ok-query"
}

@Get[path = "/token_auth/param/{token}"]
private func auth2(ctx: JoyContext, @PathParam token: String): String {
    "ok-param"
}

@Post[path = "/token_auth/form"]
private func auth3(ctx: JoyContext, @PostFormParam token: String): String {
    "ok-form"
}

@Get[path = "/token_auth/header"]
private func auth4(ctx: JoyContext, @HeaderParam[name = "Authorization"] token: String): String {
    "ok-header"
}

@Get[path = "/token_auth/cookie"]
private func auth5(ctx: JoyContext, @CookieParam token: String): String {
    "ok-cookie"
}

@Test
public class TokenAuthTestCaseSuit {
    var _instance: ?Joy = None
    let _client = ClientBuilder().build()

    @BeforeAll
    func setup() {
        spawn {
            let joy = Joy.default()
            let router = joy.router
            joy.router.group("/token_auth/header").use(TokenAuth(["abc"]))
            joy.router.group("/token_auth/query").use(TokenAuth(["abc"], lookupKey: "query:token"))
            joy.router.group("/token_auth/param").use(TokenAuth(["abc"], lookupKey: "param:token"))
            joy.router.group("/token_auth/form").use(TokenAuth(["abc"], lookupKey: "form:token"))
            joy.router.group("/token_auth/cookie").use(TokenAuth(["abc"], lookupKey: "cookie:token"))
            // 启动服务
            JoyMiddlewares.registerTo(joy)
            JoyHandlers.registerTo(joy)
            _instance = joy
            joy.run("127.0.0.1", 18881)
        }
        sleep(Duration.second * 2)
    }

    @AfterAll
    func tearDown() {
        _client.close()
        _instance?.shutdown()
    }

    /**
     * 测试头部 Token 认证 - 验证通过 Authorization 头部传递 Token 的认证
     */
    @TestCase
    public func testHeader() {
        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18881/token_auth/header")
            .method("GET")
            .header(JoyHttpConsts.HEADER_AUTHORIZATION, "Bearer abc")
            .build()
        let rsp = _client.send(req)
        assertResp(rsp, "ok-header")
        rsp.close()
    }

    /**
     * 测试查询参数 Token 认证 - 验证通过查询参数传递 Token 的认证
     */
    @TestCase
    public func testQuery() {
        let rsp = _client.get("http://127.0.0.1:18881/token_auth/query?token=abc")
        assertResp(rsp, "ok-query")
        rsp.close()
    }

    /**
     * 测试路径参数 Token 认证 - 验证通过路径参数传递 Token 的认证
     */
    @TestCase
    public func testParam() {
        let rsp = _client.get("http://127.0.0.1:18881/token_auth/param/abc")
        assertResp(rsp, "ok-param")
        rsp.close()
    }

    /**
     * 测试表单 Token 认证 - 验证通过表单数据传递 Token 的认证
     */
    @TestCase
    public func testForm() {
        let req = HttpRequestBuilder()
            .post()
            .url("http://127.0.0.1:18881/token_auth/form")
            .body("token=abc")
            .header("Content-Type", "application/x-www-form-urlencoded")
            .build()
        let rsp = _client.send(req)
        assertResp(rsp, "ok-form")
        rsp.close()
    }

    /**
     * 测试 Cookie Token 认证 - 验证通过 Cookie 传递 Token 的认证
     */
    @TestCase
    public func testCookie() {
        let req = HttpRequestBuilder()
            .get()
            .url("http://127.0.0.1:18881/token_auth/cookie")
            .header("Cookie", "token=abc")
            .build()
        let rsp = _client.send(req)
        assertResp(rsp, "ok-cookie")
        rsp.close()
    }

    private func assertResp(rsp: HttpResponse, exp: String): Unit {
        let reader = StringReader(rsp.body)
        @Assert(reader.readToEnd(), exp)
    }
}
