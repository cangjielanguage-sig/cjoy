/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.schedule

import std.collection.HashSet

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
            )
        ]
        for (cs in cases) {
            let job = CronJob.parse(cs.name, cs.schedule, jobrun)
            @Assert(job, cs.expJob)
        }
    }

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
