# Session

---

## 概述

HTTP是无状态协议，Session是Web服务端存储特定用户会话所需的属性及配置信息。当用户在应用程序的Web页之间跳转时，存储在Session对象中的变量将不会丢失，而是在整个用户会话中一直存在下去。

当用户首次请求时，如果该用户还没有会话，则Web服务器将自动创建一个Session对象，并在头域中Set-Cookie指定Session ID，用于关联会话内的多次请求。

当会话过期或被放弃后，服务器将终止该会话。

### 内置存储实现

CJoy内置了两个简易Session存储实现：

| 存储实现 | 说明 |
|----------|------|
| `MemorySessionStorage` | Session存储在内存中，适合开发和测试环境 |
| `FileSessionStorage` | Session存储在指定目录下，适合小型应用 |

核心接口：
- `JoySession`：Session接口，参见 [session.cj](../../src/session/session.cj)
- `JoySessionStorage`：Session存储接口，参见 [session_storage.cj](../../src/session/session_storage.cj)

使用示例：[examples/session](../../examples/src/session/main.cj)。

---

## 一、注册SessionManager中间件

### 1.1 全局注册

给所有路径注册SessionManager，采用MemorySessionStorage：

```cangjie
import cjoy.middleware.SessionManager
import cjoy.middleware.JoySessionConfig
import cjoy.session.MemorySessionStorage

main(): Int64 {
    let joy = Joy.default()

    // 使用默认配置
    let memorySessionManager = SessionManager(MemorySessionStorage())
    joy.router.use(memorySessionManager)

    joy.run("127.0.0.1", 8080)
    return 0
}
```

### 1.2 路由组注册

给某个Group注册SessionManager，采用FileSessionStorage：

```cangjie
import cjoy.middleware.SessionManager
import cjoy.middleware.JoySessionConfig
import cjoy.session.FileSessionStorage

main(): Int64 {
    let joy = Joy.default()

    let group = joy.router.group("/file")
    let fileSessionManager = SessionManager(
        FileSessionStorage("./sessions"),
        config: JoySessionConfig(
            cookiePath: "/file"
        )
    )
    group.use(fileSessionManager)

    joy.run("127.0.0.1", 8080)
    return 0
}
```

### 1.3 JoySessionConfig

在注册SessionManager时，可以通过 `JoySessionConfig` 配置Session相关选项：

```cangjie
let config = JoySessionConfig(
    cookieName: "sid",
    cookiePath: "/",
    cookieSecure: false,
    cookieHttpOnly: true,
    cookieMaxAge: 3600,
    cookieDomain: "",
    idLength: 32
)
let sessionManager = SessionManager(MemorySessionStorage(), config: config)
```

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| cookieName | String | "sid" | 会话Cookie名称 |
| cookiePath | String | "/" | 会话Cookie的Path |
| cookieSecure | Bool | false | 是否只在HTTPS下使用 |
| cookieHttpOnly | Bool | true | HttpOnly属性，使JavaScript脚本无法获得Cookie，防止XSS攻击 |
| cookieMaxAge | Int | 3600 | 会话Cookie存活时长（秒） |
| cookieDomain | String | "" | 会话Cookie的域名 |
| idLength | Int | 32 | Session ID长度 |

---

## 二、使用Session

### 2.1 获取Session对象

使用 `getSession` 函数从上下文获取Session对象：

```cangjie
import cjoy.middleware.getSession

@Get[path = "/data"]
func handleData(ctx: JoyContext): Unit {
    let session = getSession(ctx).getOrThrow()
    // 使用session...
}
```

### 2.2 Session操作

#### set - 存储数据

在Session上存储信息：

```cangjie
let session = getSession(ctx).getOrThrow()

// 存储字符串
session.set("username", "john")

// 存储数字
session.set("count", 42)

// 存储自定义对象（需实现JsonSerializable和JsonDeserializable）
session.set("user", User(name: "John", age: 25))
```

#### get - 获取数据

在Session上获取信息：

```cangjie
let session = getSession(ctx).getOrThrow()

// 获取字符串
if (let Some(username) <- session.get<String>("username")) {
    @JoyLogInfo("Username: ${username}")
}

// 获取数字
if (let Some(count) <- session.get<Int>("count")) {
    @JoyLogInfo("Count: ${count}")
}

// 获取自定义对象
if (let Some(user) <- session.get<User>("user")) {
    @JoyLogInfo("User: ${user.name}")
}
```

#### remove - 删除数据

在Session上删除信息并返回被删除的值：

```cangjie
let session = getSession(ctx).getOrThrow()

// 删除并获取值
if (let Some(value) <- session.remove<String>("username")) {
    @JoyLogInfo("Removed: ${value}")
}
```

#### invalidate - 使Session失效

让Session失效，清除Cookie：

```cangjie
let session = getSession(ctx).getOrThrow()
session.invalidate()
// Session失效后，Cookie会在下次响应时被删除
```

#### id - 获取Session ID

获取当前Session的唯一标识：

```cangjie
let session = getSession(ctx).getOrThrow()
@JoyLogInfo("Session ID: ${session.id}")
```

#### isInvalidated - 检查Session状态

检查Session是否已失效：

```cangjie
let session = getSession(ctx).getOrThrow()
if (session.isInvalidated) {
    @JoyLogWarn("Session已失效")
}
```

---

## 三、完整示例

```cangjie
import cjoy.Joy
import cjoy.middleware.SessionManager
import cjoy.middleware.JoySessionConfig
import cjoy.middleware.getSession
import cjoy.session.MemorySessionStorage
import cjoy.json.macros.*

main(): Int64 {
    let joy = Joy.default()

    // 注册Session中间件
    let sessionManager = SessionManager(
        MemorySessionStorage(),
        config: JoySessionConfig(
            cookieName: "mysession",
            cookieMaxAge: 1800  // 30分钟
        )
    )
    joy.router.use(sessionManager)

    // 设置Session数据
    joy.router.post("/login", {ctx: JoyContext =>
        let session = getSession(ctx).getOrThrow()
        session.set("username", "john")
        session.set("loginTime", DateTime.now())
        ctx.string("登录成功")
    })

    // 获取Session数据
    joy.router.get("/profile", {ctx: JoyContext =>
        let session = getSession(ctx).getOrThrow()
        if (let Some(username) <- session.get<String>("username")) {
            ctx.json(@ToJson({
                "username": username,
                "sessionId": session.id
            }))
        } else {
            ctx.status(401).string("未登录")
        }
    })

    // 登出
    joy.router.post("/logout", {ctx: JoyContext =>
        let session = getSession(ctx).getOrThrow()
        session.invalidate()
        ctx.string("登出成功")
    })

    joy.run("127.0.0.1", 8080)
    return 0
}
```

---

## 四、扩展

开发者可以自己扩展Session存储（如Redis、数据库），只需要实现以下两个接口：

### 4.1 JoySession接口

```cangjie
public interface JoySession {
    // Session ID
    prop id: String

    // Session是否已失效
    prop isInvalidated: Bool

    // 存储值
    func set<T>(key: String, value: T): Unit where T <: JsonSerializable & JsonDeserializable<T>

    // 获取值
    func get<T>(key: String): ?T where T <: JsonSerializable & JsonDeserializable<T>

    // 删除并返回值
    func remove<T>(key: String): ?T where T <: JsonSerializable & JsonDeserializable<T>

    // 持久化到存储
    func flush(): Unit

    // 删除Session
    func invalidate(): Unit
}
```

### 4.2 JoySessionStorage接口

```cangjie
public interface JoySessionStorage {
    // Session数量
    prop size: Int

    // 删除Session
    func delete(sid: String): Unit

    // 获取或创建Session
    func getOrCreate(sid: String, idLen: Int32): JoySession

    // 检查Session是否存在
    func exists(sid: String): Bool

    // 清理过期Session
    func clean(): Unit
}
```

### 4.3 扩展示例：Redis存储

```cangjie
import cjoy.session.{JoySession, JoySessionStorage}

class RedisSession <: AbstractSession {
    private let _redis: RedisClient

    public init(sid: String, redis: RedisClient) {
        super(sid)
        _redis = redis
    }

    public override func flush(): Unit {
        // 将session数据持久化到Redis
        _redis.set("session:${id}", serializeSession())
    }
}

class RedisSessionStorage <: AbstractSessionStorage {
    private let _redis: RedisClient

    public init(redis: RedisClient, maxLifetime: Duration) {
        super(maxLifetime)
        _redis = redis
    }

    protected override func createSession(sid: String): AbstractSession {
        RedisSession(sid, _redis)
    }

    protected override func loadSession(sid: String): ?AbstractSession {
        // 从Redis加载session
        if (let Some(data) <- _redis.get("session:${sid}")) {
            return deserializeSession(data)
        }
        None
    }

    public override func delete(sid: String): Unit {
        super.delete(sid)
        _redis.delete("session:${sid}")
    }
}
```

---

## 五、注意事项

1. **Session清理**：SessionManager会启动后台任务，每5秒清理一次过期的Session

2. **线程安全**：Session操作是线程安全的，可以在并发环境中安全使用

3. **类型约束**：Session存储的值必须实现 `JsonSerializable` 和 `JsonDeserializable` 接口

4. **内存限制**：MemorySessionStorage会占用应用内存，大量用户时应使用Redis或数据库存储

5. **分布式环境**：多实例部署时，需要使用共享存储（如Redis）而非MemorySessionStorage

6. **Cookie配置**：生产环境建议设置 `cookieSecure: true`，仅通过HTTPS传输

---
<< [返回](../../README.md#使用指导)
