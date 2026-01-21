/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.schedule

import std.time.{DateTime, TimeZone}

@Test
public class CronTickTestCaseSuit {
    @TestCase
    public func testTick() {
        let dt = DateTime.of(year: 2025, month: 10, dayOfMonth: 1, hour: 12, minute: 30, second: 55, nanosecond: 0,
            timeZone: TimeZone.Local)
        let tick = CronTick.of(dt)
        let exp = #"CronTick(sec: 55, min: 30, hour: 12, day: 1, month: 10, dayOfWeek: 3)"#
        @Assert(tick.toString(), exp)
    }
}
