# Middleware

CJoy 提供 HTTP 请求拦截处理机制，类似于 Java 的 Servlet Filter。Middleware 可以在请求到达 Handler 之前或之后执行自定义逻辑，实现日志、认证、授权、CORS、CSRF 防护等功能。

## 概述

CJoy Middleware 系统基于以下核心概念设计：

- **请求链模式**：通过 `JoyRequestHandlerChain` 管理中间件链式调用，支持提前终止或短路请求
- **多种注册方式**：支持全局注册、路由分组注册、单次路由注册
- **中间件继承**：子分组自动继承父分组的中间件栈
- **宏注解支持**：可通过 `@Middleware` 宏自动将中间件注册到指定分组

核心接口定义：
- `JoyMiddlewareHandler`：中间件接口，参见 [pkg.cj](../../src/middleware/pkg.cj)
- `JoyRequestHandlerChain`：中间件链接口，参见 [route.cj](../../src/framework/route.cj)

---

## 一、中间件接口

### 1.1 JoyMiddlewareHandler

所有中间件必须实现 `JoyMiddlewareHandler` 接口：

```cangjie
public interface JoyMiddlewareHandler {
    /**
     * 处理 HTTP 请求
     *
     * @param ctx: 请求上下文
     * @param chain: 中间件链
     */
    func handle(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit
}
```

### 1.2 JoyRequestHandlerChain

中间件链对象，用于控制请求处理流程：

```cangjie
public interface JoyRequestHandlerChain {
    /**
     * 执行下一个中间件或最终 Handler
     */
    func next(ctx: JoyContext): Unit
}
```

---

## 二、注册中间件

### 2.1 全局注册 use()

使用 `use()` 方法将中间件注册到全局或指定的路由分组，该中间件会拦截所有经过该路由分组的请求：

```cangjie
import cjoy.*
import cjoy.middleware.*

// 单个中间件
let joy = Joy.default()
joy.router.use(AccessLog())      // 拦截所有请求

// 多个中间件（按注册顺序执行）
joy.router.use(ExceptionHandler())
joy.router.use(BasicAuth("test-realm", HashMap([
    ("user", "test"),
    ("password", "test")
]))

// 嵌套分组注册
let api = joy.router.group("/api")
api.use(Cors())
api.use(JwtAuth())
```

### 2.2 路由分组注册

使用 `group()` 创建子路由分组，然后在分组上注册中间件：

```cangjie
// group 内的中间件只作用于该分组下的请求
let users = joy.router.group("/users")
users.use(SessionManager())
users.get("/{id}", handler)
```

### 2.3 单次路由注册 apply()

使用 `apply()` 方法将中间件仅应用于本次注册的路由 Handler：

```cangjie
// apply 的中间件只对此次路由生效
router.get("/protected", handler).apply(AuthCheck())
```

---

## 三、使用方式对比

| 方式 | 作用范围 | 注册位置 |
|---|---|---|
| `use()` | 全局或指定分组 | 在 Router 上调用 |
| `apply()` | 单次路由 Handler | 在 Router 方法链式调用 |

---

## 四、宏注解注册

使用 `@Middleware` 宏可以自动将中间件注册到指定的分组：

```cangjie
import cjoy.macros.*

// 应用到 /users 分组
@Middleware[groups = "/users"]
func usersMiddleware(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
    chain.next(ctx)
}
```

**注意**：使用 `@Middleware` 宏时，无需手动注册中间件，框架会自动处理。

---

## 五、内置中间件

CJoy 内置以下中间件，开箱即用：

### 5.1 ExceptionHandler

异常处理中间件，捕获所有未处理的异常：

```cangjie
import cjoy.middleware.*

// 全局使用，捕获所有请求
joy.router.use(ExceptionHandler())
```

### 5.2 AccessLog

访问日志中间件，记录 HTTP 请求信息：

```cangjie
import cjoy.middleware.AccessLog

// 自定义过滤函数
let filterFn: {ctx: JoyContext =>
    ctx.path != "/heartbeat"  // 忽略心跳请求
}

// 应用到所有请求
joy.router.use(AccessLog(filterFn))
```

### 5.3 SessionManager

会话管理中间件，支持内存或文件存储的会话管理：

```cangjie
import cjoy.middleware.SessionManager
import cjoy.session.JoySessionConfig

// 内存存储
let joy = Joy.default()
joy.router.use(SessionManager(emorySessionStorage()))

// 文件存储
let joy = Joy.default()
joy.router.group("/file").use(SessionManager(FileSessionStorage(
    config: JoySessionConfig(
        cookieName: "sid",
        cookiePath: "/file",
        cookieDomain: "example.com"
    )))
```

### 5.4 CORS

跨域资源共享中间件，自动添加 CORS 相关响应头：

```cangjie
import cjoy.middleware.Cors

// 全局应用
joy.router.use(Cors())

// 指定分组应用
let api = joy.router.group("/api")
api.use(Cors(allowOrigins: ["https://example.com"]))
```

### 5.5 RequestId

请求 ID 生成中间件，为每个请求生成唯一标识符：

```cangjie
import cjoy.middleware.RequestId

joy.router.use(RequestId())

// 在 Handler 中获取请求 ID
@Get[path = "/request-id"]
func getRequestId(ctx: JoyContext): String {
    let requestId = ctx.getRequestId()
    "Request ID: ${requestId}"
}
```

### 5.6 NoCache

禁用缓存中间件，设置响应头禁用浏览器缓存：

```cangjie
import cjoy.middleware.NoCache

joy.router.use(NoCache())
```

### 5.7 CsrfProtect

CSRF 保护中间件，防御跨站请求伪造攻击：

```cangjie
import cjoy.middleware.CsrfProtect

joy.router.use(CsrfProtect())
```

### 5.8 Security

安全头域设置中间件，配置各类安全 HTTP 响应头：

```cangjie
import cjoy.middleware.Security

// 设置允许的主机名
let security = Security()
    security.allowedHosts(["localhost", "127.0.0.1"])

// 添加 X-Frame-Options
security.frameDeny = true
joy.router.use(security)

// 添加 Content-Type-Options
security.contentTypeNosniff = true
joy.router.use(security)

// 添加 X-XSS-Protection
security.browserXssFilter = true
joy.router.use(security)
```

### 5.9 BasicAuth

Basic 认证中间件，使用 HTTP Basic Auth 进行身份验证：

```cangjie
import cjoy.middleware.BasicAuth

// 全局注册 - 作用于所有路由
let joy = Joy.default()
joy.router.use(BasicAuth("test-realm", HashMap([
    ("user", "test"),
    ("password", "test")
]))

// 分组注册
let users = joy.router.group("/users")
users.use(BasicAuth("user-realm", HashMap([
    ("user", "user"),
    ("password", "user")
]))

// 单次路由注册 - 仅对指定路径生效
router.get("/login", handler).apply(BasicAuth("user-realm"))
```

### 5.10 TokenAuth

Token 认证中间件，使用 Bearer Token 进行身份验证：

```cangjie
import cjoy.middleware.TokenAuth

joy.router.use(TokenAuth())
```

### 5.11 JwtAuth

JWT 认证中间件，支持 JWT token 验证：

```cangjie
import cjoy.middleware.JwtAuth

joy.router.use(JwtAuth())
```

---

## 六、自定义中间件

### 6.1 实现接口

```cangjie
import cjoy.*
import cjoy.middleware.JoyMiddlewareHandler

// 自定义中间件
class CustomMiddleware <: JoyMiddlewareHandler {
    public func handle(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
        // 执行业务逻辑
        @JoyLogInfo("Custom middleware executed")
        chain.next(ctx)
    }
}

// 注册
let joy = Joy.default()
joy.router.use(CustomMiddleware())
```

### 6.2 使用 @Middleware 宏

```cangjie
import cjoy.macros.*

@Middleware[groups = "/api"]
func apiMiddleware(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
    chain.next(ctx)
}
```

---

## 七、完整示例

```cangjie
import std.collection.*
import std.time.DateTime
import cjoy.*
import cjoy.macros.*
import cjoy.middleware.{AccessLog, ExceptionHandler, BasicAuth, SessionManager}
import cjoy.context.ServiceContainer

// 定义中间件：记录请求耗时
class TimingMiddleware <: JoyMiddlewareHandler {
    @JoyCreateLogger("timing.middleware")
    private let _timings: HashMap<String, Int64> = HashMap()

    public func handle(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
        let start = DateTime.now()

        chain.next(ctx)

        let duration = DateTime.now().toUnixTimeStamp() - start.toUnixTimeStamp()
        let path = ctx.path

        // 使用上下文传递时长
        ctx.setCtxParam("requestTime", duration)

        @JoyLogInfo("[Timing] ${ctx.method} ${path} took ${duration}ms")
    }
}

// 使用宏注册的中间件
@Middleware[groups = "/api"]
func authMiddleware(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
    let token = ctx.getHeader("Authorization")

    if (token.isNone()) {
        ctx.status(401).string("Unauthorized")
        return
    }

    ctx.setCtxParam("userId", verifyToken(token))
    chain.next(ctx)
}

main(): Int64 {
    let joy = Joy.default()

    // 1. 全局中间件（所有请求）
    joy.router.use(ExceptionHandler())
    joy.router.use(TimingMiddleware())

    // 2. 分组中间件（只影响 /api 路径）
    let api = joy.router.group("/api")
    api.use(authMiddleware)

    // 3. 注册生成的 Handlers 和 Middlewares
    JoyMiddlewares.registerTo(joy)
    JoyHandlers.registerTo(joy)

    joy.run("127.0.0.1", 18881)
    return 0
}
```

---

## 八、注意事项

1. **执行顺序**：中间件按注册顺序执行，先注册的中间件先执行（如果相同分组）

2. **短路请求**：在中间件中直接返回响应会阻止后续中间件和 Handler 的执行

3. **chain.next()**：必须调用 `chain.next(ctx)` 继续执行中间件链，否则请求会被挂起

4. **分组继承**：子分组自动继承父分组的中间件栈

5. **use vs apply**：`use()` 作用于整个分组，`apply()` 仅作用于单次注册的 Handler

6. **@Middleware 宏**：使用 `@Middleware` 宏时无需手动注册，框架会自动处理

7. **上下文参数**：通过 `ctx.setCtxParam()` 和 `ctx.getCtxParam()` 在中间件和 Handler 之间传递数据

8. **异常处理**：`ExceptionHandler` 应该作为最后注册的中间件，确保所有异常都被捕获

9. **Session 存储**：`SessionManager` 默认使用内存存储，生产环境建议使用文件存储

10. **日志记录**：`AccessLog` 是专门的日志中间件，支持自定义过滤函数控制记录范围

11. **安全头**：`Security` 中间件可设置多种安全相关 HTTP 响应头，防止各类攻击

---
<< [返回](../../README.md#使用指导)
