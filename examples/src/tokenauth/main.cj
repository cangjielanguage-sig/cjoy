/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 */

package examples.tokenauth

import cjoy.*
import cjoy.macros.*
import cjoy.middleware.{TokenAuth, ExceptionHandler}

@Get[path = "/token_auth/query"]
func auth1(ctx: JoyContext): String {
    "ok-query"
}

@Get[path = "/token_auth/param/{token}"]
func auth2(ctx: JoyContext, @PathParam token: String): String {
    "ok-param"
}

@Post[path = "/token_auth/form"]
func auth3(ctx: JoyContext, @PostFormParam token: String): String {
    "ok-form"
}

@Get[path = "/token_auth/header"]
func auth4(ctx: JoyContext, @HeaderParam[name = "Authorization"] token: String): String {
    "ok-header"
}

@Get[path = "/token_auth/cookie"]
func auth5(ctx: JoyContext, @CookieParam token: String): String {
    "ok-cookie"
}

main(): Int64 {
    let joy = Joy.default()
    joy.router.use(ExceptionHandler())
    joy.router.group("/token_auth/header").use(TokenAuth("abc"))
    joy.router.group("/token_auth/query").use(TokenAuth("abc", lookupKey: "query:token"))
    joy.router.group("/token_auth/param").use(TokenAuth("abc", lookupKey: "param:token"))
    joy.router.group("/token_auth/form").use(TokenAuth("abc", lookupKey: "form:token"))
    joy.router.group("/token_auth/cookie").use(TokenAuth("abc", lookupKey: "cookie:token"))
    // 启动服务
    JoyMiddlewares.registerTo(joy)
    JoyHandlers.registerTo(joy)
    joy.run("127.0.0.1", 18881)
    return 0
}
