/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.httpx

import cjoy.framework.JoySseBuilder

@Test
public class JoySSEventStreamCaseSuit {
    /**
     * 测试 SSE 事件流 - 验证单个事件单个字段的解析
     */
    @TestCase
    public func testOneEventOneField() {
        let httpStream = JoyHttpStream()
        httpStream.put(JoySseBuilder().id("test_id").build().toArray())

        let sse = JoySSEventStream(httpStream)
        let data = sse.next().getOrThrow()
        @Assert(data.id, "test_id")

        httpStream.markEOF()
        @Assert(sse.next().isNone())
    }

    /**
     * 测试 SSE 事件流 - 验证两个事件单个字段的解析
     */
    @TestCase
    public func testTwoEventOneField() {
        let httpStream = JoyHttpStream()
        httpStream.put(JoySseBuilder().id("test_id_1").build())
        httpStream.put(JoySseBuilder().id("test_id_2").build())
        let sse = JoySSEventStream(httpStream)

        var data = sse.next().getOrThrow()
        @Assert(data.id, "test_id_1")

        data = sse.next().getOrThrow()
        @Assert(data.id, "test_id_2")

        httpStream.markEOF()
        @Assert(sse.next().isNone())
    }

    /**
     * 测试 SSE 事件流 - 验证单个事件所有字段的解析
     */
    @TestCase
    public func testOneEventAllField() {
        let httpStream = JoyHttpStream()
        httpStream.put(
            JoySseBuilder().id("test_id").data("data").event("event").comment("comment").retry(1).build().toArray())

        let sse = JoySSEventStream(httpStream)
        let data = sse.next().getOrThrow()
        @Assert(data.id, "test_id")
        @Assert(data.data, "data")
        @Assert(data.event, "event")
        @Assert(data.comment, "comment")
        @Assert(data.retry, 1)

        httpStream.markEOF()
        @Assert(sse.next().isNone())
    }
}
