# 分块传输

CJoy 提供对Chunked的封装，支持Chunked数据以及SSE(Server-Sent Events)的发送。

## Chunked

```cangjie
router.get("/chunked", {ctx: JoyContext =>
    let writer = ctx.chunkedWriter()
    for (num in 1..10) {
        writer.write(num.toString())
        sleep(Duration.millisecond*200)
    }
    writer.end()
})
```

 - 调用`JoyContext.chunkedWriter()` 创建 JoyPusherWriter
 - 调用`JoyChunkedWriter.write(...)` 写块数据，每调用一次发送一次Chunked
 - 调用`JoyChunkedWriter.end` 结束（可选）

## SSE

```cangjie
router.get("/sse", {ctx: JoyContext =>
    let emitter = ctx.eventEmitter()
    for (num in 1..10) {
        emitter.sendEvent(JobServerEventBuilder().data("{\"num\":\"${num}\"}"))
        sleep(Duration.millisecond*200)
    }
    emitter.end()
})
```

 - 调用`JoyContext.eventEmitter()` 创建 JoySseEmitter
 - 使用`JobServerEventBuilder` 构建 SSE 数据，调用`JoySseEmitter.sendEvent(...)`，每调用一次发送一次Event
 - 调用`JoySseEmitter.end` 结束（可选）
  
----
<< [返回](../../README.md#使用指导)