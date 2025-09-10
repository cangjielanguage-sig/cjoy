/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 */

package examples.session

import std.collection.*
import cjoy.*
import cjoy.macros.*
import cjoy.json.*
import cjoy.middleware.session.*

@Json
class UserInfo {
    var id: String = ""
    var name: String = ""
    var address: String = ""
    var gender: Int = 0
}

@Get[path = "/session"]
func getSession1(ctx: JoyContext): String {
    // 获取当前Session
    let session = getSession(ctx).getOrThrow()
    let user = UserInfo()
    user.id = "0009527"
    user.name = "xiao"
    user.address = "shenzhen"
    // 在Session上存储信息
    session.set("user", user)
    "set user info in session"
}

@Get[path = "/file/session"]
func getSession2(ctx: JoyContext): String {
    getSession1(ctx)
}

@Get[path = "/user_info", produce = "json"]
func getUesrInfo1(ctx: JoyContext): JsonSerializable {
    let session = getSession(ctx).getOrThrow()
    // 在Session上获取其它请求存储的信息
    let user = session.get<UserInfo>("user")
    if (let Some(u) <- user) {
        return u
    }
    return @ToJson({"errMsg":"not found user in session"})
}

@Get[path = "/file/user_info", produce = "json"]
func getUesrInfo2(ctx: JoyContext): JsonSerializable {
    getUesrInfo1(ctx)
}

main(): Int64 {
    let joy = Joy.default()
    // 设置Session管理
    let memorySessionManager = SessionManager(MemorySessionStorage())
    joy.router.use(memorySessionManager)

    // 在指定的Group上设置Session管理
    let group = joy.router.group("/file")
    let fileSessionManager = SessionManager(FileSessionStorage("./sessions"), config: JoySessionConfig(cookiePath: "/file"))
    // 注意：此时/file会有两个Session管理，此处只用于演示
    group.use(fileSessionManager)

    // 启动服务
    JoyMiddlewares.registerTo(joy)
    JoyHandlers.registerTo(joy)
    joy.run("127.0.0.1", 18881)

    // 清理
    memorySessionManager.destroy()
    fileSessionManager.destroy()
    return 0
}
