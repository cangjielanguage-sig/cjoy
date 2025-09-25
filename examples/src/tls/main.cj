/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 */

package examples.tls

import cjoy.*
import stdx.net.http.*

main(): Int64 {
    // 创建joy实例
    let joy = Joy.default()

    // 注册路由
    let router = joy.router
    router.get(
        "/{name}",
        {
            ctx: JoyContext =>
            let name = ctx.getParam("name") ?? "no name"
            ctx.string("name in paramter path, name=${name}")
        }
    )
    router.get(
        "/abc",
        {
            ctx: JoyContext => ctx.string("static path abc")
        }
    )

    // 启动服务
    let certificatePath = "../testdata/server_cert.pem"
    let certificateKeyPath = "../testdata/server_key.pem"
    joy.run("127.0.0.1", 18881, certificatePath, certificateKeyPath)
    return 0
}
