# NoCache 中间件

NoCache 中间件用于禁用 HTTP 缓存，确保客户端不会缓存响应内容。这对于需要实时数据的 API 或包含敏感信息的页面特别有用。

## 基本用法

```cangjie
import cjoy.middleware.NoCache

main(): Int64 {
    let joy = Joy.default()

    // 全局禁用缓存
    joy.router.use(NoCache())

    joy.router.get("/api/data", {ctx: JoyContext =>
        ctx.json([("timestamp", DateTime.now())])
    })

    joy.run("127.0.0.1", 8080)
    return 0
}
```

## 应用到特定路由

```cangjie
// 只对 /api 下的路由禁用缓存
joy.router
    .group("/api")
    .use(NoCache())
    .get("/data", {ctx => ctx.json([("key", "value")])})

// 只对单个路由禁用缓存
joy.router
    .apply(NoCache())
    .get("/public/data", {ctx => ctx.json([("key", "value")])})
```

## 工作原理

NoCache 中间件通过设置以下 HTTP 响应头来禁用缓存：

### 删除的请求头

中间件会删除以下客户端请求的缓存相关头：

| 请求头 | 说明 |
|---------|------|
| `ETag` | 实体标签，用于验证缓存 |
| `If-Modified-Since` | 条件请求，只获取修改过的资源 |
| `If-Match` | 条件请求，匹配 ETag |
| `If-None-Match` | 条件请求，不匹配 ETag |
| `If-Range` | 条件请求，范围请求 |
| `If-Unmodified-Since` | 条件请求，未修改的资源 |

### 添加的响应头

| 响应头 | 值 | 说明 |
|---------|-----|------|
| `Expires` | `Thu, 01 Jan 1970 00:00:00 GMT` | 设置过期时间为过去时间 |
| `Cache-Control` | `no-cache, no-store, no-transform, must-revalidate, private, max-age=0` | 禁用所有缓存指令 |
| `Pragma` | `no-cache` | HTTP/1.0 兼容的缓存控制 |
| `X-Accel-Expires` | `0` | 加速器扩展头，设置过期时间为 0 |

## 完整示例

```cangjie
import cjoy.Joy
import cjoy.middleware.NoCache
import cjoy.json.macros.*

main(): Int64 {
    let joy = Joy.default()

    // API 接口禁用缓存，确保获取实时数据
    joy.router
        .group("/api")
        .use(NoCache())
        .get("/currentTime", {ctx: JoyContext =>
            ctx.json(@ToJson({
                "currentTime": DateTime.now().format(DateTimeFormat.ISO8601),
                "message": "此响应不会被缓存"
            }))
        })

    // 静态资源可以不使用 NoCache，允许浏览器缓存
    joy.router.get("/static/data", {ctx: JoyContext =>
        ctx.json(@ToJson({
            "version": "1.0.0",
            "message": "此响应可以被缓存"
        }))
    })

    joy.run("127.0.0.1", 8080)
    return 0
}
```

## 使用场景

- **实时数据 API**：确保客户端获取最新数据
- **用户个人信息**：包含敏感信息，不应被缓存
- **动态生成的页面**：内容经常变化，缓存会导致显示过期内容
- **表单提交后**：防止返回旧状态
- **支付/交易页面**：确保显示正确的金额和状态

## 注意事项

1. **性能影响**：禁用缓存会增加服务器负载和客户端网络请求
2. **选择性使用**：只为需要的路由添加 NoCache 中间件
3. **静态资源**：静态文件（CSS、JS、图片）应允许缓存以提升性能
4. **CDN 场景**：使用 CDN 时需要注意其缓存策略可能覆盖 NoCache 设置

----
<< [返回](../../README.md#使用指导)
