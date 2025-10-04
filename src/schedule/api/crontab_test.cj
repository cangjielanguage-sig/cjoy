/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.schedule.api

import std.sync.SyncCounter

@Test
public class CrontabTestCaseSuit {
    @TestCase
    public func testRun() {
        let crontab = Crontab()
        let count = SyncCounter(1)
        crontab.addJob("test1", "* * * * * *", {
            ctx: ScheduleContext => count.dec()
        })
        count.waitUntilZero()
    }
}
