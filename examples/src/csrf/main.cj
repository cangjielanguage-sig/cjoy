/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 */

package examples.csrf

import cjoy.*
import cjoy.macros.*
import cjoy.session.*
import cjoy.middleware.{getCsrfToken, CsrfProtect, SessionManager}

// 1. 先在Get 请求某个url，生成CRSF token
@Get[path = "/get_token"]
func get1(ctx: JoyContext): String {
    getCsrfToken(ctx)
}

// 2.0 提交数据时，携带CRSF token，可以放在表单，Header等
@Post[path = "/submit_form"]
func post1(ctx: JoyContext): String {
    "token is valid"
}

main(): Int64 {
    let joy = Joy.default()
    // 设置Session管理
    let sessionManager = SessionManager(MemorySessionStorage())
    joy.router.use(sessionManager)
    // CSRF依赖Session，需要先设置sessionManager
    joy.router.use(CsrfProtect("abcdef"))

    // 启动服务
    JoyMiddlewares.registerTo(joy)
    JoyHandlers.registerTo(joy)
    joy.run("127.0.0.1", 18881)

    // 清理
    sessionManager.destroy()
    return 0
}
