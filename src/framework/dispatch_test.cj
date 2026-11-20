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
import stdx.net.http.*
import std.io.{readToEnd, BufferedInputStream, StringReader, InputStream}

/**
 * 测试框架分发的边界场景：405、OPTIONS、客户端 IP、chunked 请求体、文件不存在等
 */
@Test
public class DispatchBugfixTestCaseSuit {
    var _instance: ?Joy = None
    var _client = ClientBuilder().build()

    @BeforeAll
    func setup() {
        spawn {
            let config = JoyConfig(remoteIPHeaders: ["X-Forwarded-For"], caseInsensitive: true)
            let joy = Joy.create(config, name: "testDispatchBugfix")
            joy.router.get("/method", {ctx: JoyContext => ctx.string("get")})
            joy.router.get("/client-ip", {ctx: JoyContext => ctx.string(ctx.getClientIP())})
            joy.router.get("/file-not-found", {ctx: JoyContext => ctx.file("/definitely/not/exist/file.txt")})
            joy.router.post("/echo-body", {ctx: JoyContext => ctx.string(ctx.readString())})
            joy.router.get("/echo/{Name}", {ctx: JoyContext => ctx.string(ctx.getParam("Name") ?? "")})
            let group = joy.router.group("/g")
            group.get("/foo", {ctx: JoyContext => ctx.string("foo")})
            _instance = joy
            joy.run("127.0.0.1", 18891)
        }
        sleep(Duration.second)
    }

    @AfterAll
    func tearDown() {
        _instance?.shutdown()
        _client.close()
    }

    @AfterEach
    func tearDownEach() {
        _client.close()
        _client = ClientBuilder().build()
    }

    private func streamToString(stream: InputStream): String {
        StringReader(BufferedInputStream(stream)).readToEnd()
    }

    /**
     * 测试客户端 IP 解析 - 验证 X-Forwarded-For 返回纯 IP 值
     */
    @TestCase
    public func testClientIPFromHeader() {
        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18891/client-ip")
            .get()
            .header("X-Forwarded-For", "8.8.8.8")
            .build()
        let rsp = _client.send(req)
        @Assert(rsp.status, 200)
        @Assert(streamToString(rsp.body), "8.8.8.8")
    }

    /**
     * 测试客户端 IP 解析失败回退 - 验证无效代理头会回退到 remoteAddr
     */
    @TestCase
    public func testClientIPFallback() {
        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18891/client-ip")
            .get()
            .header("X-Forwarded-For", "not-an-ip")
            .build()
        let rsp = _client.send(req)
        @Assert(rsp.status, 200)
        @Assert(streamToString(rsp.body), "127.0.0.1")
    }

    /**
     * 测试方法不允许 - 验证返回 405 和 Allow 头
     */
    @TestCase
    public func testMethodNotAllowed() {
        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18891/method")
            .method("PUT")
            .build()
        let rsp = _client.send(req)
        @Assert(rsp.status, 405)
        let allow = rsp.headers.getFirst("Allow")
        @Assert(allow.isSome(), true)
        @Assert(allow.getOrThrow().contains("GET"), true)
    }

    /**
     * 测试默认 OPTIONS 处理 - 验证返回 200 和 Allow 头
     */
    @TestCase
    public func testDefaultOptions() {
        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18891/method")
            .method("OPTIONS")
            .build()
        let rsp = _client.send(req)
        @Assert(rsp.status, 200)
        let allow = rsp.headers.getFirst("Allow")
        @Assert(allow.isSome(), true)
        @Assert(allow.getOrThrow().contains("GET"), true)
    }

    /**
     * 测试分组内方法不允许 - 验证分组默认通配 handler 不会掩盖 405
     */
    @TestCase
    public func testGroupMethodNotAllowed() {
        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18891/g/foo")
            .method("PUT")
            .build()
        let rsp = _client.send(req)
        @Assert(rsp.status, 405)
    }

    /**
     * 测试分组内默认 OPTIONS - 验证分组默认通配 handler 不会掩盖 OPTIONS
     */
    @TestCase
    public func testGroupDefaultOptions() {
        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18891/g/foo")
            .method("OPTIONS")
            .build()
        let rsp = _client.send(req)
        @Assert(rsp.status, 200)
        let allow = rsp.headers.getFirst("Allow")
        @Assert(allow.isSome(), true)
        @Assert(allow.getOrThrow().contains("GET"), true)
    }

    /**
     * 测试文件不存在 - 验证 ctx.file 返回 404 而不是抛异常
     */
    @TestCase
    public func testFileNotFound() {
        let rsp = _client.get("http://127.0.0.1:18891/file-not-found")
        @Assert(rsp.status, 404)
    }

    /**
     * 测试 chunked 请求体 - 验证能够读取 chunked 传输的请求体
     */
    @TestCase
    public func testChunkedRequestBody() {
        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18891/echo-body")
            .post()
            .header("Transfer-Encoding", "chunked")
            .body(ChunkedBodyStream("chunked-body"))
            .build()
        let rsp = _client.send(req)
        @Assert(rsp.status, 200)
        @Assert(streamToString(rsp.body), "chunked-body")
    }

    /**
     * 测试大小写不敏感路由 - 验证路径参数保持原始大小写
     */
    @TestCase
    public func testCaseInsensitivePathParam() {
        let rsp = _client.get("http://127.0.0.1:18891/echo/AbCdEf")
        @Assert(rsp.status, 200)
        @Assert(streamToString(rsp.body), "AbCdEf")
    }
}

/**
 * 非 Seekable 的请求体流，使客户端使用 chunked 传输编码
 */
class ChunkedBodyStream <: InputStream {
    let _data: Array<Byte>
    var _pos: Int64 = 0

    init(data: String) {
        _data = data.toArray()
    }

    public func read(buffer: Array<Byte>): Int64 {
        if (_pos >= _data.size) {
            return 0
        }
        let n = min(Int64(buffer.size), Int64(_data.size) - _pos)
        _data.copyTo(buffer, 0, _pos, n)
        _pos += n
        n
    }
}
