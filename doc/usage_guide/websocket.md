# WebSocket

CJoy 提供WebSocket的封装，简化WebSocket消息接收与响应。

## 路由注册

示例：

```cangjie
router.websocket("/ws/chat/{name}", TextEchoJoyWebSocketHandler())
```

调用`JoyRouters.websocket`注册路由，与调用`get`函数类似，也支持中间件拦截WebSocket握手时的请求消息。

## Handler

接收消息需要实现接口`JoyWebSocketHandler`，回调函数说明：

 - `supportedSubProtocols`：设置支持的SubProtocols，默认为空，表示接受所有
 - `supportedOrigins`：设置接受Origins的白名单，默认为空，表示接受所有
 - `mergeFrames`：当分Frame传输时，是否合并Frame一个消息回调onMessage函数，默认合并
 - `onOpen`：Webscoket握手成功之后回调
 - `onMessage`：接收到Text或Binary消息时回调，如果分Frame传输且mergeFrames=false，则一个消息会按分Frame回调多次
 - `onClose`：Webscoket关闭时回调
 - `onError`：若接收或发送消息发生异常时回调

两个主要类，相关方法请参见源码：

 - `JoyWebSocketMessage`：Webscoket消息包装类
 - `JoyWebSocketSession`：Webscoket会话包装类，可以获取握手请求的一些URL参数(Path参数、Query参数，头域)，调用`send`函数发送消息

约束：

 - 受限于Cangjie SDK，`JoyWebSocketHandler`处理与发送消息要在同一线程中。

使用示例：[examples/websocket](../../examples/src/websocket/main.cj) 。

----
<< [返回](../../README.md#使用指导)