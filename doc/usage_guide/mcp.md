# MCP

CJoy内建支持MCP(Model Context Protocol)Server与Client。

- 协议版本：2024-11-05
- 传输层协议：SSE

## 服务端

CJoy提供宏来简化MCP的Tool，Resource, Prompt服务端函数的开发。

### Tool

CJoy提供宏@Tool标注函数，发布其为MCP的Tool。

```
@Tool[name = "add", description = "add two number"]
public func add(@ToolParam[description = "number a"] a: Int, @ToolParam[description = "number b"] b: Int): Int {
    a + b
}

@Tool[description = "nultiply two number"]
public func multiply(a: Int, b: Int): Int {
    a * b
}
```

|宏|属性参数|说明|
|---|---|---|
|`@Tool`|name="..", description:".."|作用于函数上。`name`默认函数名|
|`@ToolParam`|name="..", description:".."|作用函数参数上。`@ToolParam`可选，`name`默认取参数名|

以上宏的属性参数说明，属性可以采用`=`与`:`赋值，如`@Tool[name=xx]`与`@Tool[name:xx]`等价：

|宏属性参数|默认值|是否可选|说明|
|---|---|---|---|
|`name`||是|指定工具或参数的名称|
|`description`||是|用于描述工具或参数，会生成JSON schema，为了大模型更好的效果，描述应简洁清楚无歧义|

工具函数约束：
 - 入参是实现stdx.encoding.json.stream包下JsonDeserializable接口的类型，如基本类型，String等
 - 入参还可以是JoyContext类型，用于获取HTTP上下文信息，不用`@ToolParam`标注
 - 出参是实现ToString或JsonSerializable接口的类型

使用示例：[examples/mcpserver](../../src/examples/mcpserver/main.cj) 。

### 注册

目前传输层支持SSE协议，如下示例为把MCP注册到HTTP服务实例SSE接口上：

```
...
let joy = Joy.create(cfg)
// 注册到Http实例上
McpServer.registerSseTo(joy)
joy.run("127.0.0.1", 18881)
```

`McpServer.registerSseTo`支持把MCP的函数自动注册到服务实例上，有如下参数：

 - joy: 服务实列
 - ssePath：接收sse的PATH，默认为`/sse`
 - messagePath: 接收MCP消息的Path，默认为`/messages`

## 客户端

客户端仅仅用于测试，示例如下：

```
main(): Int64 {
    // 创建McpSseClient
    try(client = createMcpSseClient("http://127.0.0.1:18881/sse")) {
        // 会话协商
        let _ = client.initialize()
        // 查询工具
        let _ = client.listTools()
        // 调用工具
        let _ = client.callTool(CallToolRequest(name: "add", arguments: HashMap<String, Int64>([("a", 1), ("b", 2)])))
        let _ = client.callTool(CallToolRequest(name: "multiply", arguments: HashMap<String, Int64>([("a", 2), ("b", 3)])))
    } 
    return 0
}
```

使用示例：[examples/mcpclient](../../src/examples/mcpclient/main.cj) 。

----
<< [返回](../../README.md#使用指导)