# 服务启动

---

## 概述

CJoy 提供两种服务启动方式：

1. **JoyBoot（推荐）**：应用引导器，支持配置文件加载、TLS/HTTP2 配置、生命周期回调等完整功能
2. **Joy**：底层引擎类，提供直接创建和启动 HTTP 服务器的简洁 API

对于生产环境应用，推荐使用 `JoyBoot`，因为它提供了更完整的配置管理能力。

核心类：
- `JoyBoot`：应用引导器，参见 [boot_api.cj](../../src/boot/boot_api.cj)
- `Joy`：HTTP 服务器引擎，参见 [engine.cj](../../src/framework/engine.cj)

---

## 一、使用 JoyBoot 启动（推荐）

`JoyBoot` 是 CJoy 的应用引导器，负责：
1. 加载配置文件（命令行参数、properties、json）
2. 初始化框架配置
3. 创建 Joy 引擎实例
4. 注册宏生成的中间件和路由处理器
5. 构建并启动 HTTP 服务器

### 1.1 基本使用

```cangjie
import cjoy.boot.JoyBoot

main(args: Array<String>): Int64 {
    JoyBoot.of(args).run()
    return 0
}
```

### 1.2 配置文件路径

默认配置文件根目录为 `./config`，可以通过 `cfgPath` 方法指定：

```cangjie
import cjoy.boot.JoyBoot

main(args: Array<String>): Int64 {
    JoyBoot.of(args)
        .cfgPath("./myconfig")
        .run()
    return 0
}
```

### 1.3 生命周期回调

`JoyBoot` 提供多个生命周期回调：

| 方法 | 参数 | 说明 | 调用时机 |
|------|------|------|-----------|
| `extendConfig` | `(config: Config, cfgRootPath: String) -> Unit` | 扩展配置 | 配置文件加载后 |
| `beforeJoyStart` | `(cfg: JoyConfig, joy: Joy) -> Unit` | 初始化前 | Joy 实例创建后 |
| `afterBind` | `() -> Unit` | 绑定成功后 | 服务器绑定端口后 |
| `onShutdown` | `() -> Unit` | 关闭前 | 服务器关闭前 |

#### 扩展配置回调

```cangjie
import cjoy.boot.JoyBoot
import cjoy.config.Config

main(args: Array<String>): Int64 {
    JoyBoot.of(args)
        .extendConfig { config, cfgRootPath =>
            // 可以添加自定义配置加载器
            let env = config.getValue("APP_ENV", "dev")
            println("Running in ${env} mode, config root: ${cfgRootPath}")
        }
        .run()
    return 0
}
```

#### 初始化前回调

```cangjie
import cjoy.boot.JoyBoot
import cjoy.framework.JoyConfig

main(args: Array<String>): Int64 {
    JoyBoot.of(args)
        .beforeJoyStart { cfg, joy =>
            // 可以在服务器启动前进行自定义配置
            joy.router.get("/health", { ctx =>
                ctx.status(200).string("OK")
            })
        }
        .run()
    return 0
}
```

#### 完整示例

```cangjie
import cjoy.boot.JoyBoot
import cjoy.config.Config
import cjoy.framework.JoyConfig

main(args: Array<String>): Int64 {
    JoyBoot.of(args)
        .cfgPath("./config")
        .{
            config: Config, cfgRootPath: String =>
            println("Loading config from ${cfgRootPath}")
        }
        .beforeJoyStart { cfg, joy =>
            println("Server starting...")
            joy.router.get("/", { ctx => ctx.string("Hello CJoy!") })
        }
        .afterBind {
            println("Server started and listening")
        }
        .onShutdown {
            println("Server shutting down...")
        }
        .run()
    return 0
}
```

---

## 二、配置文件

JoyBoot 支持通过配置文件（properties 或 json 格式）来自定义应用配置。

### 2.1 配置文件位置

配置文件默认从以下位置查找（按优先级从高到低）：

| 文件类型 | 位置1（高优先级） | 位置2（低优先级） |
|----------|---------------------|---------------------|
| Properties | `{cfgPath}/config/joy.properties` | `{cfgPath}/joy.properties` |
| Json | `{cfgPath}/config/joy.json` | `{cfgPath}/joy.json` |

支持通过 `joy.profile` 配置项指定环境配置文件名，如 `dev` 环境会查找 `joy-dev.properties`。

### 2.2 Properties 配置示例

```properties
# 应用名称
joy.name=myapp

# 服务器配置
joy.server.address=0.0.0.0
joy.server.port=8080

# HTTP 配置
joy.server.http.caseInsensitive=true
joy.server.http.escapeAddedRoutes=true
joy.server.http.remoteIpHeaders=X-Forwarded-For,X-Real-IP
joy.server.http.maxRequestBodySize=33554432
joy.server.http.maxRequestHeaderSize=8192
joy.server.http.readHeaderTimeout=5000
joy.server.http.readTimeout=30000
joy.server.http.writeTimeout=30000

# HTTP/2 配置
joy.server.http.h2.enabled=true
joy.server.http.h2.enableConnectProtocol=false
joy.server.http.h2.headerTableSize=4096
joy.server.http.h2.initialWindowSize=65535
joy.server.http.h2.maxConcurrentStreams=100
joy.server.http.h2.maxFrameSize=16384
joy.server.http.h2.maxHeaderListSize=4294967295

# TLS 配置
joy.server.tls.enabled=true
joy.server.tls.version=1.3
joy.server.tls.ciphers=
joy.server.tls.clientAuth=false
joy.server.tls.keyPassword=
joy.server.tls.keyFile=./cert/server_key.pem
joy.server.tls.certFile=./cert/server_cert.pem
joy.server.tls.trustFile=
joy.server.tls.trustAll=false

# 线程池配置
joy.server.pool.capacity=10000
joy.server.pool.queueCapacity=10000
joy.server.pool.preheat=0
```

### 2.3 Json 配置示例

```json
{
  "joy": {
    "name": "myapp",
    "server": {
      "address": "0.0.0.0",
      "port": 8080,
      "http": {
        "caseInsensitive": true,
        "escapeAddedRoutes": true,
        "remoteIpHeaders": "X-Forwarded-For,X-Real-IP",
        "maxRequestBodySize": 33554432,
        "maxRequestHeaderSize": 8192,
        "readHeaderTimeout": 5000,
        "readTimeout": 30000,
        "writeTimeout": 30000,
        "h2": {
          "enabled": true,
          "enableConnectProtocol": false,
          "headerTableSize": 4096,
          "initialWindowSize": 65535,
          "maxConcurrentStreams": 100,
          "maxFrameSize": 16384,
          "maxHeaderListSize": 4294967295
        }
      },
      "tls": {
        "enabled": true,
        "version": "1.3",
        "ciphers": "",
        "clientAuth": false,
        "keyPassword": "",
        "keyFile": "./cert/server_key.pem",
        "certFile": "./cert/server_cert.pem",
        "trustFile": "",
        "trustAll": false
      },
      "pool": {
        "capacity": 10000,
        "queueCapacity": 10000,
        "preheat": 0
      }
    }
  }
}
```

### 2.4 配置项说明

#### 顶层配置

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `joy.name` | String | "default" | 应用名称，用于创建 Joy 实例 |

#### 服务器配置 (server)

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `joy.server.address` | String | "127.0.0.1" | 服务器监听地址 |
| `joy.server.port` | UInt16 | 18880 | 服务器监听端口 |

#### HTTP 配置 (server.http)

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `joy.server.http.caseInsensitive` | Bool | false | 路由匹配是否大小写不敏感 |
| `joy.server.http.escapeAddedRoutes` | Bool | false | 是否对添加的路由路径进行转义 |
| `joy.server.http.remoteIpHeaders` | String | "" | 获取真实客户端 IP 的请求头，逗号分隔 |
| `joy.server.http.maxRequestBodySize` | Int64 | 32MB | 最大请求体大小（字节） |
| `joy.server.http.maxRequestHeaderSize` | Int64 | 0 | 最大请求头大小（字节） |
| `joy.server.http.readHeaderTimeout` | Int64 | 0 | 读取请求头超时（毫秒） |
| `joy.server.http.readTimeout` | Int64 | 0 | 读取请求体超时（毫秒） |
| `joy.server.http.writeTimeout` | Int64 | 0 | 写入响应超时（毫秒） |

#### HTTP/2 配置 (server.http.h2)

| 配置项 | 类型 | 默认值 | 说明 |
| | | |
|--------|------|--------|------|
| `joy.server.http.h2.enabled` | Bool | false | 是否启用 HTTP/2（需同时启用 TLS） |
| `joy.server.http.h2.enableConnectProtocol` | Bool | false | 是否启用 CONNECT 协议 |
| `joy.server.http.h2.headerTableSize` | UInt32 | 4096 | HPACK 头表大小 |
| `joy.server.http.h2.initialWindowSize` | UInt32 | 0 | 初始窗口大小 |
| `joy.server.http.h2.maxConcurrentStreams` | UInt32 | 100 | 最大并发流数 |
| `joy.server.http.h2.maxFrameSize` | UInt32 | 16384 | 最大帧大小 |
| `joy.server.http.h2.maxHeaderListSize` | UInt32 | UInt32.Max | 最大头列表大小 |

#### TLS 配置 (server.tls)

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `joy.server.tls.enabled` | Bool | false | 是否启用 TLS（HTTPS） |
| `joy.server.tls.version` | String | "" | TLS 版本，支持 "1.2" 或 "1.3" |
| `joy.server.tls.ciphers` | String | "" | | 加密套件列表，逗号分隔 |
| `joy.server.tls.clientAuth` | Bool | false | 是否启用客户端认证 |
| `joy.server.tls.keyPassword` | String | "" | 私钥文件密码 |
| `joy.server.tls.keyFile` | String | "" | 私钥文件路径 |
| `joy.server.tls.certFile` | String | "" | 证书文件路径 |
| `joy.server.tls.trustFile` | String | "" | 信任证书文件路径 |
| `joy.server.tls.trustAll` | Bool | false | 是否信任所有客户端证书（不安全） |

#### 线程池配置 (server.pool)

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `joy.server.pool.capacity` | Int64 | 10000 | 线程池容量 |
| `joy.server.pool.queueCapacity` | Int64 | 10000 | 任务队列容量 |
| `joy.server.pool.preheat` | Int64 | 0 | 预热线程数 |

---

## 三、使用 Joy 直接启动

当需要更细粒度控制或快速启动时，可以直接使用 `Joy` 类。

### 3.1 JoyConfig 配置

`JoyConfig` 结构体提供对服务实例一些个性化配置参数：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `remoteIPHeaders` | `Array<String>` | `[]` | 设置信任的获取远程 IP 的头域名，如 `X-Forwarded-For`。注意：头域通常可以伪造，需要结合前端 Nginx 这类配置一起审视 |
| `caseInsensitive` | `Bool` | `false` | 是否对路径的 path 大小写不敏感 |
| `escapeAddedRoutes` | `Bool` | `false` | 是否在添加路由时，对 path 进行转义处理 |
| `notFoundHandler` | `JoyRequestHandler` | `JoyNotFoundHandler()` | 找不到路由的 Handler |
| `methodNotAllowedHandler` | `JoyRequestHandler` | `JoyMethodNotAllowedHandler()` | 方法不允许的 Handler |
| `maxRequestBodySize` | `Int` | `32 * 1024 * 1024` (32MB) | 最大请求体大小 |

### 3.2 使用配置

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

### 3.3 自定义 404 Handler

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

## 四、创建 Joy 实例

### 4.1 default() - 默认实例

调用 `Joy.default()` 创建的实例，配置都采用默认值：

```cangjie
let joy = Joy.default()
```

### 4.2 create() - 指定配置

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

## 五、启动服务

### 5.1 run() - HTTP 服务器

`Joy` 类提供 `run` 方法支持不同的启动方法，一旦调用 `run` 方法会阻塞当前线程：

```cangjie
// HTTP，绑定在 127.0.0.1:8080
joy.run("127.0.0.1", 8080)
```

### 5.2 run() - HTTPS 服务器

使用证书文件启动 HTTPS 服务器：

```cangjie
// HTTPS，绑定在 127.0.0.1:8443
let certPath = "./cert/server_cert.pem"
let keyPath = "./cert/server_key.pem"
joy.run("0.0.0.0", 8443, certFilePath: certPath, keyFilePath: keyPath)
```

### 5.3 run() - HTTP/2

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

### 5.4 run() - 自定义 ServerBuilder

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

## 六、异步启动与优雅关闭

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

## 七、服务注册

Joy 实例提供服务注册功能，可以在多个 Joy 实例之间共享服务：

### 7.1 addService - 添加服务

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

### 7.2 getService - 获取服务

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

## 八、完整示例

### 8.1 使用 JoyBoot 的 HTTP 服务器

```cangjie
import cjoy.boot.JoyBoot
import cjoy.json.macros.*

@JoyCreateLogger("starter")

@Get[path = "/api/info"]
func handleApiInfo(ctx: JoyContext): Unit {
    @JoyLogInfo("获取 API 信息")
    ctx.json(@ToJson({
        "name": "CJoy",
        "version": "0.1.0",
        "description": "仓颉 Web 框架"
    }))
}

main(): Int64 {
    JoyBoot.of(args)
        .cfgPath("./config")
        .beforeJoyStart { cfg, joy =>
            // 注册路由
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
        }
        .run()
    return 0
}
```

### 8.2 使用 JoyBoot 的 HTTPS 服务器

```cangjie
import cjoy.boot.JoyBoot

main(): Int64 {
    JoyBoot.of(args)
        .cfgPath("./config")
        .run()
    return 0
}
```

配置文件 `./config/joy.properties`：

```properties
joy.server.address=0.0.0.0
joy.server.port=8443
joy.server.tls.enabled=true
joy.server.tls.certFile=./cert/server_cert.pem
joy.server.tls.keyFile=./cert/server_key.pem
```

### 8.3 使用 Joy 的多实例示例

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

## 九、注意事项

1. **阻塞启动**：`run` 方法会阻塞当前线程，直到服务器关闭

2. **实例名称**：使用 `create` 方法时，实例名称必须唯一

3. **路由注册**：必须在调用 `run` 之前完成所有路由注册

4. **服务共享**：使用 `addService` 添加的服务可以在不同实例间共享（通过 ServiceContainer.GLOBAL）

5. **优雅关闭**：使用 `shutdown(true)` 进行优雅关闭，等待当前请求完成

6. **请求大小限制**：默认限制为 32MB，可根据需要调整 `maxRequestBodySize`

7. **配置优先级**：命令行参数 > Properties/Json 文件，同名键会被覆盖

8. **HTTP/2 要求**：启用 HTTP/2 必须同时启用 TLS 并指定证书文件

9. **配置文件查找**：配置文件会从 `{cfgPath}/config/` 和 `{cfgPath}/` 两个位置查找

---
<< [返回](../../README.md#使用指导)
