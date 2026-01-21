# MCP

CJoy内建支持MCP(Model Context Protocol)服务端开发。

- 协议版本：2025-03-26
- 传输层协议：SSE, StreamableHttp

MCP支持的情况：

 - 支持Tool、Resource、Prompt查询与调用，不支持listChanged与subscribe，不支持Batch请求
 - 支持SSE，StreamableHttp传输层（支持Json Response方式，不支持SSE Stream方式）
 - 接口认证需要使用者自已基于中间件机制扩展
 - StreamableHttp模式下Session存储在内存，多节点部署时需要前端LB配置基于会话级路由

## 服务端

CJoy提供宏来简化MCP的Tool，Resource, Prompt服务端函数的开发。

### Tool

Tool是核心MCP协议中重要组成，允许您的LLM与外部系统交互、执行代码和访问不在其训练数据中的数据。

 Tool可以执行查询数据库、调用API、进行计算或访问文件等任务，从而将其功能扩展到训练数据之外。当LLM决定使用工具时，流程如下：
 - 客户端根据Tool的Schema发送带有参数的请求
 - CJoy路由请求到对应的函数
 - CJoy把结果返回给LLM，LLM可以在其响应中使用它

CJoy提供宏`@Tool`标注函数，`@ToolParam`标注函数参数，发布其为MCP的Tool。

```cangjie
@Tool[name = "add", description = "add two number"]
public func add(@ToolParam[description = "number a"] a: Int, @ToolParam[description = "number b"] b: Int): Int {
    a + b
}

@Tool[description = "nultiply two number"]
public func multiply(a: Int, b: Int): Int {
    a * b
}
```

注册Tool后，CJoy会自动：

  - 使用`@Tool`属性中`name`与`description`生成Tool名与描述
  - 使用`@ToolParam`属性中`name`与`description`作为Tool参数与描述
  - 基于函数的参数和类型生成MCP协议要求的InputSchema
  - 注册HTTP的请求路由，以便后续MCP请求能路由到此函数

宏与宏属性说明：

|宏|属性参数|说明|
|---|---|---|
|`@Tool`|name="..", description:".."|作用于函数上。`name`默认函数名|
|`@ToolParam`|name="..", description:".."|作用函数参数上。`@ToolParam`可选，`name`默认取参数名|

以上宏的属性参数说明，属性可以采用`=`与`:`赋值，如`@Tool[name=xx]`与`@Tool[name:xx]`等价：

|宏属性参数|默认值|是否可选|说明|
|---|---|---|---|
|`name`||是|指定工具或参数的名称|
|`description`||是|用于描述工具或参数，会生成JSON schema，为了大模型更好的效果，描述应简洁清楚无歧义|

使用示例：[examples/mcpserver](../../examples/src/mcpserver/main.cj) 或者测试代码 [test/mcp_test](../../src/test/mcp_test.cj)。

#### Tool入参

参数的类型注释对于正确的工具功能至关重要：

- 为MCP协议生成准确的JSON Schema
- 告知LLM每个参数的预期数据类型

支持的类型：

 - 入参是实现stdx.encoding.json.stream包下JsonDeserializable接口的类型，以及基本类型，String等。
 - 入参宏`@ToolParam`可选，属性`name`默认取参数名，建议通过`@ToolParam(description:...)`来增强参数描述
 - 入参可以是可选参数，如`Option<类型>`，则Tool的Schema对应的参数也是可选
 - 入参还可以是JoyContext类型，用于获取HTTP上下文信息，不用`@ToolParam`标注

当工具的输入参数较多时，可以把多个参数聚合在一个类型中，如下所示：

```cangjie
@Json
public class Params {
    @JsonField[description = "number a"]
    public var a: Int
    @JsonField[description = "number b"]
    public var b: Int
}

@Tool[description = "add two number"]
public func add2(param: Params): Int {
    param.a + param.b
}

@Tool[description = "add two number"]
public func add3(param: Params, ctx: JoyContext): Int {
    param.a + param.b
}
```

示例中`add2`和`add3`与前面的`add`是等价的，有相同的MCP工具的inputSchema。

#### Tool出参

框架自动将函数返回的值转换为客户端的适当的MCP协议定义的Content格式：

 - 出参是实现ToString或JsonSerializable接口的类型，返回TextContent
 - 出参是`Array<ToString|JsonSerializable>`或`ArrayList<ToString|JsonSerializable>`类型，返回多个TextContent
 - 出参是cjoy.mcp.Image类型或`Array<Image>`或`ArrayList<Image>`，返回ImageContent
 - 出参是cjoy.mcp.Audio类型或`Array<Audio>`或`ArrayList<Audio>`，返回AudioContent
 - 调用函数出错，返回TextContent(isError=true, text="error message")

### Resource

静态Resource表示MCP客户端可以读取的数据或文件，动态ResourceTemplate通过允许客户端根据URI中传递的参数请求**动态**生成资源来扩展这一概念。

Resource为LLM或客户端应用程序提供对数据的只读访问，Resource允许LLM访问与对话相关的文件、数据库内容、配置或动态生成的信息。当客户端请求资源URI时：
- CJoy找到相应的资源定义，路由到对应的函数
- 如果它是动态Resource（由函数定义），该提取URI中参数
- 返回对应的内容（文本、JSON、二进制数据）给调用者

Cjoy提供`@Resource`宏标注函数，发布为MCP中静态与动态Resource。

```cangjie
@Resource[uri = "data://secret"]
public func secretData(): String {
    "secret data"
}

@Resource[uri = "resource://{name}/detail"]
public func systemStatus(ctx: JoyContext, name: String): HashMap<String, String> {
    HashMap<String, String>([("name", name)])
}
```

宏与宏属性说明：

|宏|属性参数|说明|
|---|---|---|
|`@Resource`|uri:"..", name="..", description:"..",mimeType:""|作用于函数上。`name`默认函数名|
|`@ResourceParam`|name="..", description:"..", default:""|作用函数参数上。`@ResourceParam`可选，`name`默认取参数名|

|宏属性参数|默认值|是否可选|说明|
|---|---|---|---|
|`uri`||否|指定资源的URI，格式如resource://{name}/detail，其中{name}动态参数变量|
|`name`||是|指定资源的名称|
|`description`||是|用于描述资源，为了大模型更好的效果，描述应简洁清楚无歧义|
|`mimeType`||是|资源的类型|
|`default`||是|参数默认值|

使用示例：[examples/mcpserver](../../examples/src/mcpserver/main.cj) 或者测试代码 [test/mcp_test](../../src/test/mcp_test.cj)。

#### Resource入参

函数支持的入参

 - 可以是JoyContext类型，用于获取HTTP上下文信息
 - 当是动态Resource，绑定URI中参数，参数名为URL中变量，入参为基础类型，String
  
```cangjie
@Resource[uri = "resource://{name}/detail"]
public func systemStatus(ctx: JoyContext, name: String): HashMap<String, String> {
    // name参数是URI中的{name}
    HashMap<String, String>([("name", name)])
}
```

#### Resource出参

框架自动将函数返回的值转换为客户端的适当的MCP协议定义的ResourceContents格式：

 - 出参是实现ToString接口的类型，返回TextResourceContents(mimeType="text/plain")
 - 出参是实现JsonSerializable接口的类型，返回TextResourceContents(mimeType="application/json")
 - 出参是`Array<ToString|JsonSerializable>`或`ArrayList<ToString|JsonSerializable>`类型，返回多个TextResourceContents
 - 出参是HashMap类型，返回TextResourceContents(mimeType="application/json")
 - 出参是`Array<Byte>`类型，返回BlobResourceContents(mimeType="application/octet-stream")，对响应进行Base64编码
 - 当出参非上述类型，返回TextResourceContents(mimeType="ext/plain"), 内容为空
 - 返回XXXResourceContents优先取@Resource指定的mimeType值，不存在则取上述默认值

### Prompt

Prompt是可重用的消息模板，可帮助LLM生成结构化、有目的的响应。当客户端请求Prompt时：

 - CJoy找到相应的Prompt定义
 - 如果它有参数，提取参数
 - 生成的消息将返回给LLM以指导其响应
 - 允许您定义一致的、可重用的模板，LLM可以在不同的客户端和上下文中使用这些模板


CJoy提供`@Prompt`宏标注函数，发布为MCP中Prompt。

```cangjie
@Prompt[name = askUserTopic]
public func askUserTopic(topic: String): String {
    "Can you please explain the concept of ${topic}"
}

@Prompt[name = analyze_data_request, description = "Creates a request to analyze data with specific parameters"]
public func dataAnalysisPrompt(
    @PromptParam[description = "The URI of the resource containing the data."] dataUri: String,
    @PromptParam[default = "summary", description = "Type of analysis."] analysisType: String
): String {
    "Please perform a '${analysisType}' analysis on the data found at ${dataUri}."
}
```

宏与宏属性说明：

|宏|属性参数|说明|
|---|---|---|
|`@Prompt`|name="..", description:".."|作用于函数上。`name`默认函数名|
|`@PromptParam`|name="..", description:"..", default:""|作用函数参数上。`@PromptParam`可选，`name`默认取参数名|

|宏属性参数|默认值|是否可选|说明|
|---|---|---|---|
|`name`||是|指定Prompt或参数的名称|
|`description`||是|用于描述Prompt或参数，描述应简洁清楚无歧义|
|`default`||是|参数默认值|

使用示例：[examples/mcpserver](../../examples/src/mcpserver/main.cj) 或者测试代码 [test/mcp_test](../../src/test/mcp_test.cj)。

#### Prompt入参

函数支持的入参

 - 可以是JoyContext类型，用于获取HTTP上下文信息
 - 可以为基础类型，String
 - 可以为Option<类型>
  
#### Prompt出参

框架自动将函数返回的值转换为客户端的适当MCP定义格式：

 - 出参是实现ToString接口的类型，返回PromptMessage.TextContent
 - 出参是实现JsonSerializable接口的类型，返回PromptMessage.TextContent
 - 出参是`Array<ToString|JsonSerializable>`或`ArrayList<ToString|JsonSerializable>`类型，返回多个PromptMessage.TextContent
 - 出参是HashMap类型，返回TextContent
 - 出参是`cjoy.mcp.Message`类型，返回PromptMessage.TextContent
 - 出参是`Array<Message>`或`ArrayList<Message>`类型，返回多个PromptMessage.TextContent
 - 出参是`cjoy.mcp.PromptMessage`类型，返回PromptMessage
 - 出参是`Array<PromptMessage>`或`ArrayList<PromptMessage>`类型，返回多个PromptMessage
 - 当出参没有指定role时，默认是role=assistant

### 注册

目前传输层支持SSE与StreamableHttp协议，如下示例为把MCP注册到HTTP服务实例接口上：

```cangjie
let joy = Joy.create(cfg)
// 注册到Http实例上
McpServer.registerSseTo(joy)
McpServer.registerStreamableTo(joy, isJsonResp: true)
joy.run("127.0.0.1", 18881)
```

SSE方式，`McpServer.registerSseTo`支持把MCP的函数自动注册到服务实例上，有如下参数：

 - joy: 服务实列
 - ssePath：接收sse的PATH，默认为`/sse`
 - messagePath: 接收MCP消息的Path，默认为`/messages`

StreamableHttp方式，`McpServer.registerStreamableTo`支持把MCP的函数自动注册到服务实例上，有如下参数：

  - joy: 服务实例
  - path：接收MCP消息的Path，默认为`/mcp`
  - isJsonResp: 响应采用Json方式代替SSE方式

注：目前只支持isJsonResp=true

## 客户端

客户端仅仅用于测试，示例如下：

```cangjie
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

使用示例：[examples/mcpclient](../../examples/src/mcpclient/main.cj) 。

可以使用Python的fastmcp客户端来对接CJoy开发的MCP服务端 [examples/mcpclient/client.py](../../examples/src/mcpclient/client.py) 。

----
<< [返回](../../README.md#使用指导)