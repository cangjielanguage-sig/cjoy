/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.test

import std.unittest.testmacro.*
import stdx.net.http.*
import cjoy.*
import std.convert.*

@Test
public class FileServerTestCaseSuit {
    var _instance: ?Joy = None
    var _client = ClientBuilder().build()

    @BeforeAll
    func setup() {
        spawn {
            let joy = Joy.default()
            let router = joy.router
            router.staticFile("/static/logo.png", "./doc/imgs/logo.png")
            router.staticFs("/static", "./doc")
            _instance = joy
            joy.run("127.0.0.1", 18882)
        }
        sleep(Duration.second)
    }

    @AfterAll
    func tearDown() {
        _instance?.shutdown()
    }

    @AfterEach
    func tearDownEach() {
        _client.close()
        _client = ClientBuilder().build()
    }

    /**
     * 测试静态文件服务 - 验证直接访问静态文件的功能
     */
    @TestCase
    public func testStaticFile() {
        let rsp = _client.get("http://127.0.0.1:18882/static/logo.png")
        @Assert(rsp.status, 200)
        @Assert(rsp.headers.getFirst("content-type"), "image/png")
    }

    /**
     * 测试静态文件系统获取图片文件 - 验证从静态文件系统中获取图片文件的功能
     */
    @TestCase
    public func testStaticFsGetImgFile() {
        let rsp = _client.get("http://127.0.0.1:18882/static/imgs/logo.png")
        @Assert(rsp.status, 200)
        @Assert(rsp.headers.getFirst("content-type"), "image/png")
    }

    /**
     * 测试静态文件系统获取文本文件 - 验证从静态文件系统中获取文本文件的功能
     */
    @TestCase
    public func testStaticFsGetTextFile() {
        let rsp = _client.get("http://127.0.0.1:18882/static/dev_guide/README.md")
        @Assert(rsp.status, 200)
    }

    // ====== Range Request Tests (断点续传测试) ======

    /**
     * 测试单范围请求 - 验证 bytes=0-1023 范围请求的处理
     */
    @TestCase
    public func testRangeRequestSingleRange() {
        // 测试单个 Range 请求: bytes=0-1023
        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18882/static/imgs/logo.png")
            .header("Range", "bytes=0-1023")
            .build()
        let rsp = _client.send(req)

        // 验证状态码为 206 Partial Content
        @Assert(rsp.status, 206)
        @Assert(rsp.headers.getFirst("Accept-Ranges"), "bytes")

        // 验证 Content-Range 头
        let contentRange = rsp.headers.getFirst("Content-Range")
        if (contentRange.isNone()) {
            @Fail("Content-Range header missing")
        }
        let range = contentRange.getOrThrow()
        @Assert(range.startsWith("bytes 0-1023/"), true)
    }

    /**
     * 测试从偏移量开始的范围请求 - 验证 bytes=100- 范围请求的处理
     */
    @TestCase
    public func testRangeRequestFromOffset() {
        // 测试从偏移量开始的 Range 请求: bytes=100-
        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18882/static/imgs/logo.png")
            .header("Range", "bytes=100-")
            .build()
        let rsp = _client.send(req)

        @Assert(rsp.status, 206)
        @Assert(rsp.headers.getFirst("Accept-Ranges"), "bytes")

        // 验证 Content-Range 头
        let contentRange = rsp.headers.getFirst("Content-Range")
        if (contentRange.isNone()) {
            @Fail("Content-Range header missing")
        }
        let range = contentRange.getOrThrow()
        @Assert(range.startsWith("bytes 100-"), true)
    }

    /**
     * 测试获取最后 N 字节的范围请求 - 验证 bytes=-512 范围请求的处理
     */
    @TestCase
    public func testRangeRequestLastNBytes() {
        // 测试获取最后 N 字节的 Range 请求: bytes=-512
        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18882/static/imgs/logo.png")
            .header("Range", "bytes=-512")
            .build()
        let rsp = _client.send(req)

        @Assert(rsp.status, 206)
        @Assert(rsp.headers.getFirst("Accept-Ranges"), "bytes")

        // 验证 Content-Range 头
        let contentRange = rsp.headers.getFirst("Content-Range")
        if (contentRange.isNone()) {
            @Fail("Content-Range header missing")
        }
        let range = contentRange.getOrThrow()
        @Assert(range.contains("/"), true)
    }

    /**
     * 测试多范围请求 - 验证 bytes=0-100,200-300 范围请求的处理
     */
    @TestCase
    public func testRangeRequestMultiRange() {
        // 测试多个 Range 请求: bytes=0-100,200-300
        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18882/static/imgs/logo.png")
            .header("Range", "bytes=0-100,200-300")
            .build()
        let rsp = _client.send(req)

        // 多个 Range 请求应返回 206 状态码
        @Assert(rsp.status, 206)
        @Assert(rsp.headers.getFirst("Accept-Ranges"), "bytes")

        // 验证 Content-Type 应为 multipart/byteranges
        let contentType = rsp.headers.getFirst("Content-Type")
        if (contentType.isNone()) {
            @Fail("Content-Type header missing for multipart response")
        }
        let ct = contentType.getOrThrow()
        @Assert(ct.contains("multipart/byteranges"), true)
    }

    /**
     * 测试无效的范围请求（开始位置大于结束位置）- 验证 bytes=500-100 范围请求的处理
     */
    @TestCase
    public func testRangeRequestInvalidStartEnd() {
        // 测试无效的 Range 请求: start > end (bytes=500-100)
        // 虽然都在文件范围内，但 start > end 是无效的
        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18882/static/imgs/logo.png")
            .header("Range", "bytes=500-100")
            .build()
        let rsp = _client.send(req)

        // 应返回 416 Requested Range Not Satisfiable
        @Assert(rsp.status, 416)
    }

    /**
     * 测试接近文件末尾的范围请求 - 验证 bytes=18000- 范围请求的处理
     */
    @TestCase
    public func testRangeRequestNearEndOfFile() {
        // 测试接近文件末尾的 Range 请求: bytes=18000-
        // 这是一个有效的 Range 请求，应该返回 206
        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18882/static/imgs/logo.png")
            .header("Range", "bytes=18000-")
            .build()
        let rsp = _client.send(req)

        // 应返回 206 Partial Content
        @Assert(rsp.status, 206)
        @Assert(rsp.headers.getFirst("Accept-Ranges"), "bytes")

        let contentRange = rsp.headers.getFirst("Content-Range")
        if (contentRange.isNone()) {
            @Fail("Content-Range header missing")
        }
        let range = contentRange.getOrThrow()
        // 应该从 18000 开始
        @Assert(range.startsWith("bytes 18000-"), true)
    }

    /**
     * 测试无效格式的范围请求 - 验证 bytes=abc-def 范围请求的处理
     */
    @TestCase
    public func testRangeRequestInvalidFormat() {
        // 测试无效格式的 Range 请求: bytes=abc-def
        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18882/static/imgs/logo.png")
            .header("Range", "bytes=abc-def")
            .build()
        let rsp = _client.send(req)

        // 应返回 416 Requested Range Not Satisfiable
        @Assert(rsp.status, 416)
    }

    /**
     * 测试带有 ETag 的范围请求 - 验证 Range 请求与 ETag 配合使用的功能
     */
    @TestCase
    public func testRangeRequestWithETag() {
        // 测试 Range 请求与 ETag 配合使用
        // 首先获取完整文件，获取 ETag
        let rsp1 = _client.get("http://127.0.0.1:18882/static/imgs/logo.png")
        let eTag = rsp1.headers.getFirst("ETag")

        if (eTag.isNone()) {
            @Fail("ETag header missing")
        }
        let tag = eTag.getOrThrow()

        // 使用 ETag 和 If-Range 进行条件 Range 请求
        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18882/static/imgs/logo.png")
            .header("Range", "bytes=0-1023")
            .header("If-Range", tag)
            .build()
        let rsp2 = _client.send(req)

        @Assert(rsp2.status, 206)
        @Assert(rsp2.headers.getFirst("Accept-Ranges"), "bytes")
    }

    /**
     * 测试断点续传功能 - 验证 Range 请求实现断点续传的功能
     */
    @TestCase
    public func testRangeRequestResumeDownload() {
        // 模拟断点续传场景：
        // 1. 先下载文件的前 512 字节
        // 2. 使用 Range 请求下载剩余部分
        let url = "http://127.0.0.1:18882/static/imgs/logo.png"

        // 获取完整文件大小
        let fullRsp = _client.get(url)
        let fileSizeStr = fullRsp.headers.getFirst("Content-Length")

        if (fileSizeStr.isNone()) {
            @Fail("Content-Length header missing")
        }
        let sizeStr = fileSizeStr.getOrThrow()
        let fileSize = Int.parse(sizeStr)

        if (fileSize <= 512) {
            @Fail("File too small for resume test")
        }

        // 模拟下载前 512 字节
        let bytesToDownload = 512
        let remainingBytes = fileSize - bytesToDownload

        // 使用 Range 请求下载剩余部分
        let req = HttpRequestBuilder()
            .url(url)
            .header("Range", "bytes=${bytesToDownload}-")
            .build()
        let rsp = _client.send(req)

        // 验证断点续传响应
        @Assert(rsp.status, 206)

        let contentRange = rsp.headers.getFirst("Content-Range")
        if (contentRange.isNone()) {
            @Fail("Content-Range header missing")
        }
        let range = contentRange.getOrThrow()

        // Content-Range 应为 "bytes 512-<total>/fileSize"
        @Assert(range.startsWith("bytes ${bytesToDownload}-"), true)
        @Assert(range.endsWith("/${fileSize}"), true)

        // 验证返回的内容长度
        let contentLength = rsp.headers.getFirst("Content-Length")
        if (contentLength.isNone()) {
            @Fail("Content-Length header missing")
        }
        let lenStr = contentLength.getOrThrow()
        let len = Int.parse(lenStr)
        @Assert(len, remainingBytes)
    }

    /**
     * 测试 HEAD 方法的范围请求 - 验证使用 HEAD 方法进行范围请求的功能（已跳过）
     */
    @TestCase
    @Skip
    public func testRangeRequestHeadMethod() {
        // 测试 HEAD 方法与 Range 请求
        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18882/static/imgs/logo.png")
            .head()
            .header("Range", "bytes=0-1023")
            .build()
        let rsp = _client.send(req)

        // HEAD 请求应返回 206，但不包含响应体
        @Assert(rsp.status, 206)
        // 验证 Content-Length 仍然存在
        let contentLength = rsp.headers.getFirst("Content-Length")
        @Assert(contentLength.isSome(), true)
    }

    /**
     * 测试条件请求 If-None-Match - 验证使用 If-None-Match 条件请求的功能
     */
    @TestCase
    public func testConditionalRequestIfNoneMatch() {
        // 测试条件请求 If-None-Match
        let url = "http://127.0.0.1:18882/static/imgs/logo.png"

        // 获取 ETag
        let rsp1 = _client.get(url)
        let eTag = rsp1.headers.getFirst("ETag")

        if (eTag.isNone()) {
            @Fail("ETag header missing")
        }
        let tag = eTag.getOrThrow()

        // 使用 If-None-Match 发送条件请求
        let req = HttpRequestBuilder()
            .url(url)
            .header("If-None-Match", tag)
            .build()
        let rsp2 = _client.send(req)

        // 如果资源未修改，应返回 304 Not Modified
        @Assert(rsp2.status, 304)
    }

    /**
     * 测试文本文件的范围请求 - 验证对文本文件的 Range 请求功能
     */
    @TestCase
    public func testTextFileRangeRequest() {
        // 测试文本文件的 Range 请求
        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18882/static/dev_guide/README.md")
            .header("Range", "bytes=0-99")
            .build()
        let rsp = _client.send(req)

        @Assert(rsp.status, 206)
        @Assert(rsp.headers.getFirst("Accept-Ranges"), "bytes")

        let contentRange = rsp.headers.getFirst("Content-Range")
        if (contentRange.isNone()) {
            @Fail("Content-Range header missing")
        }
        let range = contentRange.getOrThrow()
        @Assert(range.startsWith("bytes 0-99/"), true)
    }
}
