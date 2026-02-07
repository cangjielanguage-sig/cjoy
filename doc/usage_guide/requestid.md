# RequestId 中间件

RequestId 中间件为每个 HTTP 请求生成或分配一个唯一的请求 ID。这对于日志追踪、问题排查和分布式系统中的请求链路追踪非常有用。

## 基本用法

```cangjie
import cjoy.middleware.{RequestId, getRequestId}

main(): Int64 {
    let joy = Joy.default()

    // 注册 RequestId 中间件
    joy.router.use(RequestId())

    joy.router.get("/api/data", {ctx: JoyContext =>
        if (let Some(req) <- getRequestId(ctx)) {
            ctx.string("Request ID: ${req}")
        }
    })

    joy.run("127.0.0.1", 8080)
    return 0
}
```

## 配置选项

### 构造函数参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| prefix | String | 随机4位字符串 | 请求 ID 的前缀 |
| headerName | String | "X-Request-Id" | 请求头名称，用于获取或设置请求 ID |

### prefix

设置请求 ID 的前缀。如果不指定，中间件会生成一个随机的 4 位字符串作为前缀。

```cangjie
// 使用自定义前缀
let requestId = RequestId(
    prefix: "app1",
    headerName: "X-Request-Id"
)
```

请求 ID 格式：`<prefix>-<sequence>`

例如：`app1-0000000001`、`app1-0000000002`

### headerName

指定用于获取或设置请求 ID 的请求头名称。

```cangjie
// 使用自定义请求头
let requestId = RequestId(
    prefix: "api",
    headerName: "X-Correlation-Id"
)
```

## 工作原理

1. **检查请求头**：中间件首先检查请求中是否已包含指定的请求头
2. **使用现有 ID**：如果请求头中存在请求 ID，则使用该 ID
3. **生成新 ID**：如果请求头中不存在请求 ID，则生成新的请求 ID（`<prefix>-<sequence>`）
4. **设置响应头**：将请求 ID 设置到响应头中
5. **存储到上下文**：将请求 ID 存储到上下文中，可通过 `getRequestId` 获取

## 获取请求 ID

使用 `getRequestId` 函数从上下文中获取请求 ID：

```cangjie
import cjoy.middleware.getRequestId

@Get[path = "/api/data"]
func handleData(ctx: JoyContext): Unit {
    if (let Some(reqId) <- getRequestId(ctx)) {
        // 在日志中使用请求 ID
        @JoyLogInfo("[${reqId}] 处理请求: ${ctx.path}")
    } else {
        @JoyLogWarn("未获取到请求 ID")
    }
}
```

## 完整示例

### 基本示例

```cangjie
import cjoy.Joy
import cjoy.middleware.{RequestId, getRequestId}

main(): Int64 {
    let joy = Joy.default()

    // 注册 RequestId 中间件
    joy.router.use(RequestId(
        prefix: "web",
        headerName: "X-Request-Id"
    ))

    joy.router.get("/hello", {ctx: JoyContext =>
        if (let Some(reqId) <- getRequestId(ctx)) {
            ctx.header("X-Request-Id", reqId)
            ctx.json(@ToJson({
                "message": "Hello!",
                "requestId": reqId
            }))
        }
    })

    joy.run("127.0.0.1", 8080)
    return 0
}
```

### 配合 AccessLog 使用

```cangjie
import cjoy.Joy
import cjoy.middleware.{RequestId, getRequestId, AccessLog}
import cjoy.log.macros.*

main(): Int64 {
    let joy = Joy.default()

    // 注册 RequestId
    joy.router.use(RequestId())

    // 注册 AccessLog，在日志中包含请求 ID
    joy.router.use(AccessLog {
        ctx: JoyContext =>
            if (let Some(reqId) <- getRequestId(ctx)) {
                @JoyLogInfo("[${reqId}] ${ctx.method} ${ctx.url} - ${ctx.respStatus}")
            } else {
                @JoyLogInfo("${ctx.method} ${ctx.url} - ${ctx.respStatus}")
            }
    })

    joy.router.get("/api/data", {ctx: JoyContext =>
        ctx.json(@ToJson({"data": "success"}))
    })

    joy.run("127.0.0.1", 8080)
    return 0
}
```

### 链路追踪

在分布式系统中，通过请求 ID 追踪请求链路：

```cangjie
import cjoy.Joy
import cjoy.middleware.{RequestId, getRequestId}
import cjoy.log.macros.*

// 模拟调用外部服务
func callExternalService(ctx: JoyContext, url: String): Unit {
    if (let Some(reqId) <- getRequestId(ctx)) {
        // 将请求 ID 传递给下游服务
        @JoyLogInfo("[${reqId}] 调用外部服务: ${url}")
        // 实际代码中会通过 HTTP 头传递请求 ID
        // headers.add("X-Request-Id", reqId)
    }
}

main(): Int64 {
    let joy = Joy.default()

    joy.router.use(RequestId(prefix: "gateway"))

    joy.router.get("/api/user", {ctx: JoyContext =>
        if (let Some(reqId) <- getRequestId(ctx)) {
            @JoyLogInfo("[${reqId}] 开始处理用户请求")
            callExternalService(ctx, "http://user-service/api/info")
            @JoyLogInfo("[${reqId}] 完成处理")
        }
        ctx.json(@ToJson({"status": "ok"}))
    })

    joy.run("127.0.0.1", 8080)
    return 0
}
```

## 客户端传递请求 ID

客户端可以在请求头中传递请求 ID，用于链路追踪：

```bash
# 使用 curl 发送请求并指定请求 ID
curl -H "X-Request-Id: client-12345" http://localhost:8080/api/data
```

前端代码示例：

```javascript
// 生成或获取请求 ID
function getRequestId() {
    let reqId = sessionStorage.getItem('requestId');
    if (!reqId) {
        reqId = 'client-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9);
        sessionStorage.setItem('requestId', reqId);
    }
    return reqId;
}

// 发送请求时携带请求 ID
fetch('/api/data', {
    headers: {
        'X-Request-Id': getRequestId()
    }
});
```

## 使用场景

- **日志追踪**：在日志中关联同一请求的所有日志记录
- **问题排查**：通过请求 ID 快速定位特定请求的处理过程
- **分布式链路追踪**：在微服务架构中追踪请求跨越多个服务的路径
- **性能分析**：统计特定请求 ID 的处理时间
- **安全审计**：记录每个请求的唯一标识，用于安全审计

## 注意事项

1. **请求 ID 格式**：格式为 `<prefix>-<sequence>`，sequence 是自增的数字（10位，前导零填充）
2. **前缀选择**：使用有意义的前缀便于区分不同服务或环境
3. **线程安全**：自增序列号使用原子操作，确保线程安全
4. **序列重置**：服务重启后序列号会重置，但前缀是随机生成或指定的，可避免冲突
5. **日志格式**：建议在日志中统一使用 `[请求ID]` 前缀格式

----
<< [返回](../../README.md#使用指导)
