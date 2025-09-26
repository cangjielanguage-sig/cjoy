/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 */

package examples.schedule

import cjoy.*
import cjoy.macros.*
import cjoy.schedule.*
import cjoy.middleware.ExceptionHandler
import cjoy.log.*

// 使用方式1： 采用宏标注函数，函数只有一个参数ScheduleContext
@Scheduled[name = "metric job", cron = "*/2 * * * * *"]
func logMetric(ctx: ScheduleContext): Unit {
    @LogInfo("log metric in crontab ...")
}

@Post[path = "/crontab"]
func addCrontab(ctx: JoyContext): Unit {
    let crontab = ctx.getService<Crontab>("crontab").getOrThrow()
    crontab.addJobIfAbsent("the name", "*/5 * * * * *",
        {
            schedCtx: ScheduleContext => @LogInfo("another crontab ...")
        })
}

main(): Int64 {
    let joy = Joy.default()
    joy.router.use(ExceptionHandler())

    // 注册Crontab服务，可以在Post, Get等Handler方法中使用
    joy.addService("crontab", Crontab())

    // 注册所有生成的handlers
    JoyMiddlewares.registerTo(joy)
    JoyHandlers.registerTo(joy)
    joy.run("127.0.0.1", 18881)
    return 0
}
