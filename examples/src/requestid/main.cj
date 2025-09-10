/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 */

package examples.requestid

import cjoy.*
import cjoy.macros.*
import cjoy.middleware.{RequestId, getRequestId, ExceptionHandler}

@Get[path = "/request_id"]
func reqId(ctx: JoyContext): String {
    getRequestId(ctx).getOrThrow()
}

main(): Int64 {
    let joy = Joy.default()
    joy.router.use(ExceptionHandler()).use(RequestId())
    // 启动服务
    JoyMiddlewares.registerTo(joy)
    JoyHandlers.registerTo(joy)
    joy.run("127.0.0.1", 18881)
    return 0
}
