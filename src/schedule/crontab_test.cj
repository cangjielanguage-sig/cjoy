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
    /**
     * 测试 Crontab 的运行功能 - 验证任务能够正常执行
     */
    @TestCase
    public func testRun() {
        let crontab = Crontab()
        let count = SyncCounter(1)
        crontab.addJob("test1", "* * * * * *", {
            ctx: ScheduleContext => count.dec()
        })
        count.waitUntilZero()
    }

    /**
     * 测试添加任务 - 验证任务能够成功添加到 Crontab 中
     */
    @TestCase
    public func testAddJob() {
        let crontab = Crontab()
        crontab.addJob("test1", "* * * * * *", {
            ctx: ScheduleContext => eprintln("test1")
        })
        @Assert(crontab.exists("test1"), true)
        @Assert(crontab.getJobNames().size, 1)
    }

    /**
     * 测试条件添加任务 - 验证只有在任务不存在时才会添加
     */
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

    /**
     * 测试移除任务 - 验证任务能够成功从 Crontab 中移除
     */
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

    /**
     * 测试移除不存在的任务 - 验证移除不存在的任务时不会报错
     */
    @TestCase
    public func testRemoveNonExistentJob() {
        let crontab = Crontab()
        @Assert(crontab.removeJob("nonexistent"), false)
    }

    /**
     * 测试任务存在性检查 - 验证能够正确判断任务是否存在
     */
    @TestCase
    public func testExists() {
        let crontab = Crontab()
        @Assert(crontab.exists("test1"), false)
        crontab.addJob("test1", "* * * * * *", {
            ctx: ScheduleContext => eprintln("test1")
        })
        @Assert(crontab.exists("test1"), true)
    }

    /**
     * 测试获取任务名称列表 - 验证能够正确获取所有任务的名称
     */
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

    /**
     * 测试添加重复任务 - 验证添加重复名称的任务时会抛出异常
     */
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

    /**
     * 测试关闭 Crontab - 验证 Crontab 能够正确关闭
     */
    @TestCase
    public func testClose() {
        let crontab = Crontab()
        @Assert(crontab.isClosed(), false)
        crontab.close()
        @Assert(crontab.isClosed(), true)
    }

    /**
     * 测试销毁 Crontab - 验证 Crontab 能够正确销毁
     */
    @TestCase
    public func testDestroy() {
        let crontab = Crontab()
        @Assert(crontab.isClosed(), false)
        crontab.destroy()
        @Assert(crontab.isClosed(), true)
    }

    /**
     * 测试任务执行 - 验证任务能够按照预期的次数执行
     */
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

    /**
     * 测试并发执行任务 - 验证多个任务能够同时正常执行
     */
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
