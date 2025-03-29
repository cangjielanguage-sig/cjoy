/*
 * Copyright (c) lanlingx 2025-present. All rights resvered.
 */

package cjoy.examples.macros

import cjoy.*
import cjoy.macros.*
import cjoy.json.*
import cjoy.middleware.*

@Json
class UserInfo {
    var id: String = ""
    var name: String = ""
    var address: String = ""
    var gender: Int = 0
}

@Get[path = "/abc"]
func getStaticPath(): String {
    "/abc"
}

@Get[path = "/users/{name}"]
func getUserName(@PathParam name: String): (UInt16, String) {
    (200, "/users/${name}")
}

@Get[path = "/users", produce = "json"]
func listUsers(@QueryParam[name = id, default = xiao] id: String): UserInfo {
    let usr = UserInfo()
    usr.id = id
    usr.name = "xiao"
    usr.address = "shenzhen"
    usr
}

@Middleware[groups = "/users"]
func testMiddleware(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
    println("intercept /users")
    chain.next(ctx)
}

main(): Int64 {
    var cfg = JoyConfig()
    cfg.enableDebugLog = true
    // 创建joy实例
    let joy = Joy.create(cfg)
    // 注册生成的handlers
    joy.router.use(ExceptionHandler())
    JoyMiddlewares.registerTo(joy)
    JoyHandlers.registerTo(joy)
    joy.run("127.0.0.1", 18881)
    return 0
}
