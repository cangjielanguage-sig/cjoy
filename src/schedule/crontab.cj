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

import std.sync.{Timer}
import std.collection.concurrent.ConcurrentHashMap
import std.time.DateTime
import cjoy.context.ServiceConainter
import cjoy.log.macros.*

public class Crontab <: Resource {
    public static let INSTANCE: Crontab = Crontab()

    private let _jobs: ConcurrentHashMap<String, CronJob>
    private let _timer: Timer
    private var _isClosed = false

    public init() {
        let jobs = ConcurrentHashMap<String, CronJob>()
        _jobs = jobs
        _timer = Timer.repeat(Duration.second, Duration.second, {
            => runScheduled(jobs)
        })
    }

    ~init() {
        _timer.cancel()
    }

    public func destroy(): Unit {
        close()
    }

    public func close(): Unit {
        if (_isClosed) {
            return
        }
        _timer.cancel()
        _isClosed = true
    }

    public func isClosed(): Bool {
        _isClosed
    }

    /**
     * @throws ScheduleException if the name is existed
     */
    public func addJob(name: String, cronExp: String, fn: ScheduleFunc): Unit {
        if (exists(name)) {
            throw ScheduleException("the cron job name is existed")
        }
        let job = CronJob.parse(name, cronExp, fn)
        _jobs.add(name, job)
        @LogInfo("[Schedule] add crontab job, name=${name}")
    }

    public func addJobIfAbsent(name: String, cronExp: String, fn: ScheduleFunc): Unit {
        let job = CronJob.parse(name, cronExp, fn)
        if (_jobs.addIfAbsent(name, job).isNone()) {
            @LogInfo("[Schedule] add crontab job, name=${name}")
        }
    }

    public func exists(name: String): Bool {
        _jobs.contains(name)
    }

    private static func runScheduled(jobs: ConcurrentHashMap<String, CronJob>): Unit {
        let now = DateTime.now()
        let iter = jobs.iterator()
        while (let Some(it) <- iter.next()) {
            let job = it[1]
            if (job.tick(CronTick.of(now))) {
                spawn {
                    job.run(now)
                }
            }
        }
    }
}

private let _: Unit = ServiceConainter.GLOBAL.addService("crontab", Crontab.INSTANCE)
