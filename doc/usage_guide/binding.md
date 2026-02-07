# 参数绑定

CJoy 提供了灵活的参数绑定机制，支持从 Query、Form、Header 等来源自动将参数绑定到类或结构体。

## 概述

通过 `@Bind` 宏标记，可以在类或结构体中声明字段映射。绑定时会自动从指定源获取值并进行类型转换。

- 与 `@Valid` 宏结合使用，实现绑定 + 校验
- 支持多种数据源：Query、Form、Header、自定义 Map
- 自动类型转换：字符串到各种目标类型
- 支持默认值

## JoyBindSource 接口

`JoyBindSource` 是数据源接口，用于从不同位置获取参数值，下面是一些内置实现扩展：

| 实现类 | 说明 | 支持类型 |
|----------|------|----------|
| `MapContainer` | 基于 HashMap 的数据源 | 任意类型 |
| `Form` | HTTP Form 表单数据 | `String`、`Collection` |
| `HttpHeaders` | HTTP Headers 数据 | `String`、`Collection` |
| `HashMap<String, String>` | 简化的 HashMap 数据源 | `String` |

### MapContainer

使用 Map 作为数据源：

```cangjie
import cjoy.bind.MapContainer
import std.collection.HashMap

let data = HashMap<String, Any>()
data.add("name", "张三")
data.add("age", 25)

let container = MapContainer(data)
```

## JoyBindable 接口

`JoyBindable` 是可绑定类型的接口，支持类型绑定和默认值。

### 支持的类型

| 类型 | 说明 |
|------|------|
| `String` | 字符串 |
| `Int8` | 有符号 8 位整数 |
| `Int16` | 有符号 16 位整数 |
| `Int32` | 有符号 32 位整数 |
| `Int64` | 有符号 64 位整数 |
| `UInt8` | 无符号 8 位整数 |
| `UInt16` | 无符号 16 位整数 |
| `UInt32` | 无符号 32 位整数 |
| `UInt64` | 无符号 64 位整数 |
| `Float16` | 16 位浮点数 |
| `Float32` | 32 位浮点数 |
| `Float64` | 64 位浮点数 |
| `Bool` | 布尔值 |
| `DateTime` | 日期时间 |
| `Array<T>` | 数组 |
| `ArrayList<T>` | 数组列表 |
| `Option<T>` | 可选值（嵌套绑定需要元素也实现 `JoyBindable`） |

## @Bind 宏

使用 `@Bind` 宏标记字段映射：

```cangjie
import cjoy.bind.*

@Bind
public struct UserQuery {
    @BindField[name = "username"]
    var username: String = ""

    @BindField[name = "age", default = 18]
    var age: Int32 = 0

    @BindField[name = "tags", default = ""]
    var tags: Array<String> = []
}
```

### @BindField 参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `name` | `String` | 字段名，不指定则使用变量名 | 映射到源中的键名 |
| `default` | `String` | `""` | 默认值，字符串形式 |
| `timeformat` | `String` | 无 | DateTime 格式字符串，如 `"yyyy-MM-dd HH:mm:ss"` |

## JoyContext 绑定方法

`JoyContext` 提供了多个便捷的绑定方法：

### bindQuery - 绑定 Query 参数

从 URL 查询参数绑定：

```cangjie
@Bind
public struct SearchQuery {
    @BindField[name = "keyword"]
    var keyword: String = ""

    @BindField[name = "page", default = 1]
    var page: Int32 = 1

    @BindField[name = "size", default = 20]
    var size: Int32 = 20
}

@Get[path = "/search"]
func search(ctx: JoyContext): Unit {
    if (let Some(query) <- ctx.bindQuery<SearchQuery>()) {
        ctx.json(@ToJson({
            "keyword": query.keyword,
            "page": query.page,
            "size": query.size
        }))
    }
}
```

请求：`GET /search?keyword=cjoy&page=2&size=10`

### bindPostForm - 绑定 Form 参数

从 POST 表单数据绑定：

```cangjie
@Bind
public struct LoginForm {
    @BindField[name = "username"]
    var username: String = ""

    @BindField[name = "password"]
    var password: String = ""
}

@Post[path = "/login"]
func login(ctx: JoyContext): Unit {
    if (let Some(form) <- ctx.bindPostForm<LoginForm>()) {
        ctx.json(@ToJson({
            "username": form.username,
            "password": form.password
        }))
    }
}
```

### bindHeader - 绑定 Header 参数

从 HTTP Header 绑定：

```cangjie
@Bind
public struct HeaderForm {
    @BindField[name = "X-Request-Id"]
    var requestId: String = ""

    @BindField[name = "User-Agent", default = "unknown"]
    var userAgent: String = "unknown"
}

@Get[path = "/info"]
func info(ctx: JoyContext): Unit {
    if (let Some(headers) <- ctx.bindHeader<HeaderForm>()) {
        ctx.json(@ToJson({
            "requestId": headers.requestId,
            "userAgent": headers.userAgent
        }))
    }
}
```

## 完整示例

### 查询参数绑定

```cangjie
import cjoy.Joy
import cjoy.bind.*
import cjoy.json.macros.*

@Bind
public struct PageQuery {
    @BindField[name = "page", default = 1]
    var page: Int32 = 1

    @BindField[name = "size", default = 20]
    var size: Int32 = 20

    @BindField[name = "sort", default = "id"]
    var sort: String = "id"
}

@Get[path = "/users"]
func listUsers(ctx: JoyContext): Unit {
    if (let Some(query) <- ctx.bindQuery<PageQuery>()) {
        @JoyLogInfo("查询参数: page=${query.page}, size=${query.size}, sort=${query.sort}")
        ctx.json(@ToJson({
            "page": query.page,
            "size": query.size,
            "sort": query.sort
        }))
    }
}
```

### 表单绑定

```cangjie
import cjoy.Joy
import cjoy.bind.*
import cjoy.json.macros.*

@Bind
public struct RegisterForm {
    @BindField[name = "username"]
    var username: String = ""

    @BindField[name = "email"]
    var email: String = ""

    @BindField[name = "password"]
    var password: String = ""

    @BindField[name = "confirm_password"]
    var confirmPassword: String = ""

    @BindField[name = "agree", default = false]
    var agree: Bool = false
}

@Post[path = "/register", produce = "json"]
func register(ctx: JoyContext): Unit {
    if (let Some(form) <- ctx.bindPostForm<RegisterForm>()) {
        // 处理注册逻辑
        ctx.json(@ToJson({
            "username": form.username,
            "email": form.email
        }))
    }
}
```

### 数组绑定

```cangjie
import cjoy.Joy
import cjoy.bind.*
import cjoy.json.macros.*

@Bind
public struct FilterQuery {
    @BindField[name = "ids", default = ""]
    var ids: Array<Int32> = []

    @BindField[name = "tags", default = ""]
    var tags: ArrayList<String> = ArrayList<String>()
}

@Get[path = "/filter"]
func filter(ctx: JoyContext): Unit {
    if (let Some(query) <- ctx.bindQuery<FilterQuery>()) {
        ctx.json(@ToJson({
            "ids": query.ids,
            "tags": query.tags
        }))
    }
}
```

请求：`GET /filter?ids=1,2,3&tags=a,b,c`

### DateTime 绑定

```cangjie
import cjoy.Joy
import cjoy.bind.*
import cjoy.json.macros.*

@Bind
public struct ScheduleQuery {
    @BindField[name = "start_date", timeformat = "yyyy-MM-dd HH:mm:ss"]
    var startDate: ?DateTime = None

    @BindField[name = "end_date", timeformat = "yyyy-MM-dd HH:mm:ss"]
    var endDate: ?DateTime = None
}

@Get[path = "/schedule"]
func schedule(ctx: JoyContext): Unit {
    if (let Some(query) <- ctx.bindQuery<ScheduleQuery>()) {
        ctx.json(@ToJson({
            "start": query.startDate,
            "end": query.endDate
        }))
    }
}
```

### 自定义数据源

```cangjie
import cjoy.Joy
import cjoy.bind.*
import cjoy.json.macros.*

// 自定义配置数据
let config = HashMap<String, Any>()
config.add("api_key", "secret")
config.add("api_version", "1.0")

@Bind
public struct ConfigForm {
    @BindField[name = "api_key"]
    var apiKey: String = ""

    @BindField[name = "api_version"]
    var apiVersion: String = ""
}

@Get[path = "/config"]
func getConfig(ctx: JoyContext): Unit {
    // 调用两个参数的 bind 方法
    if (let Some(cfg) <- ConfigForm.bind(MapContainer(config), "", None, None)) {
        ctx.json(@ToJson({
            "apiKey": cfg.apiKey,
            "apiVersion": cfg.apiVersion
        }))
    }
}
```

### 绑定 + 校验

结合 `@Bind` 和 `@Valid` 宏：

```cangjie
import cjoy.Joy
import cjoy.bind.*
import cjoy.validation.*
import cjoy.json.macros.*

@Bind
@Valid
public struct UserForm {
    @Length[min = 3, max = 20]
    @NotBlank
    var username: String = ""

    @Size[min = 6, max = 20]
    @NotBlank
    var password: String = ""
}

@Post[path = "/login", produce = "json"]
func login(ctx: JoyContext): Unit {
    if (let Some(form) <- ctx.bindPostForm<UserForm>()) {
        // 绑定成功，且校验通过
        ctx.json(@ToJson({
            "message": "登录成功"
        }))
    } else {
        // 绑定失败或校验失败
        ctx.status(400).json(@ToJson({
            "message": "请求参数错误"
        }))
    }
}
```

## 注意事项

1. **类型转换**：Bind 会自动将源数据转换为目标类型，失败时返回 `None`
2. **默认值**：可以通过 `default` 参数设置默认值
3. **DateTime 格式**：使用 `timeformat` 参数指定日期时间格式
4. **嵌套绑定**：`Array<T>` 和 `ArrayList<T>` 会尝试对每个元素进行绑定
5. **可选值**：`Option<T>` 支持可选值的绑定
6. **组合使用**：与 `@Valid` 宏结合使用实现完整的数据处理流程

----
<< [返回](../../README.md#使用指导)
