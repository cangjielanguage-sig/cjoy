# 路由宏

CJoy 提供丰富的编译时宏系统，用于简化 Handler 注册、参数绑定和中间件定义。通过宏在编译时生成代码，实现零反射、高性能的运行时行为。

## 概述

CJoy 的宏系统基于以下核心概念设计：

- **编译时代码生成**：宏在编译时展开，生成高效的 Handler 和中间件代码
- **自动参数绑定**：通过参数绑定宏自动从请求中提取并转换参数
- **零反射**：所有路由和中间件信息在编译时确定，运行时无需反射查找
- **类型安全**：宏生成的代码遵循仓颉类型系统，编译时检查类型安全
- **自动注册**：生成的 Handler 和中间件自动添加到注册表，通过 `registerTo()` 统一注册

宏定义源码参见 [macros.cj](../../src/framework/macros/macros.cj)，测试用例参见 [macro_test.cj](../../src/test/macro_test.cj)。

---

## 一、Handler 宏

Handler 宏用于注册 HTTP 请求处理函数，支持自动参数绑定和响应处理。

### 1.1 可用的 HTTP 方法宏

| 宏 | HTTP 方法 |
|---|---|
| `@Get` | GET |
| `@Post` | POST |
| `@Put` | PUT |
| `@Delete` | DELETE |
| `@Patch` | PATCH |
| `@Head` | HEAD |
| `@Handler` | 自定义方法（通过 `methods` 指定） |

### 1.2 宏属性参数

| 参数 | 默认值 | 必选 | 说明 |
|---|---|---|---|
| `path` | - | 是 | 指定 Handler 处理的 URL 路由模式 |
| `produce` | `text` | 否 | 响应类型，`json` 或 `text` |
| `methods` | - | 否（仅 `@Handler`） | HTTP 方法列表，如 `"GET,POST"` |

### 1.3 基本用法

```cangjie
import cjoy.*
import cjoy.macros.*

// 简单 GET 请求，返回文本
@Get[path = "/ping"]
func ping(): String {
    "pong"
}

// 返回 JSON
@Post[path = "/users", produce = "json"]
func createUser(@BodyParam user: UserInfo): UserInfo {
    user
}

// 返回状态码和响应体
@Delete[path = "/users/{id}"]
func deleteUser(@PathParam id: String): (UInt16, String) {
    (204, "")
}
```

### 1.4 @Handler 自定义方法

使用 `@Handler` 宏可以同时支持多个 HTTP 方法：

```cangjie
// 同时支持 GET 和 POST
@Handler[path = "/resource", methods = "GET,POST"]
func handleResource(): String {
    "GET or POST"
}

// 支持单个方法
@Handler[path = "/resource", methods = "PUT"]
func handlePut(): String {
    "PUT"
}
```

---

## 二、参数绑定宏

参数绑定宏用于自动从请求中提取参数并绑定到函数参数。

### 2.1 参数绑定宏列表

| 宏 | 绑定来源 | 适用类型 |
|---|---|---|
| `@PathParam` | URL Path 参数 | String, 基本类型, DateTime |
| `@QueryParam` | URL Query 参数 | String, 基本类型, DateTime, ArrayList, Array |
| `@PostFormParam` | POST Form 参数 | String, 基本类型, DateTime, ArrayList, Array |
| `@HeaderParam` | HTTP Header | String, 基本类型, ArrayList, Array |
| `@CookieParam` | Cookie | String, 基本类型 |
| `@ContextParam` | 上下文参数 | 任意类型 |
| `@BodyParam` | Request Body | String, JsonDeserializable |
| `@QueryBindParam` | Query 参数绑定对象 | JoyBindable |
| `@PostFormBindParam` | POST Form 绑定对象 | JoyBindable |
| `@HeaderBindParam` | Header 绑定对象 | JoyBindable |

### 2.2 参数属性

所有参数绑定宏支持以下属性：

| 属性 | 默认值 | 必选 | 说明 |
|---|---|---|---|
| `name` | 函数参数名 | 否 | 映射的参数名称，不指定时使用函数参数名 |
| `default` | - | 否 | 参数不存在时的默认值 |
| `timeformat` | - | 否 | DateTime 类型参数的时间格式（如 `"yyyy-MM-dd HH:mm:ss"`） |

### 2.3 @PathParam

从 URL Path 中提取参数：

```cangjie
// 参数名与函数参数相同
@Get[path = "/users/{id}"]
func getUser(@PathParam id: String): String {
    "User ID: ${id}"
}

// 参数名不同
@Get[path = "/users/{userId}"]
func getUserById(@PathParam[name = userId] id: String): String {
    "User ID: ${id}"
}

// 通配符参数
@Get[path = "/files/*"]
func getFiles(@PathParam name = *] path: String): String {
    "Files: ${path}"
}

// 类型转换
@Get[path = "/page/{num}"]
func getPage(@PathParam num: Int64): String {
    "Page number: ${num}"
}

// DateTime 转换
@Get[path = "/events/{date}"]
func getEvent(@PathParam[name = date] event: DateTime): String {
    event.toString()
}

// 带默认值
@Get[path = "/posts/{category}"]
func getPosts(@PathParam[name = category, default = "all"] category: String): String {
    "Category: ${category}"
}
```

### 2.4 @QueryParam

从 URL Query String 中提取参数：

```cangjie
@Get[path = "/users"]
func listUsers(
    @QueryParam[name = "page", default = "1"] page: Int64,
    @QueryParam[name = "size", default = "10"] size: Int64
): String {
    "Page ${page}, Size ${size}"
}

// 多值参数
@Get[path = "/tags"]
func getTags(@QueryParam[name = "tag"] tags: ArrayList<String>): String {
    tags.toString()
}

// 可选参数
@Get[path = "/search"]
func search(@QueryParam keyword: ?String): String {
    keyword.getOrValue("")
}
```

### 2.5 @PostFormParam

从 POST Form 数据中提取参数：

```cangjie
@Post[path = "/login"]
func login(
    @PostFormParam username: String,
    @PostFormParam password: String
): String {
    "Login: ${username}"
}
```

### 2.6 @HeaderParam

从 HTTP Header 中提取参数：

```cangjie
@Get[path = "/protected"]
func checkAuth(@HeaderParam[name = "Authorization"] token: String): String {
    token
}

// 多值 Header
@Get[path = "/headers"]
func getHeaders(@HeaderParam[name = "X-Custom-Ids"] ids: Array<String>): String {
    ids.toString()
}
```

### 2.7 @CookieParam

从 Cookie 中提取参数：

```cangjie
@Get[path = "/profile"]
func getProfile(@CookieParam[name = "sessionId"] sid: String): String {
    "Session: ${sid}"
}
```

### 2.8 @ContextParam

从上下文中提取参数（由中间件设置）：

```cangjie
// 中间件中设置
@Middleware[groups = "/api"]
func authMiddleware(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
    let userId = verifyToken(ctx.getHeader("Authorization"))
    ctx.setCtxParam("userId", userId)
    chain.next(ctx)
}

// Handler 中获取
@Get[path = "/api/profile"]
func getProfile(@ContextParam[name = "userId"] userId: String): String {
    "User ID: ${userId}"
}
```

### 2.9 @BodyParam

从 Request Body 中提取参数：

```cangjie
// 字符串 Body
@Post[path = "/text"]
func handleText(@BodyParam text: String): String {
    text
}

// JSON Body
@Post[path = "/user", produce = "json"]
func createUser(@BodyParam user: UserInfo): UserInfo {
    user
}

// 可选 JSON Body
@Post[path = "/user", produce = "json"]
func updateUser(@BodyParam user: ?UserInfo): ?UserInfo {
    user
}

// 使用 @Json 注解的类
@Json
class UserInfo {
    var id: String = ""
    var name: String = ""
}
```

### 2.10 @QueryBindParam

将多个 Query 参数绑定到对象：

```cangjie
@Bind
class SearchParams {
    @BindField[name = "keyword"]
    var keyword: String = ""

    @BindField[name = "page"]
    var page: Int64 = 1
}

@Get[path = "/search"]
func search(@QueryBindParam params: SearchParams): String {
    "Keyword: ${params.keyword}, Page: ${params.page}"
}

// 请求: /search?keyword=hello&page=2
```

### 2.11 @PostFormBindParam

将多个 POST Form 参数绑定到对象：

```cangjie
@Bind
class LoginForm {
    @BindField[name = "username"]
    var username: String = ""

    @BindField[name = "password"]
    var password: String = ""
}

@Post[path = "/login"]
func login(@PostFormBindParam form: LoginForm): String {
    "Login: ${form.username}"
}
```

### 2.12 @HeaderBindParam

将多个 Header 参数绑定到对象：

```cangjie
@Bind
class RequestHeaders {
    @BindField[name = "content-type"]
    var contentType: String = ""

    @BindField[name = "authorization"]
    var auth: String = ""
}

@Get[path = "/api/data"]
func getData(@HeaderBindParam headers: RequestHeaders): String {
    "Content-Type: ${headers.contentType}"
}
```

---

## 三、支持的参数类型

| 参数类型 | 适用宏 | 说明 |
|---|---|---|
| `String` | 所有参数绑定宏 | 字符串类型 |
| `?String` | 所有参数绑定宏 | 可选字符串类型 |
| 基本类型 (`Int64`, `Float64`, `Bool` 等) | PathParam, QueryParam, PostFormParam, HeaderParam, CookieParam | 自动类型转换 |
| `?T`（T 为基本类型） | PathParam, QueryParam, PostFormParam, HeaderParam, CookieParam | 可选基本类型 |
| `DateTime` | PathParam, QueryParam, PostFormParam, HeaderParam | 日期时间类型，支持 `timeformat` |
| `?DateTime` | PathParam, QueryParam, PostFormParam, HeaderParam | 可选日期时间类型 |
| `ArrayList<String>` | QueryParam, PostFormParam, HeaderParam | 多值参数（数组列表） |
| `Array<String>` | QueryParam, PostFormParam, HeaderParam | 多值参数（定长数组） |
| `T <: JsonDeserializable` | BodyParam | 实现 JSON 反序列化的自定义类型 |
| `?T where T <: JsonDeserializable` | BodyParam | 可选的 JSON 类型 |
| `T <: JoyBindable` | QueryBindParam, PostFormBindParam, HeaderBindParam | 实现绑定的自定义类型 |
| `?T where T <: JoyBindable` | QueryBindParam, PostFormBindParam, HeaderBindParam | 可选的绑定类型 |
| `JoyContext` | - | 上下文对象，无需宏标注 |
| 任意类型 | ContextParam | 由中间件设置的任意类型 |

---

## 四、Handler 返回值类型

Handler 函数的返回值决定响应的处理方式：

| 返回值类型 | 说明 |
|---|---|
| 无返回值 | 无响应，不返回任何内容 |
| `String` | 返回文本，Content-Type = text/plain，StatusCode = 200 |
| `T where T <: JsonSerializable` | 返回 JSON，需指定 `produce = json`，StatusCode = 200 |
| `UInt16` | 只设置状态码 |
| `Unit` | 需手动调用 `ctx.json()`, `ctx.string()` 等方法设置响应 |
| `(UInt16, String)` | 返回状态码和文本响应 |
| `(String, UInt16)` | 返回文本响应和状态码 |
| `(UInt16, T where T <: JsonSerializable)` | 返回状态码和 JSON 响应，需指定 `produce = json` |
| `(T where T <: JsonSerializable, UInt16)` | 返回 JSON 响应和状态码，需指定 `produce = json` |
| `(UInt16, T where T <: ToString)` | 返回状态码和文本响应 |
| `(T where T <: ToString, UInt16)` | 返回文本响应和状态码 |

```cangjie
// Unit 类型 - 手动设置响应
@Get[path = "/manual"]
func manualResponse(ctx: JoyContext): Unit {
    ctx.status(200).json({"message": "ok"})
}

// String 类型 - 自动文本响应
@Get[path = "/text"]
func textResponse(): String {
    "Hello"
}

// JSON 类型 - 自动 JSON 响应
@Get[path = "/json", produce = "json"]
func jsonResponse(): UserInfo {
    UserInfo()
}

// UInt16 类型 - 只设置状态码
@Delete[path = "/item/{id}"]
func deleteItem(@PathParam id: String): UInt16 {
    204
}

// 元组类型 - 状态码和响应体
@Post[path = "/create", produce = "json"]
func createItem(@BodyParam item: Item): (UInt16, Item) {
    (201, item)
}
```

---

## 五、Middleware 宏

Middleware 宏用于定义中间件函数。

### 5.1 宏属性

| 参数 | 默认值 | 必选 | 说明 |
|---|---|---|---|
| `groups` | `"/"`（根路由） | 否 | 中间件应用的分组路径列表，逗号分隔 |

### 5.2 基本用法

```cangjie
// 应用到指定分组
@Middleware[groups = "/api,/v1"]
func apiAuth(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
    // 认证逻辑
    let token = ctx.getHeader("Authorization")
    if (token.isNone()) {
        ctx.status(401).string("Unauthorized")
        return
    }
    chain.next(ctx)
}

// 应用到根路由（所有请求）
@Middleware
func globalLogger(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
    println("Request: ${ctx.path}")
    chain.next(ctx)
}

// 应用到多级分组
@Middleware[groups = "/api/v1/users,/api/v1/posts"]
func checkPermission(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
    chain.next(ctx)
}
```

### 5.3 分组自动创建

指定 `groups` 参数时，框架会自动创建对应的分组：

```cangjie
// 定义应用到 /api/v1 的中间件
@Middleware[groups = "/api/v1"]
func v1Middleware(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
    chain.next(ctx)
}

// 相当于执行了以下代码：
// let api = router.group("/api")
// let v1 = api.group("/v1")
// v1.use(V1Middleware())
```

如果 Handler 也定义在相同的路径上，它会自动注册到对应的分组：

```cangjie
@Middleware[groups = "/users"]
func userMiddleware(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
    chain.next(ctx)
}

@Get[path = "/users/{id}"]
func getUser(@PathParam id: String): String {
    id
}

// 这个 Handler 会自动注册到 /users 分组，经过 userMiddleware
```

---

## 六、注册到 Joy 实例

所有宏生成的 Handler 和 Middleware 都需要显式注册到 Joy 实例。

### 6.1 注册顺序

```cangjie
main(): Int64 {
    let joy = Joy.default()

    // 1. 先注册 Middleware
    JoyMiddlewares.registerTo(joy)

    // 2. 再注册 Handlers
    JoyHandlers.registerTo(joy)

    // 3. 启动服务
    joy.run("127.0.0.1", 18881)
    return 0
}
```

**重要**：
- `JoyMiddlewares.registerTo(joy)` 必须在 `JoyHandlers.registerTo(joy)` 之前调用
- `JoyHandlers.registerTo(joy)` 会同时初始化所有 IoC Bean

### 6.2 IoC Bean 初始化

如果使用 `@Component` 定义的 Bean，注册 Handlers 时会自动初始化：

```cangjie
import cjoy.ioc.*

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

main(): Int64 {
    let joy = Joy.default()
    JoyHandlers.registerTo(joy)  // 会初始化 UserService Bean
    joy.run("127.0.0.1", 18881)
    return 0
}
```

---

## 七、完整示例

```cangjie
import std.collection.*
import stdx.net.http.HttpStatusCode
import cjoy.*
import cjoy.json.*
import cjoy.macros.*
import cjoy.bind.*

// 定义数据模型
@Json
@Bind
@Derive[ToString]
class User {
    var id: String = ""
    var name: String = ""
    var email: String = ""
}

@Bind
@Derive[ToString]
class QueryParams {
    @BindField[name = "page"]
    var page: Int64 = 1

    @BindField[name = "size"]
    var size: Int64 = 10
}

// 定义中间件
@Middleware[groups = "/api"]
func apiAuth(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
    let token = ctx.getHeader("Authorization")
    if (token.isNone()) {
        ctx.status(HttpStatusCode.STATUS_UNAUTHORIZED).string("Unauthorized")
        return
    }
    chain.next(ctx)
}

@Middleware
func logger(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
    println("[${ctx.method}] ${ctx.path}")
    chain.next(ctx)
}

// 定义 Handler
@Get[path = "/ping"]
func ping(): String {
    "pong"
}

@Get[path = "/api/users", produce = "json"]
func listUsers(
    @QueryBindParam params: QueryParams
): Array<User> {
    // 根据 params.page 和 params.size 查询用户
    []
}

@Get[path = "/api/users/{id}", produce = "json"]
func getUser(@PathParam id: String): User {
    User(id: id, name: "User ${id}", email: "")
}

@Post[path = "/api/users", produce = "json"]
func createUser(@BodyParam user: User): (UInt16, User) {
    (HttpStatusCode.STATUS_CREATED, user)
}

@Delete[path = "/api/users/{id}"]
func deleteUser(@PathParam id: String): UInt16 {
    HttpStatusCode.STATUS_NO_CONTENT
}

main(): Int64 {
    let joy = Joy.default()

    // 注册中间件（必须先于 Handler）
    JoyMiddlewares.registerTo(joy)

    // 注册 Handler
    JoyHandlers.registerTo(joy)

    joy.run("127.0.0.1", 18881)
    return 0
}
```

---

## 注意事项

1. **注册顺序**：必须先调用 `JoyMiddlewares.registerTo(joy)`，再调用 `JoyHandlers.registerTo(joy)`，确保中间件能拦截请求

2. **IoC Bean 初始化**：`JoyHandlers.registerTo(joy)` 会自动初始化所有 `@Component` Bean，确保所有 Bean 定义在调用之前

3. **参数类型匹配**：参数类型不匹配时会抛出异常，建议使用 `Option<T>` 处理可选参数

4. **JoyContext 参数**：`JoyContext` 类型参数不需要宏标注，可以直接在函数签名中使用

5. **不支持 `_` 参数名**：函数参数名不能是 `_`，宏会跳过该参数

6. **Group 自动创建**：指定 `groups` 属性时，框架会自动创建对应的路由分组

7. **produce 参数**：返回 JSON 类型时必须指定 `produce = json`，否则会作为文本处理

8. **时间格式**：DateTime 类型参数建议使用 `timeformat` 属性指定格式，如 `"yyyy-MM-dd HH:mm:ss"`

9. **绑定宏**：`@Bind` 注解需要与 `cjoy.bind` 模块配合使用，实现参数绑定

10. **Controller 组合**：`@Controller` 可以与 Handler 宏组合使用，实现类级别的 Handler 组织

---
<< [返回](../../README.md#使用指导)
