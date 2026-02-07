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
    func write(s: String): JoyChunkedWriter

    // 写入字节数
    func write(b: Array<Byte>): JoyChunkedWriter

    // 写入 JSON 对象
    func writeJson<T>(obj: T): JoyChunkedWriter where T <: JsonSerializable
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
writer.write("Hello, World!")

```

### 1.4 链式调用

```cangjie
// 写入 JSON（自动序列化）
writer.writeJson(UserInfo())

// 写入 JSON 与Header
writer.writeJson(object).header("Some-Header", "xxxx")
```

### 1.5 写入字节流

```cangjie
// 写入字节数组并刷新
let bytes = [72u, 101u, 108u]
writer.write(bytes).flush()

// 写入字节流
let fileStream = File("/path/to/file.txt").openRead()
writer.data(fileStream)
```

---

## 二、JoySseEmitter SSE 事件发送

### 2.1 JoySseEmitter 接口

```cangjie
public interface JoySseEmitter <: ChunkedWriter {
    // 写入 SSE 数据
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
// 发送事件
emitter.sendEvent(JoyServerEventBuilder().data("{\"num\":\"${num}\"}"))
```

## 三、JoyContext 扩展方法

`JoyContext` 提供以下分块传输相关的方法：

| 函数 | 说明 |
|---|---|---|
| `chunkedWriter()` | 创建 ChunkedWriter 实例 |
| `eventEmitter()` | 创建 SSE 事件发送器实例 |


## 四、路由注册

### 4.1 Chunked 路由

```cangjie
// 注册 /chunked 路由
router.get("/stream", { ctx: JoyContext =>
    let writer = ctx.chunkedWriter()
    writer.writeJson(["line1", "line2"]).end()
})
```

### 4.2 SSE 路由

```cangjie
// 注册 /sse 路由
router.get("/events", { ctx: JoyContext =>
    let emitter = ctx.eventEmitter()
    let counter = SyncCounter(1)
    spawn {
        for (num in 1..10) {
            emitter.sendEvent(JoyServerEventBuilder().data("{\"num\":\"${num}\"}"))
            sleep(Duration.millisecond*200)
        }
        counter.dec()
    }
    counter.waitUntilZero()
    emitter.end()
})
```

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

    try {
        let fileStream = File("/path/to/file.txt").openRead()
        // 写入文件流
        writer.write(fileStream)
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
        writer.write(fileStream)
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
    // 写入多行 SSE 数据
    for (line in lines) {
        for (i in 0..10) {
            writer.sendEvent(JoyServerEventBuilder().data("{\"num\":\"${num}\"}"))
        }
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

1. **JSON 序列化**：使用 `writeJson<T>()` 方法时，对象必须实现 `JsonSerializable` 接口

2. **SSE 发送**：使用 `sendEvent()` 时，数据行会自动添加 `data: ` `event: `data: "` 前缀

3. **重试机制**：`JoySseEmitter` 支持通过 `Retry-After` 响应头设置重试间隔，网络错误时自动重试

4. **响应头设置**：使用 `header()` 方法时，会设置响应头（如 Content-Type、Retry-After）

5. **Writer 生命周期**：`ChunkedWriter` 实例的生命周期与请求响应绑定，请求结束后 Writer 自动失效

6. **并发安全**：`JoyChunkedWriter` 是线程不安全的，但底层的流和连接需要并发安全考虑


----
<< [返回](../../README.md#使用指导)