# 路由

CJoy 使用压缩前缀树（Compressed Prefix Tree）实现高效的路由匹配系统，支持多种路由模式和灵活的分组管理。

## 概述

CJoy 路由系统基于以下核心概念设计：

- **压缩前缀树**：使用压缩前缀树存储路由，实现 O(1) ~ O(n) 的高效匹配性能
- **四种路由模式**：支持静态路由、参数路由、正则路由、通配符路由
- **路由分组**：支持路由分组和嵌套分组，便于模块化管理
- **中间件继承**：子分组自动继承父分组的中间件栈
- **大小写敏感**：可通过配置开启/关闭路径大小写敏感

核心接口定义：
- `JoyRouters`：路由器接口，参见 [route.cj](../../src/framework/route.cj)
- `TreeNode`：压缩前缀树节点，参见 [tree.cj](../../src/framework/tree.cj)

---

## 一、路由规则

注册的路径支持四种路由匹配模式：

| 模式 | 说明 | 示例 |
|---|---|---|
| **静态路由** | 路径不存在 `{}` 或 `*` 参数，路径全匹配 | `/favicon.ico` |
| **参数路由** | 路径中使用 `{paramname}` 命名参数 | `/users/{id}` |
| **正则路由** | 路径中使用 `{paramname:regex}` 正则表达式 | `/page/{id:[0-9]+}` |
| **通配符路由** | 路径中使用 `*` 捕获剩余路径 | `/static/*` |

### 1.1 静态路由

路径全匹配，不包含任何参数占位符：

```cangjie
router.get("/favicon.ico", handler)
router.get("/health", handler)
router.get("/users/list", handler)
```

### 1.2 参数路由

使用 `{paramname}` 定义命名参数，匹配任意非空字符串（不跨路径段）：

```cangjie
// 单参数
router.get("/users/{id}", handler)  // 匹配 /users/1, /users/abc
                                  // 参数 id = "1" 或 "abc"

// 多参数
router.get("/users/{id}/posts/{postId}", handler)
// 匹配 /users/1/posts/100
// 参数 id = "1", postId = "100"

// 同一段多个参数
router.get("/articles/{id}:{op}", handler)
// 匹配 /articles/123:delete
// 参数 id = "123", op = "delete"
```

**注意**：参数路由不会跨路径段匹配，如 `/users/{id}` 不能匹配 `/users/1/2`。

### 1.3 正则路由

使用 `{paramname:regex}` 定义正则表达式匹配：

```cangjie
// 只匹配数字
router.get("/page/{id:[0-9]+}", handler)
// 匹配 /page/1, /page/123
// 不匹配 /page/abc

// 只匹配小写字母
router.get("/user/{name:[a-z]{3,10}}", handler)
// 匹配 /user/xiao
// 不匹配 /user/XIAO, /user/ab

// 组合使用
router.get("/file/{name:[a-z0-9]+}-{version:[0-9]+}", handler)
// 匹配 /file/document-123
```

正则表达式会自动添加 `^` 和 `$` 锚点，确保完整匹配。

### 1.4 通配符路由

使用 `*` 捕获路径剩余部分，可匹配多段路径：

```cangjie
router.get("/images/*", handler)
// 匹配 /images/abc          -> 参数 * = "abc"
// 匹配 /images/abc/def      -> 参数 * = "abc/def"
// 匹配 /images/2014/05/pic.jpg -> 参数 * = "2014/05/pic.jpg"
// 匹配 /images/              -> 参数 * = ""
```

通配符必须是路由模式的最后一个元素：

```cangjie
// 正确
router.get("/static/*", handler)

// 错误：通配符后还有内容
router.get("/static/*/file", handler)  // 抛出 IllegalArgumentException
```

---

## 二、路由优先级

路由查找优先级：**静态路由 > 正则路由 > 参数路由 > 通配符路由**

路由匹配优先级与注册顺序无关，仅由路由模式类型决定。

### 2.1 优先级示例

```cangjie
router.get("/users/{name}", {ctx: JoyContext => })
router.get("/users/abc", {ctx: JoyContext => })
router.get("/users/{name:[a-z]{3,4}}", {ctx: JoyContext => })
router.get("/users/*", {ctx: JoyContext => })
```

| 请求路径 | 匹配路由 | 说明 |
|---|---|---|
| `/users/abc` | `/users/abc` | 静态路由优先 |
| `/users/xiao` | `/users/{name:[a-z]{3,4}}` | 正则路由次之 |
| `/users/xiaoliu` | `/users/{name}` | 参数路由再次 |
| `/users/xiao/abc` | `/users/*` | 通配符最后 |

### 2.2 更多示例

```cangjie
router.get("/{page}", {ctx: JoyContext => })
router.get("/{year}/{month}/{post}", {ctx: JoyContext => })
router.get("/{year}/{month}", {ctx: JoyContext => })
router.get("/images/*", {ctx: JoyContext => })
router.get("/favicon.ico", {ctx: JoyContext => })
```

| 请求路径 | 匹配路由 | 参数 |
|---|---|---|
| `/abc` | `/{page}` | page = "abc" |
| `/2024/05` | `/{year}/{month}` | year = "2024", month = "05" |
| `/2024/05/really-great-blog-post` | `/{year}/{month}/{post}` | year = "2024", month = "05", post = "really-great-blog-post" |
| `/images/image.gif` | `/images/*` | * = "image.gif" |
| `/images/2014/05/image.jpg` | `/images/*` | * = "2014/05/image.jpg" |
| `/favicon.ico` | `/favicon.ico` | - |

---

## 三、路由注册

### 3.1 HTTP 方法路由

`JoyRouters` 接口支持所有标准 HTTP 方法：

```cangjie
let router = joy.router

router.get("/path", handler)      // GET
router.post("/path", handler)     // POST
router.put("/path", handler)      // PUT
router.delete("/path", handler)   // DELETE
router.patch("/path", handler)    // PATCH
router.head("/path", handler)     // HEAD
router.options("/path", handler)  // OPTIONS
```

### 3.2 多方法路由

使用 `handle()` 方法为多个 HTTP 方法注册同一个 Handler：

```cangjie
// 单个 Handler 处理多个方法
router.handle(["GET", "POST"], "/path", handler)

// 使用 Lambda
router.handle(["GET", "PUT"], "/resource", {ctx: JoyContext =>
    ctx.string("GET or PUT")
})
```

### 3.3 Handler 类型

支持三种 Handler 类型：

```cangjie
// JoyRequestHandler 接口实现
class MyHandler <: JoyRequestHandler {
    public func handle(ctx: JoyContext): Unit {
        ctx.string("handled")
    }
}
router.get("/", MyHandler())

// Lambda 函数（JoyRequestHandlerFunc）
router.get("/", {ctx: JoyContext => ctx.string("handled")})

// 函数引用
router.get("/", myHandlerFunc)
```

---

## 四、路由分组

### 4.1 基本用法

使用 `group()` 方法创建子路由分组：

```cangjie
let router = joy.router

let v1 = router.group("/v1")
v1.get("/users", handler)  // 实际路径: /v1/users
v1.get("/posts", handler)  // 实际路径: /v1/posts
```

### 4.2 嵌套分组

支持多级嵌套分组：

```cangjie
let api = router.group("/api")
let v1 = api.group("/v1")
let users = v1.group("/users")

users.get("/", listHandler)       // 实际路径: /api/v1/users/
users.get("/{id}", getHandler)    // 实际路径: /api/v1/users/{id}
```

### 4.3 批量创建分组

使用 `createGroups()` 快速创建多级分组：

```cangjie
// 等价于 group("/api").group("/v1").group("/users")
let users = router.createGroups("/api/v1/users")
users.get("/", handler)  // /api/v1/users/
```

### 4.4 路由分组特性

- **共享路径前缀**：分组内所有路由自动添加公共前缀
- **继承中间件**：子分组继承父分组的中间件栈
- **默认 Handler**：创建分组时自动注册 `/{group}`, `/{group}/`, `/{group}/*` 的默认处理

```cangjie
let v1 = router.group("/v1")
// 自动注册以下默认 Handler：
// GET/POST/DELETE/PUT/PATCH/HEAD/OPTIONS /v1
// GET/POST/DELETE/PUT/PATCH/HEAD/OPTIONS /v1/
// GET/POST/DELETE/PUT/PATCH/HEAD/OPTIONS /v1/*

// 可以覆盖默认 Handler
v1.get("", customHandler)
v1.get("/", customHandler)
v1.get("/*", customHandler)
```

---

## 五、中间件与路由

### 5.1 全局中间件

使用 `use()` 方法注册全局中间件，影响整个路由分组：

```cangjie
let api = router.group("/api")

// 多个中间件
api.use(AccessLog(), ExceptionHandler(), Cors())

api.get("/users", handler)  // 会经过上述所有中间件
```

### 5.2 单次中间件

使用 `apply()` 方法为单个路由应用中间件：

```cangjie
// 仅对此路由应用中间件
router.get("/protected", handler).apply(AuthCheck())
```

### 5.3 中间件继承

子分组自动继承父分组的中间件：

```cangjie
let api = router.group("/api")
api.use(AuthCheck())  // api 及其子分组都有此中间件

let v1 = api.group("/v1")
v1.get("/users", handler)  // 会经过 AuthCheck 中间件
```

---

## 六、特殊路由

### 6.1 WebSocket 路由

使用 `websocket()` 方法注册 WebSocket 处理器：

```cangjie
import cjoy.websocket.*

class MyWSHandler <: JoyWebSocketHandler {
    public func onOpen(ws: JoyWebSocket): Unit {
        println("WebSocket connected")
    }

    public func onMessage(ws: JoyWebSocket, message: String): Unit {
        ws.send("echo: ${message}")
    }

    public func onClose(ws: JoyWebSocket, code: UInt16, reason: String): Unit {
        println("WebSocket closed")
    }
}

router.websocket("/ws", MyWSHandler())
```

### 6.2 静态文件路由

使用 `staticFs()` 和 `staticFile()` 提供静态文件服务：

```cangjie
// 静态文件目录
router.staticFs("/static", "./public")
// GET /static/style.css -> ./public/style.css
// GET /static/images/pic.jpg -> ./public/images/pic.jpg

// 单个静态文件
router.staticFile("/favicon.ico", "./public/favicon.ico")
// GET /favicon.ico -> ./public/favicon.ico
```

---

## 七、路由调试

使用 `dump()` 方法输出路由树结构，用于调试：

```cangjie
main(): Int64 {
    let joy = Joy.default()

    // 注册路由...

    // 输出路由树
    println(joy.router.dump())

    joy.run("127.0.0.1", 18881)
    return 0
}
```

输出示例：
```
0,type:static,prefix:,label:,tail:,numEdges:2,isLeaf:false
  1,type:static,prefix:/api,label:/,tail:/,numEdges:1,isLeaf:false
    2,type:static,prefix:/v1,label:v,tail:/,numEdges:1,isLeaf:false
      3,type:static,prefix:/users,label:u,tail:/,numEdges:2,isLeaf:true
        4,type:param,prefix:,label:{,tail:/,numEdges:1,isLeaf:false
```

---

## 八、参数获取

通过 `JoyContext` 获取路由参数：

```cangjie
router.get("/users/{id}/posts/{postId}", {ctx: JoyContext =>
    let id = ctx.getParam("id") ?? "unknown"
    let postId = ctx.getParam("postId") ?? "unknown"

    ctx.string("User: ${id}, Post: ${postId}")
})

// GET /users/123/posts/456
// 响应: User: 123, Post: 456
```

参数不存在时返回 `None`。

---

## 九、完整示例

```cangjie
import std.collection.*
import stdx.net.http.HttpStatusCode
import cjoy.*
import cjoy.json.*
import cjoy.middleware.*

@Json
class User {
    var id: String = ""
    var name: String = ""
}

class UserHandler {
    let users: HashMap<String, User> = HashMap()

    public func list(ctx: JoyContext): Unit {
        ctx.json(users.values().toArray())
    }

    public func get(ctx: JoyContext): Unit {
        let id = ctx.getParam("id") ?? ""
        match (users.get(id)) {
            case Some(user) => ctx.json(user)
            case _ => ctx.status(HttpStatusCode.STATUS_NOT_FOUND)
        }
    }

    public func create(ctx: JoyContext): Unit {
        if (let Some(user) <- ctx.bindJsonBody<User>()) {
            users.add(user.id, user)
            ctx.status(HttpStatusCode.STATUS_CREATED)
        } else {
            ctx.status(HttpStatusCode.STATUS_BAD_REQUEST)
        }
    }

    public func delete(ctx: JoyContext): Unit {
        let id = ctx.getParam("id") ?? ""
        users.remove(id)
        ctx.status(HttpStatusCode.STATUS_NO_CONTENT)
    }
}

main(): Int64 {
    let joy = Joy.default()
    let router = joy.router

    // 全局中间件
    router.use(AccessLog())
    router.use(ExceptionHandler())

    // API 分组
    let api = router.group("/api")
    api.use(Cors())

    // 用户路由
    let users = api.group("/v1/users")
    let handler = UserHandler()

    users.get("/", handler.list)                    // GET /api/v1/users/
    users.get("/{id:[0-9]+}", handler.get)       // GET /api/v1/users/123
    users.post("/", handler.create)                 // POST /api/v1/users/
    users.delete("/{id:[0-9]+}", handler.delete) // DELETE /api/v1/users/123

    // 静态文件
    router.staticFs("/static", "./public")

    joy.run("127.0.0.1", 18881)
    return 0
}
```

---

## 注意事项

1. **通配符位置**：`*` 通配符必须是路由模式的最后一个元素，不能出现在中间或开头

2. **参数命名冲突**：同一路由中不能使用重复的参数名，如 `/users/{id}/{id}` 会抛出异常

3. **正则表达式锚点**：正则路由会自动添加 `^` 和 `$`，不需要手动指定

4. **路径分隔符**：路径必须以 `/` 开头（根路径除外），否则会抛出异常

5. **分组前缀**：分组路径以 `/` 结尾时，注册的子路由不需要再加 `/`，建议统一去掉 `/` 结尾

6. **中间件顺序**：`use()` 的中间件按注册顺序执行，`apply()` 的中间件只对单个路由生效

7. **路由冲突**：如果两个路由模式完全相同但 HTTP 方法不同，会同时存在；如果模式和方法都相同，后注册的会覆盖先注册的

8. **路径大小写**：默认路径大小写敏感，可通过 `JoyConfig.caseInsensitive` 配置关闭

9. **参数不存在**：`getParam()` 在参数不存在时返回 `None`，建议使用 `??` 提供默认值

10. **默认 Handler**：分组创建时会自动注册默认 Handler，如果需要拦截所有请求，可以显式覆盖

---
<< [返回](../../README.md#使用指导)
