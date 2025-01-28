/*
 * Copyright (c) lanlingx 2025-present. All rights resvered.
 */

package chuncked

import cjoy.*

main(): Int64 {
    var cfg = JoyConfig()
    cfg.enableDebugLog = true
    // 创建joy实例
    let joy = Joy.create(cfg)
    // 注册路由
    joy.router.get("/chuncked", {
        ctx: JoyContext =>
        let sender = ctx.chunked()
        for (num in 1..10) {
            sender.write(num.toString())
            sleep(Duration.millisecond*200)
        }
        sender.end()
    })
    // 启动服务
    joy.run("127.0.0.1", 18881)
    return 0
}