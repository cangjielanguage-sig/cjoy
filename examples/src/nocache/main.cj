/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 */

package examples.nocache

import cjoy.*
import cjoy.macros.*
import cjoy.middleware.{NoCache, ExceptionHandler}

@Get[path = "/nocache"]
func nocache(ctx: JoyContext): String {
    "no cache"
}

main(): Int64 {
    let joy = Joy.default()
    joy.router.use(ExceptionHandler()).use(NoCache())
    // 启动服务
    JoyMiddlewares.registerTo(joy)
    JoyHandlers.registerTo(joy)
    joy.run("127.0.0.1", 18881)
    return 0
}
