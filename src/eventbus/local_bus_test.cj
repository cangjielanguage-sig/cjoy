/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.eventbus

import std.sync.{SyncCounter, AtomicInt64}
import std.collection.ArrayList
import cjoy.context.{Context, MapContext}
import cjoy.macros.*

@Test
public class LocalEventBusTestCase {
    /**
     * 测试单个订阅者 - 验证事件发布后订阅者能够接收到事件
     */
    @TestCase
    public func testOneSubscriber(): Unit {
        let bs = LocalEventBus()
        let counter = AtomicInt64(1)
        bs.onEvent("e1", "test", {
            _: Context, evt: Event => counter.fetchAdd(-1)
        })
        bs.fireEvent(MapContext(), Event.of("e1").addData("k1", "v1"))
        @Assert(counter.load(), 0)
    }

    /**
     * 测试两个订阅者 - 验证事件发布后多个订阅者都能接收到事件
     */
    @TestCase
    public func testTwoSubscriber(): Unit {
        let bs = LocalEventBus()
        let counter = AtomicInt64(2)
        bs.onEvent("e1", "test1", {
            _: Context, evt: Event => counter.fetchAdd(-1)
        })
        bs.onEvent("e1", "test2", {
            _: Context, evt: Event => counter.fetchAdd(-1)
        })
        bs.fireEvent(MapContext(), Event.of("e1").addData("k1", "v1"))
        @Assert(counter.load(), 0)
    }

    /**
     * 测试事件优先级 - 验证高优先级的订阅者会先接收到事件
     */
    @TestCase
    public func testPriority1(): Unit {
        let bs = LocalEventBus()
        let data = ArrayList<Int>()
        bs.onEvent(
            "e1",
            "test1",
            {
                _: Context, evt: Event => data.add(2)
            },
            2
        )
        bs.onEvent(
            "e1",
            "test2",
            {
                _: Context, evt: Event => data.add(1)
            },
            1
        )
        bs.fireEvent(MapContext(), Event.of("e1").addData("k1", "v1"))
        @Assert(data.toArray(), [2, 1])
    }

    /**
     * 测试事件终止 - 验证高优先级订阅者可以终止事件传递，低优先级订阅者不会接收到事件
     */
    @TestCase
    public func testPriority2(): Unit {
        let bs = LocalEventBus()
        let data = ArrayList<Int>()
        bs.onEvent(
            "e1",
            "test1",
            {
                _: Context, evt: Event =>
                evt.abort()
                data.add(2)
            },
            2
        )
        bs.onEvent(
            "e1",
            "test2",
            {
                _: Context, evt: Event => data.add(1)
            },
            1
        )
        bs.fireEvent(MapContext(), Event.of("e1").addData("k1", "v1"))
        @Assert(data.toArray(), [2])
    }

    /**
     * 测试事件匹配 - 验证只有匹配事件名称的订阅者会接收到事件
     */
    @TestCase
    public func testTwoSubscriberOneMatch(): Unit {
        let bs = LocalEventBus()
        let counter = AtomicInt64(1)
        bs.onEvent("e1", "test1", {
            _: Context, evt: Event => counter.fetchAdd(-1)
        })
        bs.onEvent("e2", "test2", {
            _: Context, evt: Event => counter.fetchAdd(-1)
        })
        bs.fireEvent(MapContext(), Event.of("e1").addData("k1", "v1"))
        @Assert(counter.load(), 0)
    }

    /**
     * 测试精确匹配和通配符匹配 - 验证精确匹配和通配符匹配的订阅者都能接收到事件
     */
    @TestCase
    public func testExactAndWildcardMatch(): Unit {
        let bs = LocalEventBus()
        let counter = AtomicInt64(2)
        bs.onEvent("e1", "test1", {
            _: Context, evt: Event => counter.fetchAdd(-1)
        })
        bs.onEvent("**", "test2", {
            _: Context, evt: Event => counter.fetchAdd(-1)
        })
        bs.fireEvent(MapContext(), Event.of("e1").addData("k1", "v1"))
        @Assert(counter.load(), 0)
    }

    /**
     * 测试各种通配符模式匹配 - 验证多种通配符模式都能正确匹配事件名称
     */
    @TestCase
    public func testOneWildcardMath(): Unit {
        let patterns = ["**.c.d", "a.b.**", "*.b.c.d", "*.*.c.d", "*.*.*.d", "*.*.*.*", "a.*.c.d", "a.*.*.d", "a.*.c.*"]
        for (p in patterns) {
            let bs = LocalEventBus()
            let counter = AtomicInt64(1)
            bs.onEvent(p, "test", {
                _: Context, evt: Event => counter.fetchAdd(-1)
            })
            bs.fireEvent(MapContext(), Event.of("a.b.c.d").addData("k1", "v1"))
            @Assert(counter.load(), 0)
            bs.closeAndWait()
        }
    }
    /**
     * 测试无效模式 - 验证无效的事件模式会抛出异常
     */
    @TestCase
    public func testInvalidPattern(): Unit {
        let patterns = ["**.**.d", "a.**.d", "a.**.**", "a.123*", "a.1*2.b"]
        let bs = LocalEventBus()
        for (p in patterns) {
            try {
                bs.onEvent(p, "test", {
                    _: Context, evt: Event => ()
                })
                @Fail("should throw EventBusException, ${p}")
            } catch (ex: EventBusException) {
                @Assert(ex.message.contains("invalid pattern"))
            }
        }
    }

    /**
     * 测试异步事件发布 - 验证异步发布事件时订阅者能够接收到事件
     */
    @TestCase
    public func testFireEventAsync(): Unit {
        let bs = LocalEventBus()
        let counter = SyncCounter(1)
        bs.onEvent("e1", "test", {
            _: Context, evt: Event => counter.dec()
        })
        bs.fireEventAsync(MapContext(), Event.of("e1").addData("k1", "v1"))
        counter.waitUntilZero(timeout: Duration.second)
        @Assert(counter.count, 0)
    }

    /**
     * 测试异步事件发布方法 - 验证 asyncFireEvent 方法能够正确发布事件
     */
    @TestCase
    public func testAsyncFireEvent(): Unit {
        let bs = LocalEventBus()
        let counter = SyncCounter(1)
        bs.onEvent("e1", "test", {
            _: Context, evt: Event => counter.dec()
        })
        bs.asyncFireEvent(MapContext(), Event.of("e1").addData("k1", "v1"))
        counter.waitUntilZero(timeout: Duration.second)
        @Assert(counter.count, 0)
    }

    /**
     * 测试事件不匹配 - 验证订阅者订阅的事件与发布的事件不匹配时不会接收到事件
     */
    @TestCase
    public func testNoMatch1(): Unit {
        let bs = LocalEventBus()
        let counter = AtomicInt64(1)
        bs.onEvent("e2", "test", {
            _: Context, evt: Event => counter.fetchAdd(-1)
        })
        bs.fireEvent(MapContext(), Event.of("e1").addData("k1", "v1"))
        @Assert(counter.load(), 1)
    }

    /**
     * 测试模式不匹配 - 验证通配符模式与事件名称不匹配时不会接收到事件
     */
    @TestCase
    public func testNoMatch2(): Unit {
        let bs = LocalEventBus()
        let counter = AtomicInt64(1)
        bs.onEvent("a.b.*.1", "test", {
            _: Context, evt: Event => counter.fetchAdd(-1)
        })
        bs.fireEvent(MapContext(), Event.of("a.b.c.d").addData("k1", "v1"))
        @Assert(counter.load(), 1)
    }

    /**
     * 测试模式前缀不匹配 - 验证事件名称比模式更长时不会匹配
     */
    @TestCase
    public func testNoMatch3(): Unit {
        let bs = LocalEventBus()
        let counter = AtomicInt64(1)
        bs.onEvent("a.b.c", "test", {
            _: Context, evt: Event => counter.fetchAdd(-1)
        })
        bs.fireEvent(MapContext(), Event.of("a.b.c.d").addData("k1", "v1"))
        @Assert(counter.load(), 1)
    }
}
