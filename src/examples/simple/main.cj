/*
 * Copyright (c) lanlingx 2024-present. All rights resvered.
 */

package cjoy.examples.simple

import std.collection.*
import cjoy.*
import cjoy.middleware.*

main(): Int64 {
    var cfg = JoyConfig()
    cfg.enableDebugLog = true
    // 创建joy实例
    let joy = Joy.create(cfg)

    // 注册路由
    let router = joy.router
    router.use(ExceptionHandler())
    router.get(
        "/{name}",
        {
            ctx: JoyContext =>
            let name = ctx.getParam("name").getOrDefault({=> "no name"})
            ctx.string("/{name}, name=${name}")
        }
    )
    router.get(
        "/abc",
        {
            ctx: JoyContext => ctx.string("/abc")
        }
    )

    // group
    let v1 = router.group("/v1")
    v1.get(
        "/{name}",
        {
            ctx: JoyContext =>
            let name = ctx.getParam("name").getOrDefault({=> "no name"})
            ctx.string("/v1/{name}, name=${name}")
        }
    )
    v1.get(
        "/abc",
        {
            ctx: JoyContext => ctx.string("/v1/abc")
        }
    )
    v1.get(
        "/*",
        {
            ctx: JoyContext =>
            let name = ctx.getParam("*").getOrDefault({=> "no name"})
            ctx.string("/v1/*, name=${name}")
        }
    )

    // sub group
    let v1user = v1.group("/user")
    v1user.get(
        "/{name}",
        {
            ctx: JoyContext =>
            let name = ctx.getParam("name").getOrDefault({=> "no name"})
            ctx.string("/v1/user/{name}, name=${name}")
        }
    )
    v1user.get(
        "/abc",
        {
            ctx: JoyContext => ctx.string("/v1/user/abc")
        }
    )

    // baisc_auth
    let auth = router.group("/auth")
    auth.use(BasicAuth("test-realm", HashMap<String, String>([("test", "test")])))
    auth.get(
        "/{name}",
        {
            ctx: JoyContext =>
            let name = ctx.getParam("name").getOrDefault({=> "no name"})
            ctx.string("/auth/{name}, name=${name}")
        }
    )

    // 启动服务
    joy.run("127.0.0.1", 18881)
    return 0
}
