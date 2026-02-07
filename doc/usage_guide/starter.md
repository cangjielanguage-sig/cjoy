# 服务启动

---

## 概述

CJoy 使用 `Joy` 类来创建和启动 HTTP 服务器。`Joy` 类封装了底层 Cangjie SDK 的 `Server`，提供了更简洁的 API 和默认配置。

核心类：`Joy`，参见 [engine.cj](../../src/framework/engine.cj)

---

## 一、基本启动

使用默认配置创建并启动服务实例：

```cangjie
import cjoy.Joy

main(): Int64 {
    // 创建 Joy 实例
    let joy = Joy.default()
    // 运行并绑定在指定 IP 与 Port
    joy.run("127.0.0.1", 8080)
    return 0
}
```

---

## 二、JoyConfig 配置

`JoyConfig` 结构体提供对服务实例一些个性化配置参数：

### 2.1 配置选项

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `remoteIPHeaders` | `Array<String>` | `[]` | 设置信任的获取远程 IP 的头域名，如 `X-Forwarded-For`。注意：头域通常可以伪造，需要结合前端 Nginx 这类配置一起审视 |
| `caseInsensitive` | `Bool` | `false` | 是否对路径的 path 大小写不敏感 |
| `escapeAddedRoutes` | `Bool` | `false` | 是否在添加路由时，对 path 进行转义处理 |
| `notFoundHandler` | `JoyRequestHandler` | `JoyNotFoundHandler()` | 找不到路由的 Handler |
| `methodNotAllowedHandler` | `JoyRequestHandler` | `JoyMethodNotAllowedHandler()` | 方法不允许的 Handler |
| `maxRequestBodySize` | `Int` | `32 * 1024 * 1024` (32MB) | 最大请求体大小 |

### 2.2 使用配置

```cangjie
import cjoy.Joy
import cjoy.framework.JoyConfig

main(): Int64 {
    let cfg = JoyConfig(
        caseInsensitive: true,           // 路径大小写不敏感
        escapeAddedRoutes: true,        // 对路径进行转义处理
        maxRequestBodySize: 10 * 1024 * 1024  // 限制请求体为 10MB
    )
    let joy = Joy.create(cfg)
    joy.run("0.0.0.0", 8080)
    return 0
}
```

### 2.3 自定义 404 Handler

```cangjie
import cjoy.Joy
import cjoy.framework.{JoyConfig, JoyRequestHandler}

// 自定义 404 Handler
let notFoundHandler: JoyRequestHandler = {
    ctx: JoyContext =>
        ctx.status(404).json(@ToJson({
            "code": 404,
            "message": "资源未找到",
            "path": ctx.path
        }))
}

let methodNotAllowedHandler: JoyRequestHandler = {
    ctx: JoyContext =>
        ctx.status(405).json(@ToJson({
            "code": 405,
            "message": "方法不允许",
            "method": ctx.method,
            "allowed": ["GET", "POST"]
        }))
}

main(): Int64 {
    let cfg = JoyConfig(
        notFoundHandler: notFoundHandler,
        methodNotAllowedHandler: methodNotAllowedHandler
    )
    let joy = Joy.create(cfg)
    joy.run("127.0.0.1", 8080)
    return 0
}
```

---

## 三、创建 Joy 实例

### 3.1 default() - 默认实例

调用 `Joy.default()` 创建的实例，配置都采用默认值：

```cangjie
let joy = Joy.default()
```

### 3.2 create() - 指定配置

`Joy` 类提供 `create` 方法，支持创建多个不同配置的实例，启动绑定在不同的 IP 与 Port：

```cangjie
// 采用默认配置，创建名为 inst1 的实例
let joy1 = Joy.create(name: "inst1")

// 指定配置，创建名为 inst2 的实例
let cfg = JoyConfig(
    caseInsensitive: true,
    maxRequestBodySize: 50 * 1024 * 1024
)
let joy2 = Joy.create(cfg, name: "inst2")
```

**注意**：实例名称必须唯一，重复的名称会抛出 `IllegalArgumentException`。

---

## 四、启动服务

### 4.1 run() - HTTP 服务器

`Joy` 类提供 `run` 方法支持不同的启动方法，一旦调用 `run` 方法会阻塞当前线程：

```cangjie
// HTTP，绑定在 127.0.0.1:8080
joy.run("127.0.0.1", 8080)
```

### 4.2 run() - HTTPS 服务器

使用证书文件启动 HTTPS 服务器：

```cangjie
// HTTPS，绑定在 127.0.0.1:8443
let certPath = "./cert/server_cert.pem"
let keyPath = "./cert/server_key.pem"
joy.run("0.0.0.0", 8443, certFilePath: certPath, keyFilePath: keyPath)
```

### 4.3 run() - HTTP/2

使用 HTTP/2 协议：

```cangjie
// HTTP/2，绑定在 127.0.0.1:8443
let certPath = "./cert/server_cert.pem"
let keyPath = "./cert/server_key.pem"
joy.run("0.0.0.0", 8443,
    certFilePath: certPath,
    keyFilePath: keyPath,
    h2: true
)
```

### 4.4 run() - 自定义 ServerBuilder

直接使用官方 SDK 的 `ServerBuilder`，指定其参数：

```cangjie
import stdx.net.http.ServerBuilder

// 调用官方 SDK，创建 ServerBuilder，指定它的参数
let serverBuilder = ServerBuilder()
    .addr("0.0.0.0")
    .port(8443)
    .logger(joyLogger)
    .distributor(joyRouter.distributor)

joy.run(serverBuilder)
```

---

## 五、异步启动与优雅关闭

可以在其他线程中异步启动实例，在另一个线程主动关闭实例：

```cangjie
import cjoy.Joy
import std.sync.Mutex

var serverMutex = Mutex()

main(): Int64 {
    let joy = Joy.default()

    // 注册路由
    joy.router.get("/", {ctx => ctx.string("Hello!")})

    // 在其他线程中异步启动
    spawn {
        joy.run("127.0.0.1", 8080)
    }

    // 模拟运行一段时间后关闭
    // 在实际应用中可能通过信号处理来触发关闭
    // 这里仅作演示
}

// 可以在信号处理或管理接口中调用
func shutdownServer(joy: Joy): Unit {
    synchronized(serverMutex) {
        // gracefully 表示是否优雅关闭退出
        joy.shutdown(gracefully: true)
    }
}
```

---

## 六、服务注册

Joy 实例提供服务注册功能，可以在多个 Joy 实例之间共享服务：

### 6.1 addService - 添加服务

```cangjie
import cjoy.Joy

main(): Int64 {
    let joy = Joy.default()

    // 添加服务
    joy.addService("database", DatabaseConnection())
    joy.addService("cache", RedisClient())

    joy.run("127.0.0.1", 8080)
    return 0
}
```

### 6.2 getService - 获取服务

```cangjie
@Get[path = "/api/data"]
func handleData(ctx: JoyContext): Unit {
    // 从服务容器获取服务
    if (let Some(db) <- ctx.getService<Database>("database")) {
        let data = db.query("SELECT * FROM users")
        ctx.json(data)
    } else {
        ctx.status(500).string("数据库服务未找到")
    }
}
```

---

## 七、完整示例

### 7.1 基本 HTTP 服务器

```cangjie
import cjoy.Joy
import cjoy.json.macros.*

@JoyCreateLogger("starter")

main(): Int64 {
    let joy = Joy.default()

    joy.router.get("/", {ctx: JoyContext =>
        @JoyLogInfo("访问首页")
        ctx.html("""
            <!DOCTYPE html>
            <html>
            <head><title>CJoy 欢迎页面</title></head>
            <body>
                <h1>欢迎使用 CJoy!</h1>
                <p>一个基于仓颉的 Web 框架</p>
            </body>
            </html>
        """)
    })

    joy.router.get("/api/info", {ctx: JoyContext =>
        @JoyLogInfo("获取 API 信息")
        ctx.json(@ToJson({
            "name": "CJoy",
            "version": "0.1.0",
            "description": "仓颉 Web 框架"
        }))
    })

    @JoyLogInfo("服务启动在 127.0.0.1:8080")
    joy.run("127.0.0.1", 8080)
    return 0
}
```

### 7.2 HTTPS 服务器

```cangjie
import cjoy.Joy
import cjoy.json.macros.*

main(): Int64 {
    let cfg = JoyConfig(
        maxRequestBodySize: 10 * 1024 * 1024  // 限制请求体为 10MB
    )
    let joy = Joy.create(cfg)

    joy.router.get("/", {ctx: JoyContext =>
        ctx.html("<h1>安全连接</h1><p>当前连接是 HTTPS</p>")
    })

    // HTTPS 证书文件
    let certPath = "./cert/server_cert.pem"
    let keyPath = "./cert/server_key.pem"

    @JoyLogInfo("HTTPS 服务启动在 0.0.0.0:8443")
    joy.run("0.0.0.0", 8443,
        certFilePath: certPath,
        keyFilePath: keyPath)
    return 0
}
```

### 7.3 多实例示例

```cangjie
import cjoy.Joy
import cjoy.json.macros.*

@JoyCreateLogger("multi_instance")

main(): Int64 {
    // 创建多个不同配置的实例

    // 实例 1：HTTP 服务器，端口 8080
    let joy1 = Joy.create(name: "http-server")
    joy1.router.get("/", {ctx => ctx.string("HTTP Server")})
    spawn {
        @JoyLogInfo("HTTP 服务启动在 127.0.0.1:8080")
        joy1.run("127.0.0.1", 8080)
    }

    // 实例 2：API 服务器，端口 8081
    let cfg2 = JoyConfig(
        caseInsensitive: true
    )
    let joy2 = Joy.create(cfg2, name: "api-server")
    joy2.router.get("/api/data", {ctx => ctx.string("API Server")})
    spawn {
        @JoyLogInfo("API 服务启动在 127.0.0.1:8081")
        joy2.run("127.0.0.1", 8081)
    }

    // 主线程等待（实际应用中可以使用信号处理）
    while (true) {
        sleep(Duration.second * 60)
    }

    return 0
}
```

---

## 八、注意事项

1. **阻塞启动**：`run` 方法会阻塞当前线程，直到服务器关闭

2. **实例名称**：使用 `create` 方法时，实例名称必须唯一

3. **路由注册**：必须在调用 `run` 之前完成所有路由注册

4. **服务共享**：使用 `addService` 添加的服务可以在不同实例间共享（通过 ServiceContainer.GLOBAL）

5. **优雅关闭**：使用 `shutdown(true)` 进行优雅关闭，等待当前请求完成

6. **请求大小限制**：默认限制为 32MB，可根据需要调整 `maxRequestBodySize`

---
<< [返回](../../README.md#使用指导)
