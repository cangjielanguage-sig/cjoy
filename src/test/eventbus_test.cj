/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.test

import cjoy.context.{Context, MapContext, GLOBAL_SERVICE_CONTAINER}
import cjoy.eventbus.*
import std.sync.{SyncCounter, AtomicInt64}

private let counter = AtomicInt64(0)

@SubscribeEvent[name = "sub1", pattern = "a.b.**"]
func handleEvent1(ctx: Context, evt: Event): Unit {
    counter.fetchAdd(1)
}

@SubscribeEvent[name = "sub2", pattern = "a.b.c.d"]
func handleEvent2(ctx: Context, evt: Event): Unit {
    counter.fetchAdd(1)
}

@Test
public class EventBusServiceTestCaseSuit {
    @TestCase
    public func test(): Unit {
        let bus = GLOBAL_SERVICE_CONTAINER.getService<EventBus>("eventbus").getOrThrow()
        bus.fireEvent(MapContext(), Event.of("a.b.c.d").addData("k1", "v1"))
        @Assert(counter.load(), 2)
    }
}
