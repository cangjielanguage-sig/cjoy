/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 */

package examples.sse

import cjoy.*
import std.sync.SyncCounter

main(): Int64 {
    var cfg = JoyConfig()
    cfg.enableDebugLog = true
    // 创建joy实例
    let joy = Joy.create(cfg)
    // 注册路由
    joy.router.get("/sse", {
        ctx: JoyContext =>
        let emitter = ctx.eventEmitter()
        let counter = SyncCounter(1)
        spawn {
            for (num in 1..10) {
                emitter.sendEvent(JoyServerEventBuilder().data("{\"num\":\"${num}\"}"))
                sleep(Duration.millisecond*200)
            }
            counter.dec()
        }
        counter.waitUntilZero()
        emitter.end()
    })
    // 启动服务
    joy.run("127.0.0.1", 18881)
    return 0
}