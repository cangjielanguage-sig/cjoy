# 服务框架

CJoy 提供轻量级服务容器与依赖注入能力，支持服务的注册、获取和生命周期管理。服务框架为 Handler、Middleware 和自定义组件提供统一的依赖访问方式。

## 概述

CJoy 服务框架基于以下核心概念设计：

- **服务容器**：全局 `ServiceContainer.GLOBAL` 单例管理所有服务实例
- **依赖注入**：通过 `JoyContext` 提供服务获取能力
- **生命周期管理**：支持服务的创建、初始化和销毁
- **线程安全**：使用 `ConcurrentHashMap` 保证并发安全
- **类型泛型**：支持泛型服务获取，编译时类型检查
- **独立容器**：每个 `Joy` 实例拥有独立的服务容器

核心接口定义：
- `Context`：上下文接口，参见 [context.cj](../../src/context/context.cj)
- `ServiceContainer`：服务容器类，参见 [service.cj](../../src/context/service.cj)

---

## 一、Context 接口

`Context` 接口提供上下文参数管理和服务访问能力：

### 1.1 接口定义

```cangjie
public interface Context {
    // 设置上下文参数
    func set(key: String, value: Any): Unit

    // 获取上下文参数
    func get<T>(key: String): ?T

    // 移除上下文参数
    func remove(key: String): Unit

    // 获取服务实例
    func getService<T>(name: String): ?T

    // 获取服务实例（不存在时抛出异常）
    func mustService<T>(name: String): T
}
```

### 1.2 JoyContext 实现

`JoyContext` 是 `Context` 接口的 HTTP 上下文实现：

```cangjie
public open class JoyHttpContext <: JoyContext {
    // httpContext: SDK HTTP 上下文
    // config: JoyConfig 配置
    // params: HashMap<String, String> Path 参数
    // cookies: HashMap<String, String> Cookie 映射
    // method: String HTTP 方法
    // path: String 请求路径
    // url: URL 请求 URL
    // respStatus: UInt16 响应状态码
    // respBody: String 响应体
}
```

---

## 二、ServiceContainer 服务容器

### 2.1 容器方法

```cangjie
public class ServiceContainer {
    // 全局单例
    public static let GLOBAL: ServiceContainer = ServiceContainer()

    // 添加服务
    func addService(name: String, service: Any): Unit

    // 获取服务
    func getService<T>(name: String): ?T
}
```

### 2.2 Joy 实例的服务容器

每个 `Joy` 实例创建独立的服务容器：

```cangjie
public class Joy {
    // Joy 实例的服务容器
    let _services: ServiceContainer
}
```

---

## 三、内置服务

CJoy 内置以下服务，自动注册到全局服务容器：

| 服务名 | 类型 | 说明 |
|---|---|---|
| `config` | `Config` | [配置服务](./config.md) |
| `ioc` | `ApplicationService` | [IoC Bean 容器](./ioc.md) |
| `eventbus` | `EventBus` | [事件总线](./eventbus.md) |
| `crontab` | `Crontab` | [Crontab 任务调度](./schedule.md) |
| `http` | `JoyHttpClient` | [HTTP 客户端服务](./httpx.md) |

### 3.1 Config 配置服务

配置服务接口参见 [conf_api.cj](../../src/config/conf_api.cj)：

```cangjie
// 获取 Config 服务
let config = ctx.getService<Config>("config").getOrThrow()

// 获取配置项
let value = config.getValue("joy.server.address", "127.0.0.1")

// 绑定配置到对象
let serverConfig = config.bind<ServerConfig>("joy.server")
```

### 3.2 ApplicationService IoC 容器

IoC Bean 容器接口，管理所有 `@Component` 定义的 Bean：

```cangjie
@Component
class UserService {
    public func getUser(id: String): UserInfo {
        // ...
    }
}

@Controller[path = "/users"]
class UserHandler {
    @Autowired
    let userService: UserService

    @Get[path = "/{id}"]
    public func get(@PathParam id: String): UserInfo {
        userService.getUser(id)
    }
}
```

### 3.3 EventBus 事件总线

事件总线接口参见 [bus_api.cj](../../src/eventbus/bus_api.cj)：

```cangjie
// 事件定义
public struct UserCreatedEvent {
    public let userId: String
    public let userName: String
}

// 订阅事件
public class EmailNotifier {
    public func init() {
        let eventBus = ServiceContainer.GLOBAL.getService<EventBus>("eventbus").getOrThrow()
        eventBus.onEvent(
            pattern = "user.created",
            name = "emailNotifier",
            subcriber = EmailSubscriber()
        )
    }
}

// 发布事件
public class UserService {
    public func createUser(user: UserInfo): Unit {
        let eventBus = ServiceContainer.GLOBAL.getService<EventBus>("eventbus").getOrThrow()
        eventBus.fireEventAsync(MapContext(), [
            UserCreatedEvent(userId: user.id, userName: user.name)
        ])
    }
}
```

### 3.4 Crontab 任务调度

Crontab 任务调度服务，参见 [schedule/pkg.cj](../../src/schedule/crontab.cj)：

```cangjie
@Component
class MyTask {
    @Scheduled[cron = "0 0 * * *"]
    public func dailyTask(ctx: ScheduleContext): Unit {
        // 每天凌晨执行
        LogTool.info("Daily task executed")
    }

    @Scheduled[cron = "0 */5 * * *"]
    public func everyFiveMinutes(ctx: ScheduleContext): Unit {
        // 每5分钟执行
        LogTool.info("5-minute task executed")
    }
}
```

### 3.5 JoyHttpClient HTTP 客户端

HTTP 客户端服务接口，参见 [httpx_api.cj](../../src/httpx/httpx_api.cj)：

```cangjie
// 获取 HTTP 客户端
let httpClient = ctx.getService<JoyHttpClient>("http").getOrThrow()

// GET 请求
let response = httpClient.get(ctx, "https://api.example.com/data")

// POST 请求（JSON）
let response = httpClient.post(ctx, "https://api.example.com/users", user)

// POST 请求（表单）
let response = httpClient.postform(ctx, "https://api.example.com/login", form)

// 带查询参数
let response = httpClient.get(ctx, "/api/data", queries: HashMap([
    ("page", "1"),
    ("size", "10")
]))

// 带请求头
let headers = HttpHeaders()
headers.add("Authorization", "Bearer token")
let response = httpClient.get(ctx, "/api/data", headers)
```

---

## 四、注册服务

### 4.1 注册自定义服务

使用 `ServiceContainer.GLOBAL.addService()` 注册服务：

```cangjie
import cjoy.context.ServiceContainer

// 自定义服务
class EmailService {
    public func sendEmail(to: String, subject: String, body: String): Unit {
        println("Sending email to ${to}")
    }
}

// 注册服务
main(): Int64 {
    let emailService = EmailService()
    ServiceContainer.GLOBAL.addService("email", emailService)

    // 在 Handler 中使用
    let joy = Joy.default()
    joy.router.get("/send-email", { ctx =>
        let emailService = ctx.getService<EmailService>("email").getOrThrow()
        emailService.sendEmail("user@example.com", "Test", "Hello")
    })
    joy.run("127.0.0.1", 18881)
    return 0
}
```

### 4.2 注册 IoC Bean

使用 `@Component` 宏自动注册 Bean：

```cangjie
import cjoy.ioc.*
import cjoy.macros.*

@Component
class DatabaseService {
    public func query(sql: String): Array<Map<String, Any>> {
        // 查询数据库
        []
    }
}

@Controller[path = "/api"]
class ApiController {
    @Autowired
    let dbService: DatabaseService

    @Get[path = "/users"]
    public func listUsers(): String {
        // 使用注入的服务
        let users = dbService.query("SELECT * FROM users")
        // ...
    }
}
```

---

## 五、在 Handler 中使用服务

### 5.1 直接获取服务

```cangjie
@Get[path = "/config"]
func getConfig(ctx: JoyContext): String {
    // 方式一：通过 JoyContext 获取服务
    let config = ctx.getService<Config>("config").getOrThrow()
    let value = config.getValue("app.name", "unknown")
    value
}

@Post[path = "/user"]
func createUser(ctx: JoyContext): String {
    // 方式二：使用 mustService，不存在时自动抛出异常
    let userService = ctx.mustService<UserService>("userService")
    userService.createUser("user")
}
```

### 5.2 上下文参数传递

```cangjie
// 中间件中设置上下文参数
@Middleware[groups = "/api"]
func authMiddleware(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
    let token = ctx.getHeader("Authorization")
    let userId = verifyToken(token)
    ctx.setCtxParam("userId", userId)
    chain.next(ctx)
}

// Handler 中获取上下文参数
@Get[path = "/api/profile"]
func getProfile(@ContextParam[name = "userId"] userId: String): String {
    "User ID: ${userId}"
}
```

---

## 六、在 Middleware 中使用服务

### 6.1 基本用法

```cangjie
@Component
class CacheMiddleware {
    private let cache: HashMap<String, String> = HashMap()

    public func handle(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
        let cacheKey = ctx.path
        if (let Some(cached) <- cache.get(cacheKey)) {
            ctx.json(cached)
        return
        }

        chain.next(ctx)  // 放行到下一个处理器

        // 缓存响应
        // 注意：实际实现需要更多处理
    }
}

@Middleware
func cacheMiddleware(): JoyMiddlewareHandler {
    CacheMiddleware()
}
```

### 6.2 注册中间件

```cangjie
main(): Int64 {
    let joy = Joy.default()

    // 注册中间件
    joy.router.use(cacheMiddleware())

    // 注册生成的 Handlers
    JoyMiddlewares.registerTo(joy)
    JoyHandlers.registerTo(joy)

    joy.run("127.0.0.1", 18881)
    return 0
}
```

---

## 七、完整示例

```cangjie
import std.collection.*
import std.time.DateTime
import cjoy.*
import cjoy.macros.*
import cjoy.ioc.*
import cjoy.log.macros.*
import cjoy.context.ServiceContainer

// 定义事件
@Json
class UserCreatedEvent {
    var userId: String = ""
    var userName: String = ""
    var timestamp: DateTime = DateTime.now()
}

// 服务一：用户服务
@Component
class UserService {
    private let users: HashMap<String, UserCreatedEvent> = HashMap()

    public func getUser(id: String): ?UserCreatedEvent {
        users.get(id)
    }

    public func createUser(name: String): Unit {
        let event = UserCreatedEvent(userId: generateId(), userName: name)
        users.add(event.userId, event)

        // 发布事件
        let eventBus = ServiceContainer.GLOBAL.getService<EventBus>("eventbus").getOrThrow()
        eventBus.fireEventAsync(MapContext(), [event])
    }
}

// 服务二：邮件通知服务
@Component
class EmailService {
    public func sendUserCreatedEmail(event: UserCreatedEvent): Unit {
        @JoyLogInfo("Sending email for user: ${event.userName}")
    }
}

// 订阅事件
@Component
class EventSubscriber {
    @Autowired
    let emailService: EmailService

    public init() {
        let eventBus = ServiceContainer.GLOBAL.getService<EventBus>("eventbus").getOrThrow()

        // 使用 @SubscribeEvent 宏订阅
        eventBus.onEvent(
            pattern = "user.created",
            name = "emailSubscriber",
            subcriber = this
        )
    }

    @SubscribeEvent
    public func onUserCreated(ctx: Context, evt: UserCreatedEvent): Unit {
        emailService.sendUserCreatedEmail(evt)
    }
}

// 使用服务的 Handler
@Get[path = "/users/{id}", produce = "json"]
func getUser(@PathParam id: String): String {
    let userService = ctx.mustService<UserService>("userService")
    match (userService.getUser(id)) {
        case Some(event) => ctx.json(event)
        case _ => ctx.status(404).string("User not found")
    }
}

@Post[path = "/users", produce = "json"]
func createUser(@BodyParam name: String): String {
    let userService = ctx.mustService<UserService>("userService")
    userService.createUser(name)
    ctx.status(201).json({"message": "User created"})
}

main(): Int64 {
    let joy = Joy.default()

    // 注册生成的 Handlers 和 Middlewares
    JoyMiddlewares.registerTo(joy)
    JoyHandlers.registerTo(joy)

    joy.run("127.0.0.1", 18881)
    return 0
}
```

---

## 八、注意事项

1. **服务查找**：`getService<T>()` 返回 `Option<T>`，服务不存在时返回 `None`，建议使用 `??` 提供默认值

2. **必须服务**：`mustService<T>()` 在服务不存在时抛出异常，适合必需依赖

3. **全局容器**：`ServiceContainer.GLOBAL` 是全局单例，适用于所有 Joy 实例；`Joy._services` 是实例独立容器

4. **Bean 注册**：使用 `@Component` 宏的 Bean 会自动注册到 IoC 容器，无需手动注册

5. **服务覆盖**：后注册的服务会覆盖先注册的同名服务

6. **上下文参数**：`setCtxParam()` / `getCtxParam()` 用于在中间件和 Handler 之间传递数据，生命周期限于单次请求

7. **线程安全**：服务容器使用 `ConcurrentHashMap`，支持并发安全访问

8. **事件总线**：事件发布是异步的，确保事件处理器不阻塞发布线程

9. **HTTP 客户端**：HTTP 客户端服务是每个 Joy 实例独立的，使用前需确保 Joy 实例已创建

10. **生命周期**：Bean 生命周期由 `@Component` 宏和 `BeanFactoryManager` 管理，支持 `afterInit()` 和 `beforeDestroy()` 回调

---
<< [返回](../../README.md#使用指导)
