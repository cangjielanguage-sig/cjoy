/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 */

package examples.macros

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

// GET /abc
@Get[path = "/abc"]
func getStaticPath(): String {
    "/abc"
}

// GET /users/xiao
@Get[path = "/users/{name}"]
func getUserName(@PathParam name: String): (UInt16, String) {
    (200, "/users/${name}")
}

// GET /users?id=00009527
@Get[path = "/users", produce = "json"]
func listUsers(@QueryParam[name = id, default = "00009527"] id: String): UserInfo {
    let usr = UserInfo()
    usr.id = id
    usr.name = "xiao"
    usr.address = "shenzhen"
    usr
}

// 注册中间件到Group /users上，可以拦截所有/users请求
@Middleware[groups = "/users"]
func testMiddleware(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
    println("intercept /users")
    chain.next(ctx)
}

main(): Int64 {
    // 创建joy实例
    let joy = Joy.default()
    // 注册生成的handlers
    joy.router.use(ExceptionHandler())
    JoyMiddlewares.registerTo(joy)
    JoyHandlers.registerTo(joy)
    joy.run("127.0.0.1", 18881)
    return 0
}
