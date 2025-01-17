package rest

import std.collection.*
import std.io.ByteBuffer
import encoding.json.stream.*
import cjoy.*
import cjoy.json.*
import cjoy.json.generate.*
import net.http.HttpStatusCode

@Json
class UserInfo {
    var name: String = ""
    var address: String = ""
    var gender: Int = 0
}

class UserHandler {
    let users: HashMap<String, UserInfo> = HashMap()

    public func create(ctx: JoyContext): Unit {
        let user = ctx.readJsonBody<UserInfo>()
        if (let Some(u) <- user) {
            users.put(u.name, u)
            ctx.logger.info("save user info, name=${u.name}")
            ctx.succes(HttpStatusCode.STATUS_CREATED)
        } else {
            ctx.error(HttpStatusCode.STATUS_BAD_REQUEST)
        }
    }

    public func query(ctx: JoyContext): Unit {
        let name = ctx.getParam("name")
        match (name) {
            case Some(n) =>
                let user = users.get(n)
                match (user) {
                    case Some(u) => ctx.json(u)
                    case _ => ctx.error(HttpStatusCode.STATUS_NOT_FOUND)
                }
            case _ => ctx.error(HttpStatusCode.STATUS_NOT_FOUND)
        }
    }

    public func delete(ctx: JoyContext): Unit {
        let name = ctx.getParam("name")
        match (name) {
            case Some(n) => users.remove(n)
            case _ => ()
        }
        ctx.succes(HttpStatusCode.STATUS_NO_CONTENT)
    }

    public func update(ctx: JoyContext): Unit {
        let name = ctx.getParam("name").getOrThrow()
        let user = ctx.readJsonBody<UserInfo>().getOrThrow()
        if (user.name == name) {
            match (users.get(name)) {
                case Some(u) =>
                    users.put(name, user)
                    ctx.ok()
                case _ => ctx.error(HttpStatusCode.STATUS_NOT_FOUND)
            }
        } else {
            ctx.error(HttpStatusCode.STATUS_BAD_REQUEST)
        }
    }
}

main(): Int64 {
    var cfg = JoyConfig()
    cfg.enableDebugLog = true
    // 创建joy实例
    let joy = Joy.create(cfg)

    let userHandler = UserHandler()
    joy.router.POST("/users", userHandler.create)
    joy.router.GET("/users/{name}", userHandler.query)
    joy.router.DELETE("/users/{name}", userHandler.delete)
    joy.router.PUT("/users/{name}", userHandler.update)

    // 启动服务
    joy.run("127.0.0.1", 18881)
    return 0
}
