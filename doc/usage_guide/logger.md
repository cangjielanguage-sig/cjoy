# 日志

CJoy 内置日志工具 `JoyLoggerFactory`，用于创建 Logger 对象。默认情况下日志输出到 Console。

---

## 概述

CJoy 日志系统基于 [cjlog](https://gitcode.com/lanlingx/cjlog) 实现，默认调用 cjlog 提供的能力：

- **日志级别**：支持 DEBUG、INFO、WARN、ERROR 四种级别
- **日志宏**：通过 `@JoyCreateLogger`、`@JoyLogDebug` 等宏自动生成日志代码
- **格式统一**：自动添加时间、级别、线程、文件名、行号等信息
- **扩展接口**：支持自定义 Logger 实现，可适配其他日志框架
- **请求访问日志**：提供 `AccessLog` 中间件记录 HTTP 请求访问

核心类：
- `JoyLoggerFactory`：日志工厂类，参见 [logger.cj](../../src/log/logger.cj)
- `AccessLog`：访问日志中间件，参见 [access_log.cj](../../src/middleware/access_log.cj)

---

## 一、日志级别

CJoy 支持以下日志级别（按优先级从低到高）：

| 级别 | 说明 |
|-------|------|
| `DEBUG` | 调试信息，用于开发阶段 |
| `INFO` | 一般信息，记录程序正常运行状态 |
| `WARN` | 警告信息，表明潜在问题 |
| `ERROR` | 错误信息，记录错误事件 |

---

## 二、使用日志宏

CJoy 提供以下日志宏，建议应用优先采用宏打印日志：

| 宏 | 说明 |
|-----|------|
| `@JoyCreateLogger` | 创建日志对象 |
| `@JoyLogDebug` | 打印 DEBUG 级别日志 |
| `@JoyLogInfo` | 打印 INFO 级别日志 |
| `@JoyLogWarn` | 打印 WARN 级别日志 |
| `@JoyLogError` | 打印 ERROR 级别日志 |

### 2.1 基本用法

在 package 层创建 Logger，然后在同一 package 下的任何文件中使用日志宏：

```cangjie
// 在 package 的某个文件中创建 Logger
@JoyCreateLogger("myapp")

main(): Int64 {
    joy.run("127.0.0.1", 8080)
    return 0
}
```

```cangjie
// 在同一 package 下的其他文件中使用日志宏
@Get[path = "/api/data"]
func handleData(ctx: JoyContext): Unit {
    @JoyLogDebug("处理请求数据: ${ctx.path}")
    @JoyLogInfo("正常处理请求")
    @JoyLogWarn("发现潜在问题")
    @JoyLogError("发生错误")

    ctx.json([("data": "value")])
}
```

### 2.2 日志格式

日志宏自动添加以下信息：

- 当前时间（ISO 8601 格式）
- 日志级别
- 当前线程名或 ID
- 日志输出所在文件名
- 日志输出所在行号
- 日志输出所在 package 名

格式示例：

```
2026-02-27T22:21:33.154195185+08:00|1||INFO|engine.cj:69 >> create joy app default 
2026-02-27T22:21:33.154311283+08:00|1||INFO|route.cj:586 >> add route handler, path=/{name}, methods=[GET] 
2026-02-27T22:21:33.154358802+08:00|1||INFO|route.cj:586 >> add route handler, path=/abc, methods=[GET]
```

---

## 三、日志级别控制

CJoy 日志默认使用 [CJLog](https://gitcode.com/lanlingx/cjlog.git)，可以通过 cjlog 提供的 API 控制日志级别，更多的配置与使用介绍请参见 CJLog。

```cangjie
import cjoy.log.JoyLoggerFactory

main(): Int64 {
    // 创建 Logger（默认使用 cjlog）
    let logger = JoyLoggerFactory.createLogger("myapp")
    // 通过 cjlog 的 API 设置级别
    logger.level = LogLevel.DEBUG  // 设置为调试级别

    let joy = Joy.default()
    joy.run("127.0.0.1", 8080)
    return 0
}
```

---

## 四、扩展日志框架

可以将 CJoy 的日志输出适配到其他日志框架：

```cangjie
package myapp.log

import stdx.log.Logger
import stdx.log.{LogLevel, LogRecord, Attr}

// 自定义 Logger 实现
class MyLogger <: Logger {
    private var _level: LogLevel = LogLevel.INFO
    private let _name: String

    public init(name: String) {
        _name = name
    }

    public mut prop level: LogLevel {
        get() {
            _level
        }
        set(v) {
            _level = v
        }
    }

    public func withAttrs(attrs: Array<Attr>): Logger {
        // 实现属性支持
        this
    }

    public func isClosed(): Bool {
        false
    }

    public func close(): Unit {
        // 清理资源
    }

    public func log(record: LogRecord): Unit {
        if (record.level < _level) {
            return
        }
        // 输出到自定义日志系统
        myLogSystem.log(_name, record.level, record.message)
    }
}

// 注册自定义 Logger
main(): Int64 {
    // 在 main 方法最开始注册
    JoyLoggerFactory.registerCreator({
        name: String => MyLogger(name)
    })

    let joy = Joy.default()
    joy.run("127.0.0.1", 8080)
    return 0
}
```

---

## 五、请求访问日志

CJoy 内置请求访问日志 `AccessLog` 中间件，用于记录每次 HTTP 请求的访问信息。

### 5.1 基本用法

```cangjie
import cjoy.middleware.AccessLog

// 方式1：使用 JoyLoggerFactory 创建 Logger 输出访问日志
joy.router.use(AccessLog())
```

### 5.2 使用自定义 Logger

```cangjie
import cjoy.middleware.AccessLog
import cjoy.log.JoyLoggerFactory

// 方式2：指定自己的 Logger 对象
let logger = JoyLoggerFactory.createLogger("myapp.access")
joy.router.use(AccessLog(logger: Some(logger)))
```

### 5.3 使用过滤条件

```cangjie
// 方式3：指定过滤条件，忽略某些请求
joy.router.use(AccessLog(
    filterFn: {
        ctx: JoyContext =>
            // 忽略心跳检查路径
            ctx.path != "/heartbeat" && ctx.path != "/health"
    }
))
```

### 5.4 日志格式

AccessLog 记录的日志包含：

- 客户端 IP 地址
- HTTP 方法
- 请求 URL
- 响应状态码
- 请求处理时间（毫秒）

日志示例：

```
[AccessLog] 127.0.0.1 GET /api/data 200 15
```

---

## 六、JoyLoggerFactory API

### 6.1 createLogger

创建指定名称的 Logger 对象（默认使用 cjlog）：

```cangjie
let logger = JoyLoggerFactory.createLogger("myapp")
```

如果已注册自定义的 Logger 创建器，则使用自定义创建器；否则默认使用 cjlog。

### 6.2 registerCreator

注册自定义的 Logger 创建函数：

```cangjie
JoyLoggerFactory.registerCreator({
    name: String =>
        // 返回自定义的 Logger 实现
        MyLogger(name)
})
```

**注意**：必须在 `main` 方法最开始调用 `registerCreator`，确保在所有静态初始化之前完成。

---

## 七、使用示例

使用示例：[examples/logger](../../examples/src/logger/main.cj)。

### 7.1 基本日志

```cangjie
@JoyCreateLogger("simple")

@Get[path = "/hello"]
func hello(ctx: JoyContext): Unit {
    @JoyLogInfo("收到请求: ${ctx.url}")
    ctx.string("Hello World!")
}
```

### 7.2 调试日志

```cangjie
@JoyCreateLogger("debug")

@Get[path = "/debug"]
func debug(ctx: JoyContext): Unit {
    @JoyLogDebug("调试信息: ${ctx.queryParams}")
    @JoyLogDebug("请求头: ${ctx.httpContext.request.headers}")

    // 生产环境可以设置日志级别为 INFO 来禁用 DEBUG 日志
    ctx.string("调试信息已输出")
}
```

### 7.3 错误日志

```cangjie
@JoyCreateLogger("error")

@Get[path = "/error"]
func error(ctx: JoyContext): Unit {
    try {
        // 可能抛出异常的代码
        doSomething()
    } catch (e: Exception) {
        @JoyLogError("处理请求时发生错误: ${e.message}")
        ctx.status(500).string("内部错误")
    }
}
```

---

## 八、注意事项

1. **日志级别选择**：
   - 开发环境：使用 `DEBUG` 级别
   - 生产环境：使用 `INFO` 或 `WARN` 级别
   - 避免在生产环境输出 `DEBUG` 日志，可能泄露敏感信息

2. **日志内容规范**：
   - 使用结构化的日志格式，便于后续解析和分析
   - 记录关键业务操作的输入输出
   - 避免在日志中记录敏感信息（密码、令牌等）

3. **性能考虑**：
   - 高频日志考虑使用异步日志
   - 避免在循环中频繁记录日志
   - 使用字符串拼接而非多次日志调用

4. **访问日志管理**：
   - 生产环境建议启用 AccessLog
   - 定期清理或轮转访问日志文件
   - 结合日志分析工具进行监控和统计

5. **自定义框架**：
   - 使用成熟的日志框架（如 Log4j）进行生产部署
   - 配置日志轮转、归档和压缩策略
   - 将日志输出到集中式日志系统（如 ELK）

6. **Logger注册时机**：`registerCreator` 必须在 `main` 方法最开始调用

---
<< [返回](../../README.md#使用指导)
