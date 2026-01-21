/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 */

package examples.chunked

import cjoy.*

main(): Int64 {
    // 创建joy实例
    let joy = Joy.default()
    // 注册路由
    joy.router.get("/chunked", {
        ctx: JoyContext =>
        // 注意，目前不能切换到其它线程发送响应块
        // 获取分块Writer
        let writer = ctx.chunkedWriter()
        for (num in 1..10) {
            // 分块发送响应
            writer.write(num.toString())
            sleep(Duration.millisecond*200)
        }
        writer.end()
    })
    // 启动服务
    joy.run("127.0.0.1", 18881)
    return 0
}