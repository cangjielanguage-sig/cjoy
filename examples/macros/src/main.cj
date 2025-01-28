/*
 * Copyright (c) lanlingx 2025-present. All rights resvered.
 */

package macros

import cjoy.*
import cjoy.macros.*
import cjoy.json.*

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

@Get[path = "/users", provider="json"]
func listUsers(@QueryParam[name=id] id: String): UserInfo {
    let usr = UserInfo()
    usr.id = id
    usr.name = "xiao"
    usr.address = "shenzhen"
    usr
}

main(): Int64 {
    var cfg = JoyConfig()
    cfg.enableDebugLog = true
    // 创建joy实例
    let joy = Joy.create(cfg)
    // 注册生成的handlers
    JoyHandlers.registerTo(joy)
    joy.run("127.0.0.1", 18881)
    return 0
}