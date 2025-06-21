/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 */

package cjoy.examples.rest

import std.collection.*
import stdx.net.http.HttpStatusCode
import cjoy.*
import cjoy.json.*
import cjoy.log.LogTool

@Json
class UserInfo {
    var name: String = ""
    var address: String = ""
    var gender: Int = 0
}

class UserHandler {
    let users: HashMap<String, UserInfo> = HashMap()

    public func create(ctx: JoyContext): Unit {
        let user = ctx.bindJsonBody<UserInfo>()
        if (let Some(u) <- user) {
            users.add(u.name, u)
            LogTool.info("save user info, name=${u.name}")
            ctx.status(HttpStatusCode.STATUS_CREATED)
        } else {
            ctx.status(HttpStatusCode.STATUS_BAD_REQUEST)
        }
    }

    public func query(ctx: JoyContext): Unit {
        let name = ctx.getParam("name").getOrThrow()
        let user = users.get(name)
        match (user) {
            case Some(u) => ctx.json(u)
            case _ => ctx.status(HttpStatusCode.STATUS_NOT_FOUND)
        }
    }

    public func delete(ctx: JoyContext): Unit {
        let name = ctx.getParam("name").getOrThrow()
        users.remove(name)
        ctx.status(HttpStatusCode.STATUS_NO_CONTENT)
    }

    public func update(ctx: JoyContext): Unit {
        let name = ctx.getParam("name").getOrThrow()
        let user = ctx.readJson<UserInfo>().getOrThrow()
        if (user.name == name) {
            match (users.get(name)) {
                case Some(u) =>
                    users.add(name, user)
                    ctx.ok()
                case _ => ctx.status(HttpStatusCode.STATUS_NOT_FOUND)
            }
        } else {
            ctx.status(HttpStatusCode.STATUS_BAD_REQUEST)
        }
    }
}

main(): Int64 {
    var cfg = JoyConfig()
    cfg.enableDebugLog = true
    let joy = Joy.create(cfg)

    let userHandler = UserHandler()
    joy.router.post("/users", userHandler.create)
    joy.router.get("/users/{name}", userHandler.query)
    joy.router.delete("/users/{name}", userHandler.delete)
    joy.router.put("/users/{name}", userHandler.update)

    joy.run("127.0.0.1", 18881)
    return 0
}
