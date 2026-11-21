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

import std.io.*
import stdx.net.http.*
import cjoy.*
import cjoy.middleware.Cors

@Test
public class CorsTestCaseSuit {
    var _instance: ?Joy = None
    let _client = ClientBuilder().build()

    @BeforeAll
    func setup() {
        spawn {
            let joy = Joy.default()
            let router = joy.router

            // CORS with allowAll
            let corsAllowAll = Cors.allowAll()
            router
                .group("/cors_all")
                .use(corsAllowAll)
                .get("/test", {ctx: JoyContext => ctx.string("allow_all")})
                .post("/test", {ctx: JoyContext => ctx.string("allow_all_post")})

            // CORS with specific origins
            let corsSpecific = Cors(allowedOrigins: ["http://example.com", "https://api.example.com"],
                allowedMethods: ["GET", "POST", "PUT"], allowedHeaders: ["Content-Type", "X-Custom-Header"],
                allowCredentials: true)
            router.group("/cors_specific").use(corsSpecific).get("/test", {ctx: JoyContext => ctx.string("specific")})

            // CORS with wildcard origin
            let corsWildcard = Cors(allowedOrigins: ["http://*.example.com"])
            router.group("/cors_wildcard").use(corsWildcard).get("/test", {ctx: JoyContext => ctx.string("wildcard")})

            // CORS with custom allowOriginFunc
            let corsCustomFunc = Cors(allowOriginFunc: {
                ctx: JoyContext, origin: String => origin.contains("custom")
            }, allowedMethods: ["GET", "POST"], exposedHeaders: ["X-Custom-Response"])
            router.group("/cors_custom").use(corsCustomFunc).get("/test", {ctx: JoyContext => ctx.string("custom")})

            // CORS with maxAge and optionsPassthrough
            let corsPassthrough = Cors(allowedOrigins: ["http://passthrough.com"],
                allowedMethods: ["GET", "POST", "OPTIONS"], maxAge: 3600, optionsPassthrough: true)
            router
                .group("/cors_passthrough")
                .use(corsPassthrough)
                .get("/test", {ctx: JoyContext => ctx.string("passthrough")})
                .options("/test", {ctx: JoyContext => ctx.string("options_handled")})

            _instance = joy
            joy.run("127.0.0.1", 18882)
        }
        sleep(Duration.second * 2)
    }

    @AfterAll
    func tearDown() {
        _client.close()
        _instance?.shutdown()
    }

    /**
     * 测试允许所有源的预检请求 - 验证 Cors.allowAll() 的预检请求处理
     */
    @TestCase
    public func testAllowAllPreflight() {
        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18882/cors_all/test")
            .method("OPTIONS")
            .header("Origin", "http://any-origin.com")
            .header("Access-Control-Request-Method", "GET")
            .build()
        let rsp = _client.send(req)
        @Assert(rsp.status, 200)
        @Assert(rsp.headers.getFirst("Access-Control-Allow-Origin"), Some("http://any-origin.com"))
        @Assert(rsp.headers.getFirst("Access-Control-Allow-Credentials"), Some("true"))
    }

    /**
     * 测试允许所有方法的预检请求 - 验证所有HTTP方法的预检请求处理
     */
    @TestCase
    public func testAllowAllAllMethodsAllowed() {
        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18882/cors_all/test")
            .method("OPTIONS")
            .header("Origin", "http://any-origin.com")
            .header("Access-Control-Request-Method", "DELETE")
            .build()
        let rsp = _client.send(req)
        @Assert(rsp.status, 200)
        @Assert(rsp.headers.getFirst("Access-Control-Allow-Origin"), Some("http://any-origin.com"))
        @Assert(rsp.headers.getFirst("Access-Control-Allow-Methods"), Some("DELETE"))
    }

    /**
     * 测试允许所有源的实际请求 - 验证CORS允许所有源的实际请求处理
     */
    @TestCase
    public func testAllowAllActualRequest() {
        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18882/cors_all/test")
            .method("GET")
            .header("Origin", "http://any-origin.com")
            .build()
        let rsp = _client.send(req)
        @Assert(rsp.status, 200)
        @Assert(rsp.headers.getFirst("Access-Control-Allow-Origin"), Some("http://any-origin.com"))
        @Assert(rsp.headers.getFirst("Access-Control-Allow-Credentials"), Some("true"))
        let reader = StringReader(rsp.body)
        @Assert(reader.readToEnd(), "allow_all")
    }

    /**
     * 测试特定源的预检请求允许 - 验证允许特定源的CORS预检请求处理
     */
    @TestCase
    public func testSpecificOriginPreflightAllowed() {
        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18882/cors_specific/test")
            .method("OPTIONS")
            .header("Origin", "http://example.com")
            .header("Access-Control-Request-Method", "GET")
            .build()
        let rsp = _client.send(req)
        @Assert(rsp.status, 200)
        @Assert(rsp.headers.getFirst("Access-Control-Allow-Origin"), Some("http://example.com"))
        @Assert(rsp.headers.getFirst("Access-Control-Allow-Credentials"), Some("true"))
    }

    /**
     * 测试特定源的预检请求拒绝 - 验证不允许的源的CORS预检请求处理
     */
    @TestCase
    public func testSpecificOriginPreflightDenied() {
        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18882/cors_specific/test")
            .method("OPTIONS")
            .header("Origin", "http://unauthorized.com")
            .header("Access-Control-Request-Method", "GET")
            .build()
        let rsp = _client.send(req)
        @Assert(rsp.status, 200)
        // Origin not allowed, so no Access-Control-Allow-Origin header
        @Assert(rsp.headers.getFirst("Access-Control-Allow-Origin").isNone(), true)
    }

    /**
     * 测试特定源的实际请求 - 验证允许特定源的实际请求处理
     */
    @TestCase
    public func testSpecificOriginActualRequest() {
        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18882/cors_specific/test")
            .method("GET")
            .header("Origin", "https://api.example.com")
            .build()
        let rsp = _client.send(req)
        @Assert(rsp.status, 200)
        @Assert(rsp.headers.getFirst("Access-Control-Allow-Origin"), Some("https://api.example.com"))
        let reader = StringReader(rsp.body)
        @Assert(reader.readToEnd(), "specific")
    }

    /**
     * 测试通配符源允许的请求 - 验证包含通配符的源的CORS请求处理
     */
    @TestCase
    public func testWildcardOriginAllowed() {
        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18882/cors_wildcard/test")
            .method("GET")
            .header("Origin", "http://sub.example.com")
            .build()
        let rsp = _client.send(req)
        @Assert(rsp.status, 200)
        @Assert(rsp.headers.getFirst("Access-Control-Allow-Origin"), Some("http://sub.example.com"))
        let reader = StringReader(rsp.body)
        @Assert(reader.readToEnd(), "wildcard")
    }

    /**
     * 测试通配符源拒绝的请求 - 验证不匹配通配符的源的CORS请求处理
     */
    @TestCase
    public func testWildcardOriginDenied() {
        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18882/cors_wildcard/test")
            .method("GET")
            .header("Origin", "http://other.com")
            .build()
        let rsp = _client.send(req)
        @Assert(rsp.status, 200)
        // Origin doesn't match wildcard pattern
        @Assert(rsp.headers.getFirst("Access-Control-Allow-Origin").isNone(), true)
    }

    /**
     * 测试自定义源验证函数 - 验证使用自定义allowOriginFunc的CORS请求处理
     */
    @TestCase
    public func testCustomAllowOriginFunc() {
        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18882/cors_custom/test")
            .method("GET")
            .header("Origin", "http://custom-origin.com")
            .build()
        let rsp = _client.send(req)
        @Assert(rsp.status, 200)
        @Assert(rsp.headers.getFirst("Access-Control-Allow-Origin"), Some("http://custom-origin.com"))
        @Assert(rsp.headers.getFirst("Access-Control-Expose-Headers"), Some("X-Custom-Response"))
        let reader = StringReader(rsp.body)
        @Assert(reader.readToEnd(), "custom")
    }

    /**
     * 测试自定义源验证函数拒绝 - 验证自定义allowOriginFunc拒绝请求的处理
     */
    @TestCase
    public func testCustomAllowOriginFuncDenied() {
        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18882/cors_custom/test")
            .method("GET")
            .header("Origin", "http://other.com")
            .build()
        let rsp = _client.send(req)
        @Assert(rsp.status, 200)
        @Assert(rsp.headers.getFirst("Access-Control-Allow-Origin").isNone(), true)
    }

    /**
     * 测试OPTIONS请求透传 - 验证optionsPassthrough配置的处理
     */
    @TestCase
    public func testOptionsPassthrough() {
        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18882/cors_passthrough/test")
            .method("OPTIONS")
            .header("Origin", "http://passthrough.com")
            .header("Access-Control-Request-Method", "GET")
            .build()
        let rsp = _client.send(req)
        @Assert(rsp.status, 200)
        @Assert(rsp.headers.getFirst("Access-Control-Allow-Origin"), Some("http://passthrough.com"))
        @Assert(rsp.headers.getFirst("Access-Control-Max-Age"), Some("3600"))
        let reader = StringReader(rsp.body)
        // With optionsPassthrough, the OPTIONS handler should be called
        @Assert(reader.readToEnd(), "options_handled")
    }

    /**
     * 测试包含请求头的预检请求 - 验证带请求头的CORS预检请求处理
     */
    @TestCase
    public func testPreflightWithRequestHeaders() {
        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18882/cors_specific/test")
            .method("OPTIONS")
            .header("Origin", "http://example.com")
            .header("Access-Control-Request-Method", "POST")
            .header("Access-Control-Request-Headers", "Content-Type, X-Custom-Header")
            .build()
        let rsp = _client.send(req)
        @Assert(rsp.status, 200)
        @Assert(rsp.headers.getFirst("Access-Control-Allow-Origin"), Some("http://example.com"))
        @Assert(rsp.headers.getFirst("Access-Control-Allow-Methods"), Some("POST"))
        @Assert(rsp.headers.getFirst("Access-Control-Allow-Headers"), Some("Content-Type, X-Custom-Header"))
    }

    /**
     * 测试无Origin头的请求 - 验证没有Origin头的请求处理
     */
    @TestCase
    public func testNoOriginHeader() {
        let req = HttpRequestBuilder().url("http://127.0.0.1:18882/cors_all/test").method("GET").build()
        let rsp = _client.send(req)
        @Assert(rsp.status, 200)
        // No Origin header means no CORS headers should be added
        @Assert(rsp.headers.getFirst("Access-Control-Allow-Origin").isNone(), true)
        let reader = StringReader(rsp.body)
        @Assert(reader.readToEnd(), "allow_all")
    }

    /**
     * 测试POST请求的CORS处理 - 验证POST请求的CORS处理
     */
    @TestCase
    public func testPostRequestWithCors() {
        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18882/cors_all/test")
            .method("POST")
            .header("Origin", "http://test.com")
            .build()
        let rsp = _client.send(req)
        @Assert(rsp.status, 200)
        @Assert(rsp.headers.getFirst("Access-Control-Allow-Origin"), Some("http://test.com"))
        let reader = StringReader(rsp.body)
        @Assert(reader.readToEnd(), "allow_all_post")
    }

    /**
     * 测试源的大小写不敏感处理 - 验证源比较的大小写不敏感性
     */
    @TestCase
    public func testCaseInsensitiveOrigin() {
        // Origin comparison should be case-insensitive for the scheme and domain
        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18882/cors_specific/test")
            .method("GET")
            .header("Origin", "HTTP://EXAMPLE.COM")
            .build()
        let rsp = _client.send(req)
        @Assert(rsp.status, 200)
        @Assert(rsp.headers.getFirst("Access-Control-Allow-Origin").isSome(), true)
        let reader = StringReader(rsp.body)
        @Assert(reader.readToEnd(), "specific")
    }
}
