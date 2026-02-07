# 分块传输

CJoy 提供分块传输（Chunked）和 SSE（Server-Sent Events）支持，用于大数据流式响应或实时事件推送场景。

## 概述

CJoy 分块传输系统基于以下核心概念设计：

- **分块传输**：支持 HTTP 分块编码（Chunked）发送大文件
- **SSE 服务推送**：支持 Server-Sent Events 服务，用于实时事件推送
- **零拷贝**：数据写入直接到 HTTP 响应流，零内存拷贝
- **类型泛型**：支持字符串、字节数组、字节流、JSON 对象等
- **链式调用**：响应方法支持链式调用，如 `.json(obj).header(h, v).status(200)`

核心接口定义：
- `JoyChunkedWriter`：分块写入接口，参见 [chunked.cj](../../src/framework/chunked.cj)
- `JoySseEmitter`：SSE 事件发送接口，参见 [sse.cj](../../src/sse/sse.cj)

---

## 一、Chunked 分块传输

### 1.1 JoyChunkedWriter 接口

```cangjie
public interface JoyChunkedWriter <: ChunkedWriter {
    // 写入字符串
    func string(s: String): JoyChunkedWriter

    // 写入字节数组
    func strings(ss: Array<String>): JoyChunkedWriter

    // 写入字节数
    func bytes(b: Array<Byte>): JoyChunkedWriter

    // 写入 JSON 对象
    func json<T>(obj: T): JoyChunkedWriter where T <: JsonSerializable

    // 写入字节流
    func data(stream: InputStream): JoyChunkedWriter
}
```

### 1.2 创建 ChunkedWriter

```cangjie
// 通过 JoyContext 创建 ChunkedWriter
let writer = ctx.chunkedWriter()
```

### 1.3 基本用法

```cangjie
// 写入字符串
writer.string("Hello, World!")

// 写入字符串数组
writer.strings(["line1", "line2", "line3"])

// 写入字节数组
writer.writeStrings(["Hello", "World!"])

// 写入单个字节数组
let chunk = writer.writeStrings(["single"])
writer.flush()
```

### 1.4 链式调用

```cangjie
// 设置响应头、状态码
writer.header("X-Custom-Header", "value")
writer.status(200)

// 写入 JSON（自动序列化）
writer.json(UserInfo())

// 设置 Content-Type
writer.contentType("application/json")
writer.json(object).header("Content-Type", "application/json")

// 结束发送并刷新
writer.end()
```

### 1.5 写入字节流

```cangjie
// 写入字节数组并刷新
let bytes = [72u, 101u, 108u]
writer.bytes(bytes).flush()

// 写入字节流
let fileStream = File("/path/to/file.txt").openRead()
writer.data(fileStream)
writer.end()
```

---

## 二、JoySseEmitter SSE 事件发送

### 2.1 JoySseEmitter 接口

```cangjie
public interface JoySseEmitter <: ChunkedWriter {
    // 写入 SSE 数据行
    func line(line: String): JoySseEmitter
    func data(data: String): JoySseEmitter
    func sendEvent(data: String): JoySseEmitter
}
```

### 2.2 创建 SseEmitter

```cangjie
// 通过 JoyContext 创建 SseEmitter
let emitter = ctx.eventEmitter()
```

### 2.3 基本用法

```cangjie
// 写入 SSE 数据行
emitter.line("data: ${timestamp}")

// 写入数据行并刷新
emitter.data("some data").flush()

// 发送事件
emitter.sendEvent("event: user.created", "{\"id\": \"123\"}")
```

// 链式调用
emitter.header("Retry-After", "120")
emitter.data("retrying...").status(200).end()
```

---

## 三、JoyContext 扩展方法

`JoyContext` 提供以下分块传输相关的方法：

| 函数 | 说明 |
|---|---|---|
| `chunkedWriter()` | 创建 ChunkedWriter 实例 |
| `eventEmitter()` | 创建 SSE 事件发送器实例 |
| `chunked()` | 便捷方法，等价于 `chunkedWriter()` |

---

## 四、路由注册

### 4.1 Chunked 路由

```cangjie
// 注册 /chunked 路由
router.get("/stream", { ctx: JoyContext =>
    let writer = ctx.chunkedWriter()
    writer.strings(["line1", "line2"]).end()
})
```

### 4.2 SSE 路由

```cangjie
// 注册 /sse 路由
router.get("/events", { ctx: JoyContext =>
    let emitter = ctx.eventEmitter()
    emitter.line("event: connected")
    emitter.data("{\"connected\": true}").end()
})
```

---

## 五、完整示例

```cangjie
import std.io.{File, InputStream}
import stdx.net.http.{HttpContext, HttpStatusCode}
import cjoy.*
import cjoy.macros.*

@Get[path = "/stream"]
func streamFile(ctx: JoyContext): String {
    // 创建 ChunkedWriter
    let writer = ctx.chunkedWriter()

    // 设置响应
    ctx.contentType("text/event-stream")
        .status(HttpStatusCode.STATUS_OK)

    try {
        let fileStream = File("/path/to/file.txt").openRead()
        // 写入文件流
        writer.data(fileStream)
        fileStream.close()
    writer.end()
        return "stream complete"
    } catch (e: IOException) {
        e.printStackTrace()
        return "stream error: ${e.message}"
    }
}

@Post[path = "/stream"]
func uploadFile(ctx: JoyContext): String {
    let writer = ctx.chunkedWriter()

    try {
        // 获取请求体大小
        let contentLength = ctx.httpContext.request.bodySize.getOrThrow()

        // 限制大小
        if (contentLength > 10 * 1024 * 1024) {
            ctx.status(HttpStatusCode.STATUS_PAYLOAD_TOO_LARGE)
            writer.end()
            return "File too large"
        }

        // 写入文件流
        let fileStream = File("/path/to/file.txt").openWrite()
        writer.data(fileStream).end()
        fileStream.close()
        writer.end()
        return "Upload successful"
    } catch (e: IOException) {
        e.printStackTrace()
        return "Upload error: ${e.message}"
    }
}

@Get[path = "/sse", produce = "json"]
func sseHandler(ctx: JoyContext): String {
    let writer = ctx.eventEmitter()
    let lines = ArrayList<String>()
    for (i in 0..10) {
        lines.add("data: ${i}")
    }

    // 写入多行 SSE 数据
    for (line in lines) {
        writer.line(line).flush()
    writer.data(line).flush()
    // 矍式调用，设置重试间隔
        writer.header("Retry-After", "5000")
    }
    writer.end()
    return "SSE complete"
}
```

```cangjie
main(): Int64 {
    let joy = Joy.default()

    // 注册路由
    joy.router.get("/stream", streamFile)
    joy.router.get("/upload", uploadFile)
    joy.router.get("/sse", sseHandler)

    joy.run("127.0.0.1", 18881)
    return 0
}
```

## 六、注意事项

1. **流式关闭**：使用 `data(stream)` 或 `data(bytes)` 方法后，必须调用 `end()` 或 `flush()` 关闭流

2. **文件流**：使用 `data(fileStream)` 时，注意在 `end()` 或 `flush()` 后关闭文件流

3. **流式写入**：数据写入是自动刷新的，但建议在关键节点后手动调用 `flush()` 确保数据及时发送

4. **内存拷贝**：`bytes()` 和 `strings()` 方法会先在内存中缓存数据，然后一次性写入

5. **JSON 序列化**：使用 `json<T>()` 方法时，对象必须实现 `JsonSerializable` 接口

6. **SSE 发送**：使用 `sendEvent()` 时，数据行会自动添加 `data: ` `event: `data: "` 前缀

7. **重试机制**：`JoySseEmitter` 支持通过 `Retry-After` 响应头设置重试间隔，网络错误时自动重试

8. **响应头设置**：使用 `header()` 方法时，会设置响应头（如 Content-Type、Retry-After）

9. **Content-Type**：使用 `json()` 或 `json()` 时，默认 Content-Type 为 `text/event-stream` 或 `application/json`

10. **大文件限制**：建议在处理大文件时使用 `data()` 流式写入，避免一次性加载到内存

11. **Writer 生命周期**：`ChunkedWriter` 实例的生命周期与请求响应绑定，请求结束后 Writer 自动失效

12. **并发安全**：`JoyChunkedWriter` 是线程不安全的，但底层的流和连接需要并发安全考虑


----
<< [返回](../../README.md#使用指导)