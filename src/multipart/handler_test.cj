/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.multipart

import std.io.ByteBuffer
import std.fs.{Path, exists, remove}
import std.unittest.testmacro.*

@Test
public class MultiPartHandlerTestCaseSuit {
    /**
     * 测试内存处理器 - 验证 JoyMemoryMultiPartHandler 可以正确存储和读取分块数据
     */
    @TestCase
    public func testMemoryHandler() {
        let config = JoyMultiPartConfig()
        let handler = JoyMemoryMultiPartHandler(config)

        let part = JoyMultiPart()
        handler.onPart(part, "first data".toArray())
        handler.onPart(part, " second data".toArray())

        let content = handler.getContent(part.name)
        if (content.isNone()) {
            @Fail("should find the part content")
        }

        let text = String.fromUtf8(content.getOrThrow().bytes())
        if (text != "first data second data") {
            @Fail("content should be 'first data second data', got ${text}")
        }
    }

    /**
     * 测试内存处理器大小限制 - 验证当数据大小超过配置的 maxMemSize 限制时抛出 MultiPartLimitReachedException 异常
     */
    @TestCase
    public func testMemoryHandlerSizeLimit() {
        var config = JoyMultiPartConfig()
        config.maxMemSize = JoyDataSize(10) // 10 bytes limit
        let handler = JoyMemoryMultiPartHandler(config)

        let part = JoyMultiPart()
        try {
            handler.onPart(part, "12345678901".toArray()) // 11 bytes
            @Fail("should throw MultiPartLimitReachedException")
        } catch (e: MultiPartLimitReachedException) {
        }
    }

    /**
     * 测试函数式处理器 - 验证 JoyMultiPartFuncHandler 可以通过回调函数处理分块数据
     */
    @TestCase
    public func testFuncHandler() {
        let capturedData = [""]
        let handler = JoyMultiPartFuncHandler({ part: JoyMultiPart, data: Array<Byte> =>
            capturedData[0] += String.fromUtf8(data)
        })

        let part = JoyMultiPart()
        handler.onPart(part, "hello".toArray())
        handler.onPart(part, " world".toArray())

        if (capturedData[0] != "hello world") {
            @Fail("func handler should capture 'hello world', got ${capturedData[0]}")
        }
    }

    /**
     * 测试内存处理器关闭 - 验证调用 close() 后处理器状态变为已关闭且内容被清空
     */
    @TestCase
    public func testMemoryHandlerClose() {
        let config = JoyMultiPartConfig()
        let handler = JoyMemoryMultiPartHandler(config)

        let part = JoyMultiPart()
        handler.onPart(part, "data to be closed".toArray())

        handler.close()

        if (!handler.isClosed()) {
            @Fail("handler should be closed")
        }

        let content = handler.getContent(part.name)
        if (content.isSome()) {
            @Fail("content should be cleared after close")
        }
    }

    /**
     * 测试内存中多个分块 - 验证内存处理器可以同时存储和管理多个独立的分块数据
     */
    @TestCase
    public func testMultiplePartsInMemory() {
        let config = JoyMultiPartConfig()
        let handler = JoyMemoryMultiPartHandler(config)

        let part1 = JoyMultiPart()
        part1.setName("part1")
        handler.onPart(part1, "data1".toArray())

        let part2 = JoyMultiPart()
        part2.setName("part2")
        handler.onPart(part2, "data2".toArray())

        let part3 = JoyMultiPart()
        part3.setName("part3")
        handler.onPart(part3, "data3".toArray())

        let content1 = handler.getContent("part1")
        let content2 = handler.getContent("part2")
        let content3 = handler.getContent("part3")

        if (content1.isNone() || content2.isNone() || content3.isNone()) {
            @Fail("should find all parts")
        }

        if (String.fromUtf8(content1.getOrThrow().bytes()) != "data1") {
            @Fail("part1 content mismatch")
        }
        if (String.fromUtf8(content2.getOrThrow().bytes()) != "data2") {
            @Fail("part2 content mismatch")
        }
        if (String.fromUtf8(content3.getOrThrow().bytes()) != "data3") {
            @Fail("part3 content mismatch")
        }
    }

    /**
     * 测试磁盘文件大小限制按单个分块计算 - 多个小于限制的文件不应因总量超限而失败
     */
    @TestCase
    public func testDiskHandlerSizeLimitPerPart() {
        var config = JoyMultiPartConfig()
        config.maxFileSize = JoyDataSize(10)
        config.fileCacheDir = "./test_tmp_handler"
        let handler = JoyDiskMultiPartHandler(config)
        let str = #"--B
Content-Disposition: form-data; name="a"; filename="x.txt"

123456
--B
Content-Disposition: form-data; name="b"; filename="x.txt"

abcdef
--B--
"#
        let byteBuffer = ByteBuffer()
        byteBuffer.write(str.replace("\n", "\r\n").toArray())
        let parser = JoyMultiPartParser(config, handler, byteBuffer, "B")
        try {
            parser.parseParts()
            let fa = handler.getFile("a").getOrThrow()
            let fb = handler.getFile("b").getOrThrow()
            if (fa.info.path == fb.info.path) {
                @Fail("file parts with same filename should use different cache files")
            }
        } finally {
            handler.close()
            if (exists(Path(config.fileCacheDir))) {
                remove(config.fileCacheDir, recursive: true)
            }
        }
    }

    /**
     * 测试上传文件名中的路径穿越 - 缓存文件必须保留在配置的缓存目录内
     */
    @TestCase
    public func testDiskHandlerRejectsUnsafeFileName() {
        var config = JoyMultiPartConfig()
        config.fileCacheDir = "./test_tmp_handler"
        let handler = JoyDiskMultiPartHandler(config)
        let str = #"--B
Content-Disposition: form-data; name="a"; filename="../../evil.txt"

content
--B--
"#
        let byteBuffer = ByteBuffer()
        byteBuffer.write(str.replace("\n", "\r\n").toArray())
        let parser = JoyMultiPartParser(config, handler, byteBuffer, "B")
        try {
            parser.parseParts()
            let path = handler.getFile("a").getOrThrow().info.path.toString()
            if (path.contains("..")) {
                @Fail("uploaded file escaped cache dir: ${path}")
            }
        } finally {
            handler.close()
            if (exists(Path(config.fileCacheDir))) {
                remove(config.fileCacheDir, recursive: true)
            }
        }
    }
}
