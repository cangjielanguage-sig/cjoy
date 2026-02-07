# CORS 中间件

CORS (Cross-Origin Resource Sharing) 中间件用于处理跨源资源共享，允许浏览器从不同的域、协议或端口访问服务器资源。

## 基本用法

### 允许所有跨域请求

使用 `Cors.allowAll()` 快捷方法创建一个允许所有跨域请求的配置：

```cangjie
import cjoy.middleware.Cors

main(): Int64 {
    let joy = Joy.default()
    joy.router.use(Cors.allowAll())
    // ... 注册路由
    joy.run("127.0.0.1", 8080)
    return 0
}
```

### 自定义 CORS 配置

创建 `Cors` 实例来自定义跨域策略：

```cangjie
// 允许指定来源
let cors = Cors(allowedOrigins: ["https://example.com", "https://app.example.com"])
joy.router.use(cors)

// 允许通配符匹配（性能略低）
let cors = Cors(allowedOrigins: ["https://*.example.com"])
joy.router.use(cors)
```

## 配置选项

### 构造函数参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `allowedOrigins` | `Array<String>` | `[]` (允许所有) | 允许的源列表，`*` 表示允许所有，支持通配符 |
| `allowOriginFunc` | `?AllowOriginFunc` | `None` | 自定义源验证函数，设置后将忽略 `allowedOrigins` |
| `allowedMethods` | `Array<String>` | `["GET", "POST", "HEAD"]` | 允许的 HTTP 方法 |
| `allowedHeaders` | `Array<String>` | `["Origin", "Accept", "Content-Type"]` | 允许的请求头 |
| `exposedHeaders` | `Array<String>` | `[]` | 允许暴露给客户端的响应头 |
| `allowCredentials` | `Bool` | `false` | 是否允许携带凭据（cookies、HTTP认证等） |
| `maxAge` | `Int` | `0` | 预检请求缓存时间（秒） |
| `optionsPassthrough` | `Bool` | `false` | 是否允许其他处理器处理 OPTIONS 请求 |

### 允许的 HTTP 方法

```cangjie
let cors = Cors(
    allowedOrigins: ["https://example.com"],
    allowedMethods: ["GET", "POST", "PUT", "DELETE", "PATCH"]
)
```

### 允许的请求头

```cangjie
let cors = Cors(
    allowedOrigins: ["https://example.com"],
    allowedHeaders: ["Content-Type", "Authorization", "X-Requested-With"]
)

// 允许所有请求头
let cors = Cors(
    allowedOrigins: ["https://example.com"],
    allowedHeaders: ["*"]
)
```

### 暴露响应头

```cangjie
let cors = Cors(
    allowedOrigins: ["https://example.com"],
    exposedHeaders: ["X-Total-Count", "X-Custom-Header"]
)
```

### 允许凭据

当需要携带 cookies 或 HTTP 认证时使用：

```cangjie
let cors = Cors(
    allowedOrigins: ["https://example.com"],
    allowCredentials: true
)
```

**注意**：当设置 `allowCredentials: true` 时，`allowedOrigins` 不能设置为 `["*"]`。

### 预检请求缓存

设置预检请求（OPTIONS）的缓存时间：

```cangjie
let cors = Cors(
    allowedOrigins: ["https://example.com"],
    maxAge: 3600  // 缓存 1 小时
)
```

### OPTIONS 请求透传

当应用需要自己处理 OPTIONS 请求时：

```cangjie
let cors: Cors = Cors(
    allowedOrigins: ["https://example.com"],
    optionsPassthrough: true
)

// 需要自己注册 OPTIONS 处理器
joy.router.options("/api", {ctx => ctx.ok("OK")})
```

## 自定义源验证

使用 `allowOriginFunc` 实现自定义的源验证逻辑：

```cangjie
import cjoy.middleware.{Cors, AllowOriginFunc}

let cors = Cors(allowOriginFunc: {ctx: JoyContext, origin: String =>
    // 根据数据库或配置验证源
    origin.startsWith("https://") && origin.endsWith(".example.com")
})
joy.router.use(cors)
```

## 完整示例

```cangjie
import cjoy.Joy
import cjoy.middleware.Cors

main(): Int64 {
    let joy = Joy.default()

    // 配置 CORS
    let cors = Cors(
        allowedOrigins: ["https://example.com", "https://app.example.com", "http://localhost:3000"],
        allowedMethods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
        allowedHeaders: ["Content-Type", "Authorization", "X-Requested-With"],
        exposedHeaders: ["X-Total-Count"],
        allowCredentials: true,
        maxAge: 3600
    )

    joy.router.use(cors)

    joy.router.get("/api/data", {ctx: JoyContext =>
        ctx.json([("message", "Hello from CORS")])
    })

    joy.run("127.0.0.1", 8080)
    return 0
}
```

## 局部应用

将 CORS 中间件应用到特定路由组：

```cangjie
// 只对 /api 下的路由应用 CORS
joy.router
    .group("/api")
    .use(Cors(allowedOrigins: ["https://example.com"]))
    .get("/data", {ctx => ctx.json([("key", "value")])})

// 只对单个路由应用 CORS
joy.router
    .apply(Cors(allowedOrigins: ["https://example.com"]))
    .get("/public/data", {ctx => ctx.json([("key", "value")])})
```

## CORS 原理

CORS 涉及两种请求类型：

1. **简单请求**：直接发送请求，服务器在响应中添加 CORS 头
2. **预检请求 (Preflight)**：浏览器先发送 OPTIONS 请求，确认服务器允许跨域后再发送实际请求

### CORS 响应头

| 响应头 | 说明 |
|--------|------|
| `Access-Control-Allow-Origin` | 允许的源 |
| `Access-Control-Allow-Methods` | 允许的 HTTP 方法 |
| `Access-Control-Allow-Headers` | 允许的请求头 |
| `Access-Control-Expose-Headers` | 可暴露给客户端的响应头 |
| `Access-Control-Allow-Credentials` | 是否允许凭据 |
| `Access-Control-Max-Age` | 预检请求缓存时间 |

----
<< [返回](../../README.md#使用指导)
