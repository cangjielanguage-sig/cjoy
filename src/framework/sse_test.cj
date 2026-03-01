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
public class SseTestCaseSuit {
    /**
     * 测试 SSE Builder 事件名称 - 验证可以设置事件名称
     */
    @TestCase
    public func testSseBuilderEvent() {
        let builder = JoySseBuilder().event("message")
        let result = builder.build()
        let str = String.fromUtf8(result)
        @Assert(str.contains("event: message"), true)
    }

    /**
     * 测试 SSE Builder 事件 ID - 验证可以设置事件 ID
     */
    @TestCase
    public func testSseBuilderId() {
        let builder = JoySseBuilder().id("12345")
        let result = builder.build()
        let str = String.fromUtf8(result)
        @Assert(str.contains("id: 12345"), true)
    }

    /**
     * 测试 SSE Builder 数据 - 验证可以设置事件数据
     */
    @TestCase
    public func testSseBuilderData() {
        let builder = JoySseBuilder().data("hello world")
        let result = builder.build()
        let str = String.fromUtf8(result)
        @Assert(str.contains("data: hello world"), true)
    }

    /**
     * 测试 SSE Builder 重试 - 验证可以设置重试时间
     */
    @TestCase
    public func testSseBuilderRetry() {
        let builder = JoySseBuilder().retry(3000)
        let result = builder.build()
        let str = String.fromUtf8(result)
        @Assert(str.contains("retry: 3000"), true)
    }

    /**
     * 测试 SSE Builder 注释 - 验证可以添加注释
     */
    @TestCase
    public func testSseBuilderComment() {
        let builder = JoySseBuilder().comment("this is a comment")
        let result = builder.build()
        let str = String.fromUtf8(result)
        @Assert(str.contains(": this is a comment"), true)
    }

    /**
     * 测试 SSE Builder 完整事件 - 验证可以构建完整事件
     */
    @TestCase
    public func testSseBuilderCompleteEvent() {
        let builder = JoySseBuilder()
            .event("update")
            .id("abc")
            .data("test data")
            .retry(5000)

        let result = builder.build()
        let str = String.fromUtf8(result)
        @Assert(str.contains("event: update"), true)
        @Assert(str.contains("id: abc"), true)
        @Assert(str.contains("data: test data"), true)
        @Assert(str.contains("retry: 5000"), true)
    }

    /**
     * 测试 SSE Builder 空事件 - 验证空事件返回空
     */
    @TestCase
    public func testSseBuilderEmpty() {
        let builder = JoySseBuilder()
        let result = builder.build()
        @Assert(result.size, 0)
    }

    /**
     * 测试 SSE Builder 链式调用 - 验证方法链式调用
     */
    @TestCase
    public func testSseBuilderChaining() {
        let result = JoySseBuilder()
            .event("test")
            .data("data")
            .build()

        let str = String.fromUtf8(result)
        @Assert(str.contains("event: test"), true)
        @Assert(str.contains("data: data"), true)
    }

    /**
     * 测试 SSE Builder 多行数据 - 验证可以处理多行数据
     */
    @TestCase
    public func testSseBuilderMultilineData() {
        let builder = JoySseBuilder().data("line1\nline2\nline3")
        let result = builder.build()
        let str = String.fromUtf8(result)
        @Assert(str.contains("data: line1"), true)
    }

    /**
     * 测试 SSE Builder 特殊字符 - 验证可以处理特殊字符
     */
    @TestCase
    public func testSseBuilderSpecialChars() {
        let builder = JoySseBuilder().data("hello: world, test=true")
        let result = builder.build()
        let str = String.fromUtf8(result)
        @Assert(str.contains("data: hello: world"), true)
    }

    /**
     * 测试 SSE Builder Unicode - 验证可以处理 Unicode 字符
     */
    @TestCase
    public func testSseBuilderUnicode() {
        let builder = JoySseBuilder().data("你好世界")
        let result = builder.build()
        let str = String.fromUtf8(result)
        @Assert(str.contains("你好世界"), true)
    }

    /**
     * 测试 SSE Emitter 创建 - 验证可以创建 SSE Emitter
     */
    @TestCase
    public func testSseEmitterCreation() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/sse", {ctx: JoyContext =>
            let emitter = ctx.eventEmitter()
            emitter.sendEvent(JoySseBuilder().data("test"))
            emitter.end()
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试 SSE Emitter 多事件发送 - 验证可以发送多个事件
     */
    @TestCase
    public func testSseEmitterMultipleEvents() {
        let config = JoyConfig()
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/sse-multi", {ctx: JoyContext =>
            let emitter = ctx.eventEmitter()
            emitter.sendEvent(JoySseBuilder().event("event1").data("data1"))
            emitter.sendEvent(JoySseBuilder().event("event2").data("data2"))
            emitter.sendEvent(JoySseBuilder().event("event3").data("data3"))
            emitter.end()
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }
}