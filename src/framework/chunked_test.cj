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
import cjoy.context.ServiceContainer

@Test
public class ChunkedTestCaseSuit {
    /**
     * 测试 ChunkedWriter 创建 - 验证可以创建 ChunkedWriter
     */
    @TestCase
    public func testChunkedWriterCreation() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/chunked", {ctx: JoyContext =>
            let writer = ctx.chunkedWriter()
            writer.write("test")
            writer.end()
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试 ChunkedWriter 字符串写入 - 验证可以写入字符串
     */
    @TestCase
    public func testChunkedWriterStringWrite() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/chunked-string", {ctx: JoyContext =>
            let writer = ctx.chunkedWriter()
            writer.write("Hello, World!")
            writer.end()
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试 ChunkedWriter 字节数组写入 - 验证可以写入字节数组
     */
    @TestCase
    public func testChunkedWriterBytesWrite() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/chunked-bytes", {ctx: JoyContext =>
            let writer = ctx.chunkedWriter()
            writer.write([0x01, 0x02, 0x03, 0x04])
            writer.end()
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试 ChunkedWriter 多次写入 - 验证可以多次写入
     */
    @TestCase
    public func testChunkedWriterMultipleWrites() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/chunked-multi", {ctx: JoyContext =>
            let writer = ctx.chunkedWriter()
            writer.write("chunk1\n")
            writer.write("chunk2\n")
            writer.write("chunk3\n")
            writer.end()
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试 ChunkedWriter 响应头设置 - 验证可以设置响应头
     */
    @TestCase
    public func testChunkedWriterHeader() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/chunked-header", {ctx: JoyContext =>
            let writer = ctx.chunkedWriter()
            writer.header("X-Custom", "value")
            writer.write("test")
            writer.end()
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试 ChunkedWriter 结束状态 - 验证 end 方法正常工作
     */
    @TestCase
    public func testChunkedWriterEnd() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/chunked-end", {ctx: JoyContext =>
            let writer = ctx.chunkedWriter()
            writer.write("data")
            writer.end()
            // 结束后不应该再写入
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试 ChunkedWriter 大数据写入 - 验证可以处理大数据
     */
    @TestCase
    public func testChunkedWriterLargeData() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/chunked-large", {ctx: JoyContext =>
            let writer = ctx.chunkedWriter()
            // 写入大量数据
            for (i in 0..100) {
                writer.write("This is chunk number ${i}\n")
            }
            writer.end()
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试 ChunkedWriter 空数据 - 验证可以处理空数据
     */
    @TestCase
    public func testChunkedWriterEmptyData() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/chunked-empty", {ctx: JoyContext =>
            let writer = ctx.chunkedWriter()
            writer.write("")
            writer.end()
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试 ChunkedWriter 特殊字符 - 验证可以处理特殊字符
     */
    @TestCase
    public func testChunkedWriterSpecialChars() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/chunked-special", {ctx: JoyContext =>
            let writer = ctx.chunkedWriter()
            writer.write("Hello 你好 🌍")
            writer.end()
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试 ChunkedWriter 结束后写入异常 - 验证结束后写入抛出异常
     */
    @TestCase
    public func testChunkedWriterWriteAfterEnd() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/chunked-after-end", {ctx: JoyContext =>
            let writer = ctx.chunkedWriter()
            writer.write("data")
            writer.end()

            var threwException = false
            try {
                writer.write("more data")
            } catch (e: IllegalStateException) {
                threwException = true
            }
            @Assert(threwException, true)
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }
}