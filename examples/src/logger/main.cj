/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 */

package examples.logger

import cjoy.*
import cjoy.middleware.AccessLog

main(): Int64 {
    let joy = Joy.default()
    // 使用AccessLog输出访问日志
    joy.router.use(AccessLog(filterFn: {
        ctx: JoyContext =>
        // 忽略/heartbeat
        ctx.path != "/heartbeat"
    }))
    // 注册路由
    joy.router.get("/heartbeat", {
        ctx: JoyContext => ctx.ok()
    })
    joy.router.get("/other_path", {
        ctx: JoyContext => ctx.string("other_path")
    })
    // 启动服务
    joy.run("127.0.0.1", 18881)
    return 0
}
