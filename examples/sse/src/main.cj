/*
 * Copyright (c) lanlingx 2025-present. All rights resvered.
 */

package sse

import cjoy.*

main(): Int64 {
    var cfg = JoyConfig()
    cfg.enableDebugLog = true
    // 创建joy实例
    let joy = Joy.create(cfg)
    // 注册路由
    joy.router.get("/sse", {
        ctx: JoyContext =>
        let emitter = ctx.eventEmitter()
        for (num in 1..10) {
            emitter.sendEvent(JoyServerEventBuilder().data("{\"num\":\"${num}\"}"))
            sleep(Duration.millisecond*200)
        }
        emitter.end()
    })
    // 启动服务
    joy.run("127.0.0.1", 18881)
    return 0
}