# Http服务

CJoy提供调用Http服务能力，支持多种认证，自定义扩展认证。

## 使用方式 

使用示例：[examples/httpx](../../examples/src/httpx/main.cj) 。

1. 注册Http服务

```cangjie
// 注册Http服务，配置地址，ClienBudiler配置，你可以定制budilerFn，默认是对https证书全信任
var client: JoyHttpClient = JoyHttpClientService("https://cangjie-lang.cn/")
// 配置Basic认证
client = BasicAuthClient(client, username: "test", password: "test")
// 配置重试次数
client = RetryClient(client, maxRetries: 3)
```

示例链式使用了三个HttpClient：

- JoyHttpClientService：为基础服务
- BasicAuthClient：支持Basic认证
- RetryClient：支持抛异常时(连接超时)，服务端返回500时重试

JoyHttpClientService有两个构造参数

 - url：指定服务端基础URL
 - budilerFn：构建ClientBuidler，框架提供默认实现
   - 对HTTPS证书全信任，对地址中主机信任
   - 读写超时为 1 min

BasicAuthClient有三个构造参数
 
 - http： 代理的HttpClient
 - username: Basic认证的用户名
 - password: Basic认证的密码

RetryClient有二个构造参数
 
 - http： 代理的HttpClient
 - maxRetries: 最大发送请求次数

2. 其次在某处理Http请求函数中，根据名称获取Http服务，发送请求给服务端

```cangjie
// 使用Http服务
let client = ctx.getService<JoyHttpClient>("cj").getOrThrow()
let rsp = client.get(ctx, "/docs")
println(rsp.status)
ctx.string(rsp.text)
```

框架定义了 [JoyHttpClient](../../src/httpx/api.cj) 接口。应用调用其get/post/put/delete/patch/postform函数发送请求。参数说明如下：

- `ctx`: 上下文，取接收请求的ctx
- `path`: URL Path
- `queries`: 请求Query参数请求
- `headers`：请求头域
- `body`: 请求体

若发送JSON请求时，方法入参body类型如下会自动转换为JSON Body：

 - JsonRequest对象
 - 实现JsonSerializable接口的对象

发送通用方法为send函数，入参为JoyHttpRequest：

 - `json`: 支持把对象转成JSON Body
 - `multiPart`: 支持发送form-data，如提交表单或上传文件
 - `postform`: 支持发送x-www-form-urlencoded

响应类型为 [JoyHttpResponse](../../src/httpx/api.cj) ，调用如下函数或属性获取内容：

 - `json<T>()`: 把JSON Body反序列为对象
 - `text`：获取Body文本内容
 - `status`： 获取Http status code
 - `header`: 获取header

## 自定义扩展

框架当前提供基础实现`JoyHttpClientService`，以及如下扩展实现：

 - `BasicAuthClient`： Basic认证
 - `TokanAuthClien`： Token认证
 - `RetryClient`： 重试
  
你可以参考上述实现，定制自己的HttpClient，实现 [JoyHttpClient](../../src/httpx/api.cj) 接口，对默认实现能力扩展增强。

----
<< [返回](../../README.md#使用指导)