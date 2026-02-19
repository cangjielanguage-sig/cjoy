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

import std.collection.HashSet
import std.unittest.testmacro.*
import std.time.DateTime

class TestCronJob {
    TestCronJob(let name: String, let schedule: String, let expJob: CronJob) {
    }
}

class TestCronJobErr {
    TestCronJobErr(let name: String, let schedules: Array<String>, let expErrStr: String) {
    }
}

func jobrun(ctx: ScheduleContext): Unit {
}

@Test
public class CronJobTestCaseSuit {
    /**
     * 测试 Cron 表达式解析成功的场景 - 验证各种有效的 Cron 表达式能够正确解析
     */
    @TestCase
    public func testParseSuccess() {
        let cases = [
            TestCronJob(
                "t1",
                "* * * * * *",
                CronJob(
                    "t1",
                    jobrun,
                    sec: CronJob.getDefaultJobField(0, 59, 1),
                    min: CronJob.getDefaultJobField(0, 59, 1),
                    hour: CronJob.getDefaultJobField(0, 23, 1),
                    day: CronJob.getDefaultJobField(1, 31, 1),
                    month: CronJob.getDefaultJobField(1, 12, 1),
                    dayOfWeek: CronJob.getDefaultJobField(0, 6, 1)
                )
            ),
            TestCronJob(
                "t2",
                "*/3 * * * *",
                CronJob(
                    "t2",
                    jobrun,
                    min: CronJob.getDefaultJobField(0, 59, 3),
                    hour: CronJob.getDefaultJobField(0, 23, 1),
                    day: CronJob.getDefaultJobField(1, 31, 1),
                    month: CronJob.getDefaultJobField(1, 12, 1),
                    dayOfWeek: CronJob.getDefaultJobField(0, 6, 1)
                )
            ),
            TestCronJob(
                "t3",
                "1,5,10 * * * *",
                CronJob(
                    "t3",
                    jobrun,
                    min: HashSet([1, 5, 10]),
                    hour: CronJob.getDefaultJobField(0, 23, 1),
                    day: CronJob.getDefaultJobField(1, 31, 1),
                    month: CronJob.getDefaultJobField(1, 12, 1),
                    dayOfWeek: CronJob.getDefaultJobField(0, 6, 1)
                )
            ),
            TestCronJob(
                "t4",
                "*/20 3-5 * * *",
                CronJob(
                    "t4",
                    jobrun,
                    min: CronJob.getDefaultJobField(0, 59, 20),
                    hour: CronJob.getDefaultJobField(3, 5, 1),
                    day: CronJob.getDefaultJobField(1, 31, 1),
                    month: CronJob.getDefaultJobField(1, 12, 1),
                    dayOfWeek: CronJob.getDefaultJobField(0, 6, 1)
                )
            ),
            TestCronJob(
                "t5",
                "*/20 3-5/2 * * *",
                CronJob(
                    "t5",
                    jobrun,
                    min: CronJob.getDefaultJobField(0, 59, 20),
                    hour: CronJob.getDefaultJobField(3, 5, 2),
                    day: CronJob.getDefaultJobField(1, 31, 1),
                    month: CronJob.getDefaultJobField(1, 12, 1),
                    dayOfWeek: CronJob.getDefaultJobField(0, 6, 1)
                )
            ),
            TestCronJob(
                "t6",
                "*/20 3-5/2 22 * *",
                CronJob(
                    "t6",
                    jobrun,
                    min: CronJob.getDefaultJobField(0, 59, 20),
                    hour: CronJob.getDefaultJobField(3, 5, 2),
                    day: HashSet([22]),
                    month: CronJob.getDefaultJobField(1, 12, 1),
                    dayOfWeek: HashSet()
                )
            ),
            TestCronJob(
                "t7",
                "*/20 3-5/2 22 */5 *",
                CronJob(
                    "t7",
                    jobrun,
                    min: CronJob.getDefaultJobField(0, 59, 20),
                    hour: CronJob.getDefaultJobField(3, 5, 2),
                    day: HashSet([22]),
                    month: CronJob.getDefaultJobField(1, 12, 5),
                    dayOfWeek: HashSet()
                )
            ),
            TestCronJob(
                "t8",
                "*/20 3-5/2 22 */5 4",
                CronJob(
                    "t8",
                    jobrun,
                    min: CronJob.getDefaultJobField(0, 59, 20),
                    hour: CronJob.getDefaultJobField(3, 5, 2),
                    day: HashSet([22]),
                    month: CronJob.getDefaultJobField(1, 12, 5),
                    dayOfWeek: HashSet([4])
                )
            ),
            TestCronJob(
                "t9",
                "0 0 0 * * *",
                CronJob(
                    "t9",
                    jobrun,
                    sec: HashSet([0]),
                    min: HashSet([0]),
                    hour: HashSet([0]),
                    day: CronJob.getDefaultJobField(1, 31, 1),
                    month: CronJob.getDefaultJobField(1, 12, 1),
                    dayOfWeek: CronJob.getDefaultJobField(0, 6, 1)
                )
            ),
            TestCronJob(
                "t10",
                "59 59 23 31 12 6",
                CronJob(
                    "t10",
                    jobrun,
                    sec: HashSet([59]),
                    min: HashSet([59]),
                    hour: HashSet([23]),
                    day: HashSet([31]),
                    month: HashSet([12]),
                    dayOfWeek: HashSet([6])
                )
            ),
            TestCronJob(
                "t11",
                "0-59/10 * * * *",
                CronJob(
                    "t11",
                    jobrun,
                    min: CronJob.getDefaultJobField(0, 59, 10),
                    hour: CronJob.getDefaultJobField(0, 23, 1),
                    day: CronJob.getDefaultJobField(1, 31, 1),
                    month: CronJob.getDefaultJobField(1, 12, 1),
                    dayOfWeek: CronJob.getDefaultJobField(0, 6, 1)
                )
            ),
            TestCronJob(
                "t12",
                "1,3,5 2,4,6 8-10 1-12/3 *",
                CronJob(
                    "t12",
                    jobrun,
                    min: HashSet([1, 3, 5]),
                    hour: HashSet([2, 4, 6]),
                    day: CronJob.getDefaultJobField(8, 10, 1),
                    month: CronJob.getDefaultJobField(1, 12, 3),
                    dayOfWeek: HashSet()
                )
            )
        ]
        for (cs in cases) {
            let job = CronJob.parse(cs.name, cs.schedule, jobrun)
            @Assert(job, cs.expJob)
        }
    }

    /**
     * 测试 Cron 任务的 tick 方法 - 验证任务在正确的时间点应该执行
     */
    @TestCase
    public func testTick() {
        let now = DateTime.now()

        // 测试每秒执行
        let job1 = CronJob.parse("test1", "* * * * * *", jobrun)
        @Assert(job1.tick(CronTick.of(now)), true)

        // 测试每分钟执行（第0秒）
        let job2 = CronJob.parse("test2", "0 * * * *", jobrun)
        eprintln("job2: ${job2}")
        let tick2 = CronTick(
            sec: 0,
            min: 0,
            hour: now.hour,
            day: now.dayOfMonth,
            month: now.month.toInteger(),
            dayOfWeek: now.dayOfWeek.toInteger()
        )
        eprintln("tick2: ${tick2}")
        let result = job2.tick(tick2)
        eprintln("result: ${result}")
        @Assert(result, true)

        // 测试每天执行（0时0分0秒）
        let job3 = CronJob.parse("test3", "0 0 * * *", jobrun)
        let tick3 = CronTick(
            sec: 0,
            min: 0,
            hour: 0,
            day: now.dayOfMonth,
            month: now.month.toInteger(),
            dayOfWeek: now.dayOfWeek.toInteger()
        )
        @Assert(job3.tick(tick3), true)

        // 测试每天执行（0时0分0秒）
        let job4 = CronJob.parse("test4", "0 0 * * *", jobrun)
        let tick4 = CronTick(
            sec: 0,
            min: 0,
            hour: 0,
            day: now.dayOfMonth,
            month: now.month.toInteger(),
            dayOfWeek: now.dayOfWeek.toInteger()
        )
        @Assert(job4.tick(tick4), true)

        // 测试不匹配的时间
        let job5 = CronJob.parse("test5", "30 14 * * *", jobrun) // 每天14:30:00
        let tick5 = CronTick(
            sec: 0,
            min: 0,
            hour: 0,
            day: now.dayOfMonth,
            month: now.month.toInteger(),
            dayOfWeek: now.dayOfWeek.toInteger()
        )
        @Assert(job5.tick(tick5), false)

        // 测试特定秒执行
        let job6 = CronJob.parse("test6", "30 * * * * *", jobrun) // 每30秒执行
        let tick6 = CronTick(
            sec: 30,
            min: now.minute,
            hour: now.hour,
            day: now.dayOfMonth,
            month: now.month.toInteger(),
            dayOfWeek: now.dayOfWeek.toInteger()
        )
        @Assert(job6.tick(tick6), true)

        // 测试特定分执行
        let job7 = CronJob.parse("test7", "15 * * * *", jobrun) // 每小时15分执行
        eprintln("job7: ${job7}")
        let tick7 = CronTick(
            sec: 0,
            min: 15,
            hour: now.hour,
            day: now.dayOfMonth,
            month: now.month.toInteger(),
            dayOfWeek: now.dayOfWeek.toInteger()
        )
        eprintln("tick7: ${tick7}")
        let result7 = job7.tick(tick7)
        eprintln("result7: ${result7}")
        @Assert(result7, true)

        // 测试特定小时执行
        let job8 = CronJob.parse("test8", "0 8 * * *", jobrun) // 每天8点执行
        eprintln("job8: ${job8}")
        let tick8 = CronTick(
            sec: 0,
            min: 0,
            hour: 8,
            day: now.dayOfMonth,
            month: now.month.toInteger(),
            dayOfWeek: now.dayOfWeek.toInteger()
        )
        eprintln("tick8: ${tick8}")
        let result8 = job8.tick(tick8)
        eprintln("result8: ${result8}")
        @Assert(result8, true)

        // 测试特定日期执行
        let job9 = CronJob.parse("test9", "0 0 15 * *", jobrun) // 每月15号执行
        eprintln("job9: ${job9}")
        let tick9 = CronTick(
            sec: 0,
            min: 0,
            hour: 0,
            day: 15,
            month: now.month.toInteger(),
            dayOfWeek: now.dayOfWeek.toInteger()
        )
        eprintln("tick9: ${tick9}")
        let result9 = job9.tick(tick9)
        eprintln("result9: ${result9}")
        @Assert(result9, true)

        // 测试特定月份执行
        let job10 = CronJob.parse("test10", "0 0 * 6 *", jobrun) // 每年6月执行
        eprintln("job10: ${job10}")
        let tick10 = CronTick(
            sec: 0,
            min: 0,
            hour: 0,
            day: now.dayOfMonth,
            month: 6,
            dayOfWeek: now.dayOfWeek.toInteger()
        )
        eprintln("tick10: ${tick10}")
        let result10 = job10.tick(tick10)
        eprintln("result10: ${result10}")
        @Assert(result10, true)

        // 测试特定星期几执行
        let job11 = CronJob.parse("test11", "0 0 * * 5", jobrun) // 每周五执行
        eprintln("job11: ${job11}")
        let tick11 = CronTick(
            sec: 0,
            min: 0,
            hour: 0,
            day: now.dayOfMonth,
            month: now.month.toInteger(),
            dayOfWeek: 5
        )
        eprintln("tick11: ${tick11}")
        let result11 = job11.tick(tick11)
        eprintln("result11: ${result11}")
        @Assert(result11, true)

        // 测试范围匹配
        let job12 = CronJob.parse("test12", "0 0-5 * * *", jobrun) // 每天0-5点执行
        let hours = [0, 1, 2, 3, 4, 5]
        for (hour in hours) {
            let tick12 = CronTick(
                sec: 0,
                min: 0,
                hour: hour,
                day: now.dayOfMonth,
                month: now.month.toInteger(),
                dayOfWeek: now.dayOfWeek.toInteger()
            )
            @Assert(job12.tick(tick12), true)
        }

        // 测试步长匹配
        let job13 = CronJob.parse("test13", "0 0 */2 * *", jobrun) // 每隔1个月执行
        eprintln("job13: ${job13}")
        let months = [1, 3, 5, 7, 9, 11]
        for (month in months) {
            let tick13 = CronTick(
                sec: 0,
                min: 0,
                hour: 0,
                day: 1,
                month: month,
                dayOfWeek: now.dayOfWeek.toInteger()
            )
            @Assert(job13.tick(tick13), true)
        }
    }

    /**
     * 测试 Cron 表达式解析失败的场景 - 验证无效的 Cron 表达式会抛出适当的异常
     */
    @TestCase
    public func testParseError() {
        let cases = [
            TestCronJobErr(
                "incorrect number of schedule parts: less",
                [
                    "* * * * ",
                    "* * * * * * *"
                ],
                "schedule string must have five components like * * * * *"
            ),
            TestCronJobErr(
                "incorrect range",
                [
                    "1-100 * * * * *",
                    "1-200 * * * *",
                    "* 0-30 * * *",
                    "* * 0-10 * *",
                    "* * 1-33 * *",
                    "* * * 0-22 *",
                    "* * * * 0-7",
                    "* * 1-40/2 * *",
                    "60 * * * *"
                ],
                "out of range"
            ),
            TestCronJobErr(
                "unparsable schedule parts",
                [
                    "* * ab/2 * *",
                    "* 1,2/10 * * *",
                    "* * 1,2,3,1-15/10 * *",
                    "a b c d e"
                ],
                "unable to parse"
            )
        ]

        for (cs in cases) {
            for (schedule in cs.schedules) {
                try {
                    CronJob.parse(cs.name, schedule, jobrun)
                    @Fail("should parse error and throw a exception, schedule=${schedule}")
                } catch (ex: ScheduleException) {
                    eprintln(ex.message)
                    @Assert(ex.message.contains(cs.expErrStr))
                }
            }
        }
    }
}
