# 请求处理

CJoy 提供灵活的 HTTP 请求处理机制，支持多种 Handler 实现方式和完整的参数绑定能力。

## 概述

CJoy 的 Handler 系统基于以下核心概念设计：

- **编译时宏生成**：通过宏在编译时生成 Handler 代码，实现零反射、高性能的运行时行为
- **三种实现方式**：支持实现接口、Lambda 表达式、宏注解三种方式定义 Handler
- **自动参数绑定**：通过参数绑定宏自动从请求中提取并转换参数
- **上下文传递**：`JoyContext` 提供统一的请求/响应操作接口
- **链式调用**：响应方法支持链式调用，提高代码可读性
- **路由分组**：支持路由分组和中间件，便于模块化管理

核心接口定义：
- `JoyRequestHandler`：请求处理器接口，参见 [handler.cj](../../src/framework/handler.cj)
- `JoyContext`：请求/响应上下文接口，参见 [context.cj](../../src/framework/context.cj)
- `JoyRouters`：路由器接口，参见 [route.cj](../../src/framework/route.cj)

---

## 一、实现 JoyRequestHandler 接口

`JoyRequestHandler` 接口定义参见 [handler.cj](../../src/framework/handler.cj)。

```cangjie
import cjoy.*
import cjoy.middleware.*

// 实现 JoyRequestHandler
class UserHandler <: JoyRequestHandler {
    public func handle(ctx: JoyContext): Unit {
        let name = ctx.getParam("name") ?? "no name"
        ctx.string("Hello, ${name}")
    }
}

// 注册路由
router.get("/{name}", UserHandler())
```

---

## 二、Lambda 表达式函数

直接使用 Lambda 表达式作为 Handler：

```cangjie
router.get("/{name}", { ctx: JoyContext =>
    let name = ctx.getParam("name") ?? "no name"
    ctx.string("Hello, ${name}")
})

// 支持所有 HTTP 方法
router.post("/users", { ctx: JoyContext => ... })
router.put("/users/{id}", { ctx: JoyContext => ... })
router.delete("/users/{id}", { ctx: JoyContext => ... })
router.patch("/users/{id}", { ctx: JoyContext => ... })
router.head("/users", { ctx: JoyContext => ... })
router.options("/users", { ctx: JoyContext => ... })
```

---

## 三、宏注解定义 Handler

使用宏注解可以更简洁地定义 Handler，支持参数自动绑定。

### 3.1 基本用法

```cangjie
import cjoy.*
import cjoy.macros.*

// GET /abc
@Get[path = "/abc"]
func getStaticPath(): String {
    "/abc"
}

// GET /users/xiao
@Get[path = "/users/{name}"]
func getUserName(@PathParam name: String): (UInt16, String) {
    (200, "/users/${name}")
}

// GET /users?id=00009527
@Get[path = "/users", produce = "json"]
func listUsers(@QueryParam[name = "id", default = "00009527"] id: String): UserInfo {
    let usr = UserInfo()
    usr.id = id
    usr.name = "xiao"
    usr
}
```

### 3.2 可用的 HTTP 方法宏

| 宏 | HTTP 方法 |
|---|---|
| `@Get` | GET |
| `@Post` | POST |
| `@Put` | PUT |
| `@Delete` | DELETE |
| `@Patch` | PATCH |
| `@Head` | HEAD |
| `@Handler[method = "GET,POST"]` | 自定义方法 |

### 3.3 宏参数

- `path`: 路由路径，如 `"/users/{id}"`
- `produce`: 响应类型，`"json"` 或 `"text"`
- `methods`: HTTP 方法（仅 `@Handler` 使用），如 `"GET,POST"`

### 3.4 返回值类型

Handler 函数的返回值决定了响应的处理方式：

| 返回类型 | 说明 |
|---|---|
| `Unit` | 需要手动调用 `ctx.json()`, `ctx.string()` 等方法设置响应 |
| `T` (单值) | 根据 `produce` 自动序列化为 JSON 或 Text 响应 |
| `UInt16` | 只设置状态码，不设置响应体 |
| `(UInt16, T)` | 元组形式，第一个为状态码，第二个为响应体 |
| `(T, UInt16)` | 元组形式，第一个为响应体，第二个为状态码 |

```cangjie
// Unit 类型 - 手动设置响应
@Get[path = "/manual"]
func manualResponse(ctx: JoyContext): Unit {
    ctx.status(200).json({"message": "ok"})
}

// 单值返回 - 自动响应
@Get[path = "/single", produce = "json"]
func singleResponse(): UserInfo {
    UserInfo()
}

// 状态码返回
@Get[path = "/status"]
func statusOnly(): UInt16 {
    204
}

// 元组返回 - (状态码, 响应体)
@Get[path = "/tuple"]
func tupleResponse(): (UInt16, String) {
    (201, "created")
}
```

### 3.5 @Controller 控制器

使用 `@Controller` 可以将多个 Handler 组织在一个类中：

```cangjie
import cjoy.*
import cjoy.ioc.*
import cjoy.macros.*

@Controller[path = "/users"]
class UserHandler {
    let users: HashMap<String, UserInfo> = HashMap()

    @Post[path = "/"]
    public func create(ctx: JoyContext, @BodyParam user: UserInfo): Unit {
        users.add(user.name, user)
        ctx.status(201)
    }

    @Get[path = "/{name}"]
    public func query(ctx: JoyContext, @PathParam name: String): Unit {
        match (users.get(name)) {
            case Some(u) => ctx.json(u)
            case _ => ctx.status(404)
        }
    }

    @Get[path = "/"]
    public func list(ctx: JoyContext): Unit {
        ctx.json(users.values().toArray())
    }

    @Delete[path = "/{name}"]
    public func delete(ctx: JoyContext, @PathParam name: String): Unit {
        users.remove(name)
        ctx.status(204)
    }
}

main(): Int64 {
    let joy = Joy.default()
    JoyHandlers.registerTo(joy)  // 必须调用，注册宏生成的 Handlers
    joy.run("127.0.0.1", 18881)
    return 0
}
```

---

## 四、参数绑定宏

使用参数绑定宏可以自动从请求中提取参数并绑定到函数参数。

### 4.1 可用的参数绑定宏

| 宏 | 绑定来源 | 示例 |
|---|---|---|
| `@PathParam[name = "id"]` | URL Path 参数 | `/users/{id}` |
| `@QueryParam[name = "page", default = "1"]` | URL Query 参数 | `?page=1` |
| `@PostFormParam[name = "name"]` | POST Form 参数 | 表单提交 |
| `@HeaderParam[name = "Auth"]` | HTTP Header | `Authorization` |
| `@CookieParam[name = "token"]` | Cookie | `Set-Cookie` |
| `@BodyParam` | Request Body | JSON 请求体 |
| `@ContextParam[name = "userId"]` | 上下文参数 | Middleware 设置 |

### 4.2 参数绑定示例

```cangjie
import cjoy.macros.*

// Path 参数绑定
@Get[path = "/users/{id}"]
func getUser(@PathParam id: String): UserInfo {
    // id 自动从路径提取
    UserInfo()
}

// Query 参数绑定
@Get[path = "/users"]
func listUsers(
    @QueryParam[name = "page", default = "1"] page: Int64,
    @QueryParam[name = "size", default = "10"] size: Int64
): Array<UserInfo> {
    // page 和 size 自动从查询参数提取
    []
}

// Body 参数绑定
@Post[path = "/users"]
func createUser(@BodyParam user: UserInfo): UInt16 {
    // user 自动从 JSON 请求体反序列化
    201
}

// Header 参数绑定
@Get[path = "/protected"]
func protected(@HeaderParam name = "Authorization"] token: String): UserInfo {
    UserInfo()
}

// 上下文参数绑定
@Get[path = "/current"]
func getCurrentUser(@ContextParam name = "userId"] userId: String): UserInfo {
    UserInfo()
}
```

### 4.3 参数类型支持

参数绑定支持以下类型：

| 类型 | 说明 |
|---|---|
| `String` | 字符串类型 |
| 基本类型 (`Int64`, `Float64`, `Bool`) | 自动类型转换 |
| `Option<T>` | 可选类型，参数不存在时返回 `None` |
| `ArrayList<String>` | 多值参数（如 `?tag=a&tag=b`） |
| `T <: JsonDeserializable` | 实现 JSON 反序列化的自定义类型 |

---

## 五、路由注册

HTTP Handler 通过调用 `JoyRouters` 的方法注册到路由上。`JoyRouters` 接口定义参见 [route.cj](../../src/framework/route.cj)。

### 5.1 基本路由

```cangjie
let router = joy.router

router.get("/path", handler)
router.post("/path", handler)
router.put("/path", handler)
router.delete("/path", handler)
router.patch("/path", handler)
router.head("/path", handler)
router.options("/path", handler)
```

### 5.2 路由分组

```cangjie
// 创建子路由分组
let api = router.group("/api")

api.get("/users", handler)  // 实际路径: /api/users
api.post("/users", handler)

// 嵌套分组
let v1 = api.group("/v1")
v1.get("/users", handler)  // 实际路径: /api/v1/users
```

### 5.3 批量创建分组

```cangjie
// 等价于 group("/api").group("/v1").group("/users")
let users = router.createGroups("/api/v1/users")
```

### 5.4 路由中间件

```cangjie
// 全局中间件（影响所有子路由）
let api = router.group("/api")
api.use(AccessLog(), ExceptionHandler())

// 单次应用中间件
api.get("/users", handler).apply(CheckAuth())
```

---

## 六、处理上下文 JoyContext

Handler 的入参 `JoyContext` 提供上下文支持，用于获取请求内容与响应客户端。完整的 API 请参见源码 [context.cj](../../src/framework/context.cj)。

### 6.1 请求参数获取

| 函数 | 说明 |
|---|---|
| `getParam(name: String): ?String` | 获取 URL Path 参数 |
| `addParam(name: String, value: String): Unit` | 添加 Path 参数 |
| `getQuery(name: String): ?String` | 获取 Query 参数 |
| `getQuery(name: String, default: String): String` | 获取 Query 参数（带默认值） |
| `getQueryList(name: String): ArrayList<String>` | 获取多值 Query 参数 |
| `getPostForm(name: String): ?String` | 获取 POST Form 参数 |
| `getPostForm(name: String, default: String): String` | 获取 POST Form 参数（带默认值） |
| `getPostFormList(name: String): ArrayList<String>` | 获取多值 POST Form 参数 |
| `getForm(name: String): ?String` | 获取 POST Form 或 Query 参数 |
| `getHeader(name: String): ?String` | 获取 Header |
| `getHeaderList(name: String): Collection<String>` | 获取多值 Header |
| `getCookie(name: String): ?String` | 获取 Cookie |

### 6.2 请求体读取

| 函数 | 说明 |
|---|---|
| `readJson<T>(): ?T` | 读取并反序列化 JSON Body |
| `readString(): String` | 读取请求体为字符串 |
| `readRawData(): Array<Byte>` | 读取请求体为字节数组 |
| `bindJsonBody<T>(): ?T` | 绑定 JSON Body 到对象 |
| `bindQuery<T>(): ?T` | 绑定 Query 参数到对象 |
| `bindPostForm<T>(): ?T` | 绑定 POST Form 到对象 |
| `bindHeader<T>(): ?T` | 绑定 Header 到对象 |

### 6.3 响应设置

| 函数 | 说明 |
|---|---|
| `status(status: UInt16): JoyContext` | 设置 HTTP 状态码 |
| `ok(): JoyContext` | 设置状态码为 200 |
| `json<T>(body: T): JoyContext` | 返回 JSON 响应 |
| `json(body: String): JoyContext` | 返回 JSON 字符串响应 |
| `string(body: String): JoyContext` | 返回纯文本响应 |
| `text(body: String): JoyContext` | 返回 text/plain 响应 |
| `html(body: String): JoyContext` | 返回 HTML 响应 |
| `string(contentType: String, body: String): JoyContext` | 返回指定类型的文本响应 |
| `data(body: Array<Byte>): JoyContext` | 返回二进制响应 |
| `data(body: InputStream): JoyContext` | 返回流响应 |
| `contentType(contentType: String): JoyContext` | 设置响应 Content-Type |
| `header(name: String, value: String): JoyContext` | 设置响应 Header |
| `cookie(cookie: Cookie): JoyContext` | 设置 Cookie |
| `redirect(status: UInt16, location: String): Unit` | 重定向 |
| `notFound(): Unit` | 返回 404 响应 |

### 6.4 其他功能

| 函数 | 说明 |
|---|---|
| `getClientIP(): String` | 获取客户端真实 IP |
| `getRemoteIP(): String` | 获取连接的远程 IP |
| `getContentType(): String` | 获取请求 Content-Type |
| `basicAuth(): ?(String, String)` | 获取 Basic Auth 用户名密码 |
| `chunkedWriter(): JoyChunkedWriter` | 创建分块写入器 |
| `eventEmitter(): JoySseEmitter` | 创建 SSE 事件发射器 |

### 6.5 属性访问

| 属性 | 说明 |
|---|---|
| `httpContext: HttpContext` | SDK HTTP 上下文 |
| `config: JoyConfig` | 引擎配置 |
| `params: HashMap<String, String>` | Path 参数映射 |
| `cookies: HashMap<String, String>` | Cookie 映射 |
| `method: String` | HTTP 请求方法 |
| `path: String` | 请求路径 |
| `url: URL` | 请求完整 URL |
| `respStatus: UInt16` | 响应状态码 |
| `respBody: String` | 响应体 |

### 6.6 上下文参数

用于在中间件和 Handler 之间传递数据：

```cangjie
// 设置上下文参数
func authMiddleware(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
    let userId = verifyToken(ctx.getHeader("Authorization"))
    ctx.setCtxParam("userId", userId)
    chain.next(ctx)
}

// 获取上下文参数
@Get[path = "/profile"]
func getProfile(@ContextParam[name = "userId"] userId: String): UserInfo {
    UserInfo()
}
```

| 函数 | 说明 |
|---|---|
| `setCtxParam(key: String, value: Any): Unit` | 设置上下文参数 |
| `getCtxParam<T>(key: String): ?T` | 获取上下文参数 |

### 6.7 链式调用

响应方法支持链式调用：

```cangjie
ctx.status(200)
   .header("X-Custom-Header", "value")
   .contentType("application/json")
   .json({"message": "success"})
```

---

## 七、注册宏生成的 Handlers

使用宏注解定义的 Handler 需要调用 `JoyHandlers.registerTo()` 注册：

```cangjie
main(): Int64 {
    let joy = Joy.default()
    JoyHandlers.registerTo(joy)  // 注册所有宏生成的 Handlers
    joy.run("127.0.0.1", 18881)
    return 0
}
```

**注意**：`JoyHandlers.registerTo()` 会同时初始化所有 IoC Bean。

---

## 八、完整示例

```cangjie
package examples.handler

import std.collection.*
import stdx.net.http.{HttpStatusCode, Cookie}
import cjoy.*
import cjoy.macros.*
import cjoy.json.*
import cjoy.middleware.*

@Json
class UserInfo {
    var id: String = ""
    var name: String = ""
    var email: String = ""
}

// 使用宏定义的 Handlers
@Get[path = "/ping"]
func ping(ctx: JoyContext): String {
    "pong"
}

@Get[path = "/users/{id}", produce = "json"]
func getUser(@PathParam id: String): UserInfo {
    UserInfo()
}

@Post[path = "/users", produce = "json"]
func createUser(@BodyParam user: UserInfo): (UInt16, UserInfo) {
    (HttpStatusCode.STATUS_CREATED, user)
}

main(): Int64 {
    let joy = Joy.default()

    // 中间件
    joy.router.use(AccessLog())
    joy.router.use(ExceptionHandler())

    // 手动注册的 Handler
    joy.router.get("/hello", { ctx: JoyContext =>
        ctx.string("Hello, CJoy!")
    })

    // 注册宏生成的 Handlers
    JoyHandlers.registerTo(joy)

    joy.run("127.0.0.1", 18881)
    return 0
}
```

## 注意事项

1. **JoyHandlers.registerTo()**：使用宏注解（`@Get`、`@Post` 等）定义的 Handler 必须调用 `JoyHandlers.registerTo(joy)` 进行注册，否则无法生效

2. **IoC Bean 初始化**：`JoyHandlers.registerTo()` 会同时初始化所有 IoC Bean，确保在调用前完成所有 Bean 定义

3. **参数类型转换**：参数绑定宏会自动进行类型转换，但转换失败时会抛出异常，建议使用 `Option<T>` 处理可选参数

4. **响应时机**：当 Handler 函数返回时，构建的响应消息会自动发送给客户端。使用 `Unit` 返回类型时，必须手动调用响应方法

5. **链式调用**：响应方法（`json()`、`string()` 等）返回 `JoyContext`，支持链式调用，但 `redirect()` 和 `notFound()` 方法会立即发送响应，不支持链式调用

6. **路由分组**：子分组会继承父分组的中间件，使用 `group()` 创建的分组共享中间件栈

7. **请求体读取**：`readJson()`、`readString()`、`readRawData()` 方法会缓存请求体，支持多次读取

8. **上下文参数**：`setCtxParam()` / `getCtxParam()` 用于在中间件和 Handler 之间传递数据，生命周期限于单次请求

9. **路径参数**：路径参数（如 `/users/{id}`）通过 `getParam()` 获取，不存在时返回 `None`

10. **通配符路由**：支持 `*` 通配符，如 `/static/*` 可匹配 `/static/a/b/c`

---
<< [返回](../../README.md#使用指导)
