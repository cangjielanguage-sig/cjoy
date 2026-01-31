/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 */

package examples.restioc

import std.collection.*
import stdx.net.http.HttpStatusCode
import cjoy.*
import cjoy.json.*
import cjoy.ioc.*
import cjoy.macros.*

@JoyCreateLogger("examples.restioc")

@Json
class UserInfo {
    var name: String = ""
    var address: String = ""
    var gender: Int = 0
}

@Controller[path = "/users"]
class UserHandler {
    let users: HashMap<String, UserInfo> = HashMap()

    @Post[path = "/"]
    public func create(ctx: JoyContext, @BodyParam user: ?UserInfo): Unit {
        if (let Some(u) <- user) {
            users.add(u.name, u)
            @JoyLogInfo("save user info, name=${u.name}")
            ctx.status(HttpStatusCode.STATUS_CREATED)
        } else {
            ctx.status(HttpStatusCode.STATUS_BAD_REQUEST)
        }
    }

    @Get[path = "/{name}"]
    public func query(ctx: JoyContext, @PathParam name: String): Unit {
        let user = users.get(name)
        match (user) {
            case Some(u) => ctx.json(u)
            case _ => ctx.status(HttpStatusCode.STATUS_NOT_FOUND)
        }
    }

    @Get[path = "/"]
    public func list(ctx: JoyContext): Unit {
        ctx.json(users.values().toArray())
    }

    @Delete[path = "/{name}"]
    public func delete(ctx: JoyContext, @PathParam name: String): Unit {
        users.remove(name)
        ctx.status(HttpStatusCode.STATUS_NO_CONTENT)
    }

    @Put[path = "/{name}"]
    public func update(ctx: JoyContext, @PathParam name: String, @BodyParam user: UserInfo): Unit {
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
    let joy = Joy.default()
    // 需要调用JoyHandlers.registerTo，让生成Handler自动注册
    JoyHandlers.registerTo(joy)
    joy.run("127.0.0.1", 18881)
    return 0
}
