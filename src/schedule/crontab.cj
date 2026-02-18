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

import std.sync.{Timer}
import std.collection.{ArrayList}
import std.collection.concurrent.ConcurrentHashMap
import std.time.DateTime
import cjoy.context.ServiceContainer
import cjoy.log.macros.*

/**
 * 管理多个 Cron 任务的定时任务表
 */
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
     * 添加 Cron 任务到定时任务表
     *
     * @param name 任务名称
     * @param cronExp Cron 表达式
     * @param fn 任务执行函数
     * @throws ScheduleException 如果名称已存在
     */
    public func addJob(name: String, cronExp: String, fn: ScheduleFunc): Unit {
        if (exists(name)) {
            throw ScheduleException("the cron job name is existed")
        }
        let job = CronJob.parse(name, cronExp, fn)
        _jobs.add(name, job)
        @JoyLogInfo("[Schedule] add crontab job, name=${name}")
    }

    /**
     * 如果不存在则添加 Cron 任务到定时任务表
     *
     * @param name 任务名称
     * @param cronExp Cron 表达式
     * @param fn 任务执行函数
     */
    public func addJobIfAbsent(name: String, cronExp: String, fn: ScheduleFunc): Unit {
        let job = CronJob.parse(name, cronExp, fn)
        if (_jobs.addIfAbsent(name, job).isNone()) {
            @JoyLogInfo("[Schedule] add crontab job, name=${name}")
        }
    }

    /**
     * 检查任务是否存在
     *
     * @param name 任务名称
     * @return 如果任务存在返回 true
     */
    public func exists(name: String): Bool {
        _jobs.contains(name)
    }

    /**
     * 从定时任务表移除 Cron 任务
     *
     * @param name 任务名称
     * @return 如果任务被移除返回 true，未找到返回 false
     */
    public func removeJob(name: String): Bool {
        _jobs.remove(name).isSome()
    }

    /**
     * 获取定时任务表中所有任务名称
     *
     * @return 任务名称数组
     */
    public func getJobNames(): Array<String> {
        let names = ArrayList<String>()
        let iter = _jobs.iterator()
        while (let Some(it) <- iter.next()) {
            names.add(it[0])
        }
        names.toArray()
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

private let _: Unit = ServiceContainer.GLOBAL.addService("crontab", Crontab.INSTANCE)
