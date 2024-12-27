/*
* Copyright (c) lanlingx 2024-2024. All rights resvered.
*/

package simple

import cjoy.*

main(): Int64 {
    var cfg = JoyConfig()
    cfg.enableDebugLog=true
    // 创建joy实例
    let joy = Joy.create(cfg)

    // 注册路由
    joy.router.GET("/:name", {ctx: JoyContext => 
        let name = ctx.getParam("name").getOrDefault({=>"no name"})
        ctx.string("name in wildcard path, name=${name}")
    })
    joy.router.GET("/abc", {ctx: JoyContext => 
        ctx.string("static path abc")
    })
    joy.router.GET("/1234", {ctx: JoyContext => 
        ctx.string("static path 1234")
    })
   

    // 启动服务
    joy.run("127.0.0.1", 18881)
    return 0
}