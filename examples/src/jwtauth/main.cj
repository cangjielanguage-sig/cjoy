/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 */

package examples.jwtauth

import cjoy.*
import cjoy.macros.*
import cjoy.json.*
import cjoy.jwt.*
import cjoy.middleware.{JwtAuth, HmacSigningkey, ExceptionHandler}
import stdx.net.http.{HttpStatusCode}

// 登录请求
@Json
class Login {
    var username: String = ""
    var password: String = ""
}

// 认证之后的用户信息
@Json
class User {
    var username: String = ""
    var firstname: String = ""
    var lastname: String = ""
}

// 在认证
@Get[path = "/auth/ping", produce = "json"]
func ping(): JsonSerializable {
    @ToJson({"ping": "pong"})
}

// 登录认证回调
func authenticator(ctx: JoyContext): Unit {
    // 读取Body
    let login: ?Login = ctx.bindJsonBody()
    if (let Some(l) <- login) {
        // 假定有两个用户admin与test
        if (l.username == "admin" && l.password == "admin" || l.username == "test" && l.password == "test") {
            let u = User(
                username: l.username,
                firstname: "cjoy",
                lastname: "cangjie"
            )
            // 认证通过， 设置上下文
            ctx.setCtxParam("user_info", u)
            return
        }
    }

    // 认证失败
    ctx.status(HttpStatusCode.STATUS_UNAUTHORIZED)
}

// 授权回调
func authorizator(ctx: JoyContext, identity: String): Bool {
    if (ctx.path == "/auth/logout") {
        return true
    }
    // 只有admin授权通过
    return identity == "admin"
}

func setJwtPayload(ctx: JoyContext, jwt: Jwt): Unit {
    let user = ctx.getCtxParam<User>("user_info")
    // 从认证通过User取信息塞到JWT的claims中
    if (let Some(u) <- user) {
        // 需要与identityKey相同
        jwt.claims.claim("identity", u.username)
    }
}

main(): Int64 {
    let joy = Joy.default()
    joy.router.use(ExceptionHandler())

    let jwtAuth = JwtAuth(
        realm: "test jwt",
        signingAlg: "HS256",
        keyProvider: HmacSigningkey("abcd".toArray()),
        authenticator: authenticator,
        authorizator: authorizator,
        setPayload: setJwtPayload,
        maxRefresh: Duration.hour,
        identityKey: "identity",
        sendCookie: true,
        cookieSecure: false,
        cookieHttpOnly: true,
        cookieDomain: ".test.com",
        cookieName: "jwt-cookie",
        sendAuthorization: true
    )

    joy.router.post("/login", jwtAuth.loginHandler)

    let auth = joy.router.group("/auth")
    auth.use(jwtAuth)
    auth.get("/refresh_token", jwtAuth.refreshTokenHandler)
    auth.post("/logout", jwtAuth.logoutHandler)

    // 启动服务
    JoyMiddlewares.registerTo(joy)
    JoyHandlers.registerTo(joy)
    joy.run("127.0.0.1", 18881)
    return 0
}
