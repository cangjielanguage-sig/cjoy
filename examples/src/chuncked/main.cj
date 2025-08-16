/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 */

package examples.chuncked

import cjoy.*

main(): Int64 {
    var cfg = JoyConfig()
    cfg.enableDebugLog = true
    // 创建joy实例
    let joy = Joy.create(cfg)
    // 注册路由
    joy.router.get("/chuncked", {
        ctx: JoyContext =>
        let writer = ctx.chunkedWriter()
        for (num in 1..10) {
            writer.write(num.toString())
            sleep(Duration.millisecond*200)
        }
        writer.end()
    })
    // 启动服务
    joy.run("127.0.0.1", 18881)
    return 0
}