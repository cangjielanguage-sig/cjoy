# 日志

## 概述

CJoy 内置日志工具 `JoyLoggerFactory`，用于创建 Logger 对象。默认情况下日志输出到 Console。

### 日志级别

CJoy 支持以下日志级别（按优先级从低到高）：

| 级别 | 说明 |
|-------|------|
| `DEBUG` | 调试信息，用于开发阶段 |
| `INFO` | 一般信息，记录程序正常运行状态 |
| `WARN` | 警告信息，表明潜在问题 |
| `ERROR` | 错误信息，记录错误事件 |

## 使用日志宏

CJoy 提供以下日志宏，建议应用优先采用宏打印日志：

| 宏 | 说明 |
|-----|------|
| `@JoyCreateLogger` | 创建日志对象 |
| `@JoyLogDebug` | 打印 DEBUG 级别日志 |
| `@JoyLogInfo` | 打印 INFO 级别日志 |
| `@JoyLogWarn` | 打印 WARN 级别日志 |
| `@JoyLogError` | 打印 ERROR 级别日志 |

### 基本用法

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

### 日志格式

日志宏自动添加以下信息：

- 当前时间（ISO 8601 格式）
- 日志级别
- 当前线程名或 ID
- 日志输出所在文件名
- 日志输出所在行号
- 日志输出所在 package 名

格式示例：

```
2026-01-31T22:18:19.233594401+08:00 INFO 1 [cjoy.framework/engine.cj:72] create joy app default
2026-01-31T22:18:20.456789123+08:00 DEBUG 2 [myapp/handler.cj:45] 处理请求数据: /api/data
```

## 日志级别控制

```cangjie
import cjoy.log.JoyLoggerFactory

main(): Int64 {
    // 创建 Logger 并设置级别
    let logger = JoyLoggerFactory.createLogger("myapp")
    logger.level = LogLevel.DEBUG  // 设置为调试级别

    let joy = Joy.default()    
    joy.run("127.0.0.1", 8080)
    return 0
}
```

## 扩展日志框架

可以将 CJoy 的日志输出适配到其他日志框架（如 Log4j、slf4j 等）：

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

## 请求访问日志

CJoy 内置请求访问日志 `AccessLog` 中间件，用于记录每次 HTTP 请求的访问信息。

### 基本用法

```cangjie
import cjoy.middleware.AccessLog

// 方式1：使用 JoyLoggerFactory 创建 Logger 输出访问日志
joy.router.use(AccessLog())
```

### 使用自定义 Logger

```cangjie
import cjoy.middleware.AccessLog
import cjoy.log.JoyLoggerFactory

// 方式2：指定自己的 Logger 对象
let logger = JoyLoggerFactory.createLogger("myapp.access")
joy.router.use(AccessLog(logger: Some(logger)))
```

### 使用过滤条件

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

### 日志格式

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

### 完整示例

```cangjie
import cjoy.Joy
import cjoy.middleware.AccessLog
import cjoy.log.JoyLoggerFactory
import cjoy.log.macros.*

@JoyCreateLogger("myapp")

main(): Int64 {
    let joy = Joy.default()

    // 注册访问日志中间件
    joy.router.use(AccessLog())

    joy.router.get("/api/data", {ctx: JoyContext =>
        @JoyLogInfo("处理请求: ${ctx.method} ${ctx.url}")
        ctx.json([("data", "value")])
    })

    joy.router.post("/api/submit", {ctx: JoyContext =>
        @JoyLogInfo("收到提交请求")
        // 处理逻辑...
        ctx.json([("status", "success")])
    })

    joy.run("127.0.0.1", 8080)
    return 0
}
```

## JoyLoggerFactory API

### createLogger

创建指定名称的 Logger 对象：

```cangjie
let logger = JoyLoggerFactory.createLogger("myapp")
```

如果已注册自定义的 Logger 创建器，则使用自定义创建器；否则使用 ConsoleLogger。

### registerCreator

注册自定义的 Logger 创建函数：

```cangjie
JoyLoggerFactory.registerCreator({
    name: String =>
        // 返回自定义的 Logger 实现
        MyLogger(name)
})
```

**注意**：必须在 `main` 方法最开始调用 `registerCreator`，确保在所有静态初始化之前完成。

## 使用示例

使用示例：[examples/logger](../../examples/src/logger/main.cj)。

### 示例1：基本日志

```cangjie
@JoyCreateLogger("simple")

@Get[path = "/hello"]
func hello(ctx: JoyContext): Unit {
    @JoyLogInfo("收到请求: ${ctx.url}")
    ctx.string("Hello World!")
}
```

### 示例2：调试日志

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

### 示例3：错误日志

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

## 最佳实践

1. **日志级别**：
   - 开发环境：使用 `DEBUG` 级别
   - 生产环境：使用 `INFO` 或 `WARN` 级别
   - 避免在生产环境输出 `DEBUG` 日志，可能泄露敏感信息

2. **日志内容**：
   - 使用结构化的日志格式，便于后续解析和分析
   - 记录关键业务操作的输入输出
   - 避免在日志中记录敏感信息（密码、令牌等）

3. **性能考虑**：
   - 高频日志考虑使用异步日志
   - 避免在循环中频繁记录日志
   - 使用字符串拼接而非多次日志调用

4. **访问日志**：
   - 生产环境建议启用 AccessLog
   - 定期清理或轮转访问日志文件
   - 结合日志分析工具进行监控和统计

5. **自定义框架**：
   - 使用成熟的日志框架（如 Log4j）进行生产部署
   - 配置日志轮转、归档和压缩策略
   - 将日志输出到集中式日志系统（如 ELK）

----
<< [返回](../../README.md#使用指导)
