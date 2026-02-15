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

import std.sync.SyncCounter
import std.unittest.testmacro.*

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

    @TestCase
    public func testAddJob() {
        let crontab = Crontab()
        crontab.addJob("test1", "* * * * * *", {
            ctx: ScheduleContext => eprintln("test1")
        })
        @Assert(crontab.exists("test1"), true)
        @Assert(crontab.getJobNames().size, 1)
    }

    @TestCase
    public func testAddJobIfAbsent() {
        let crontab = Crontab()
        crontab.addJobIfAbsent("test1", "* * * * * *", {
            ctx: ScheduleContext => eprintln("test1")
        })
        @Assert(crontab.exists("test1"), true)
        crontab.addJobIfAbsent("test1", "* * * * * *", {
            ctx: ScheduleContext => eprintln("test1 duplicate")
        })
        @Assert(crontab.getJobNames().size, 1)
    }

    @TestCase
    public func testRemoveJob() {
        let crontab = Crontab()
        crontab.addJob("test1", "* * * * * *", {
            ctx: ScheduleContext => eprintln("test1")
        })
        @Assert(crontab.removeJob("test1"), true)
        @Assert(crontab.exists("test1"), false)
        @Assert(crontab.getJobNames().size, 0)
    }

    @TestCase
    public func testRemoveNonExistentJob() {
        let crontab = Crontab()
        @Assert(crontab.removeJob("nonexistent"), false)
    }

    @TestCase
    public func testExists() {
        let crontab = Crontab()
        @Assert(crontab.exists("test1"), false)
        crontab.addJob("test1", "* * * * * *", {
            ctx: ScheduleContext => eprintln("test1")
        })
        @Assert(crontab.exists("test1"), true)
    }

    @TestCase
    public func testGetJobNames() {
        let crontab = Crontab()
        crontab.addJob("test1", "* * * * * *", {
            ctx: ScheduleContext => eprintln("test1")
        })
        crontab.addJob("test2", "* * * * * *", {
            ctx: ScheduleContext => eprintln("test2")
        })
        let names = crontab.getJobNames()
        @Assert(names.size, 2)
        @Assert(names.contains("test1"), true)
        @Assert(names.contains("test2"), true)
    }

    @TestCase
    public func testAddJobDuplicate() {
        let crontab = Crontab()
        crontab.addJob("test1", "* * * * * *", {
            ctx: ScheduleContext => eprintln("test1")
        })
        try {
            crontab.addJob("test1", "* * * * * *", {
                ctx: ScheduleContext => eprintln("test1 duplicate")
            })
            @Fail("should throw ScheduleException")
        } catch (ex: ScheduleException) {
            eprintln(ex.message)
            @Assert(ex.message.contains("existed"))
        }
    }

    @TestCase
    public func testClose() {
        let crontab = Crontab()
        @Assert(crontab.isClosed(), false)
        crontab.close()
        @Assert(crontab.isClosed(), true)
    }

    @TestCase
    public func testDestroy() {
        let crontab = Crontab()
        @Assert(crontab.isClosed(), false)
        crontab.destroy()
        @Assert(crontab.isClosed(), true)
    }

    @TestCase
    public func testTaskExecution() {
        let crontab = Crontab()
        let counter = SyncCounter(2) // 期望执行2次
        crontab.addJob("testTask", "* * * * * *", {
            ctx: ScheduleContext => counter.dec()
        })
        counter.waitUntilZero()
        @Assert(crontab.exists("testTask"), true)
    }

    @TestCase
    public func testConcurrentExecution() {
        let crontab = Crontab()
        let counter1 = SyncCounter(2)
        let counter2 = SyncCounter(2)
        crontab.addJob("testConcurrent1", "* * * * * *", {
            ctx: ScheduleContext => counter1.dec()
        })
        crontab.addJob("testConcurrent2", "* * * * * *", {
            ctx: ScheduleContext => counter2.dec()
        })
        counter1.waitUntilZero()
        counter2.waitUntilZero()
        @Assert(crontab.getJobNames().size, 2)
    }
}
