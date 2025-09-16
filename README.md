<div align="center">
<h1>CJoy</h1>
a fast，extensible，lightweight and joy cangjie web framework.<br/>
一个高性能、可扩展、轻量、省心的仓颉Web框架。
<br/>
<img alt="" src="doc/imgs/logo.png" height="118" width="200" style="display: inline-block;" />
</div>

<p align="center">
<img alt="" src="https://img.shields.io/badge/release-v0.60.0-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/cjc-v1.0.0-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/cjcov-70%25+-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/state-孵化-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/domain-HOS/Cloud-brightgreen" style="display: inline-block;" />
</p>

## 🔑 概览

本项目参考多种语言Web开源框架的设计优点，基于仓颉语言打造的具有高性能、高扩展性，高易用性等特点的Web框架。

### 特性

在仓颉SDK提供的HTTP框架基础上进一步封装以简化Web应用开发：

- 1️⃣ 基于压缩前辍树的路由管理，支持静态Path，参数匹配Path，正则匹配Path，全路径通配符Path的高效注册与查找，支持路由组；
- 2️⃣ 基于拦截器的中间件扩展能力，支持Session等多种能力扩展；
- 3️⃣ 基于Context的上下文管理，支持快速获取请求参数与构建Json/Text响应；
- 4️⃣ 基于编译宏的Json序列化与反序列，支持对请求与响应消息的Json直接绑定映射;
- 5️⃣ 基于编译宏支持自动注册与参数注入请求处理函数与中间件函数;
- 6️⃣ 基于编译宏支持对请求参数校验；
- 7️⃣ 基于编译宏支持MCP服务暴露工具等能力给LLM；
- 8️⃣ 内置文件下载与上传，WebSocket，SSE等能力;
- 9️⃣ 内置多种中间件，支持Basic, Token, JWT认证;

### 应用场景

- ♠️ API服务：帮助您快速开发API服务并配置路由规则与管理各种资源；
- ♥️ Web服务：压缩前辍树高性能路由查找与文件服务，让您的Web服务更具有性能优势；
- ♦️ 微服务：路由组与内置Json编译宏，轻松实现微服务各类接口分组管理与接口实现；
- ♣️ MCP服务：提供AI MCP服务组件编译宏，可以让您快速暴露MCP的工具等能力给LLM；

### 技术特点

- 🚀 高性能：零反射，基于编译宏生成代码，前辍树高效路由，运行时高性能；
- 🧩 轻量化：内置Web应用开发常见能力，模块化按需使用，能灵活组装；
- 🔌 可扩展：提供中间件机制，支持对Web请求拦截进行处理，丰富您的Web应用；
- 😊 易上手：内置多种能力，提供编译宏，简化Web，MCP应用开发，让您聚焦你的应用逻辑；
- 🛠️ 多协议：支持HTTP1，HTTP2，WebSocket, SSE, MCP等协议；

## ✨ 快速开始

**⚠️ 注意**

CJoy支持Windows, Linux与MacOS，推荐您在Linux(或WSL)，MacOS中运行仓颉，让您获得更好更快的体验。

请选择对应的仓颉版本：<img alt="" src="https://img.shields.io/badge/cangjie-v1.0.0-brightgreen" style="display: inline-block;" />

本项目依赖仓颉stdx包，请先下载对应版本的stdx包，使用说明参见 [仓颉编程语言 stdx](https://gitcode.com/Cangjie/Cangjie-STDX) 。

例如，把对应的stdx包解压到与Cangjie SDK并列目录cangjiestdx下：

- $HOME
  - cangjie ： 仓颉SDK目录
  - cangjiestdx ： 新建此目录
    - linux_x86_64_llvm ： 解压对应的stdx包，不同OS目录名称不同

设置环境变量CANGJIE_STDX_PATH指向$HOME/cangjiestdx，如在Linux与MacOS环境中，请修改用户家目录的`.bashrc`或`.zshrc`（取决于采用bash还是zsh）：

```
export CANGJIE_STDX_PATH=$HOME/cangjiestdx
```

### 运行本项目的示例

您可以先 `git clone https://gitcode.com/Cangjie-SIG/cjoy.git` 到您本地。

通过 `cjpm run --name <package-name>` 运行对应样例：

```
cjpm test 
cjpm build 
cd examples
cjpm run --name examples.tls
```

### 添加对本项目的依赖

在您的项目cjpm.toml文件增加如下：

```
[dependencies]
  cjoy = { git = "https://gitcode.com/Cangjie-SIG/cjoy.git", branch = "main" }
```

## 📦 快速了解

### 使用API

```
import cjoy.*

main(): Int64 {
    // 创建joy实例
    let joy = Joy.default()
    // 带参路由：GET /{name}
    joy.router.get("/{name}", {ctx: JoyContext => 
        let name = ctx.getParam("name") ?? "no name"
        ctx.string("name in parameter path, name=${name}")
    })
    // 静态路由：GET /abc
    joy.router.get("/abc", {ctx: JoyContext => 
        ctx.string("static path abc")
    })
    // 启动服务
    joy.run("127.0.0.1", 18881)
    return 0
}
```

### 使用宏

```
import cjoy.*
import cjoy.macros.*
import cjoy.json.*

@Json
class UserInfo {
    var id: String = ""
    var name: String = ""
    var address: String = ""
    var gender: Int = 0
}

// 处理 GET /users/{name}
@Get[path = "/users/{name}", produce="json"]
func getUser(@PathParam name: String): (UInt16, UserInfo) {
    let usr = UserInfo()
    usr.id = "00009527"
    usr.name = name
    usr.address = "shenzhen"
    (200, usr)
}

// 处理 GET /users
@Get[path = "/users", produce="json"]
func listUsers(@QueryParam[name = id, default = "00009527"] id: String): Array<UserInfo> {
    let usr = UserInfo()
    usr.id = id
    usr.name = "xiao"
    usr.address = "shenzhen"
    [usr]
}

main(): Int64 {
    let joy = Joy.default()
    // 注册生成的handlers
    JoyHandlers.registerTo(joy)
    joy.run("127.0.0.1", 18881)
    return 0
}
```

## 📎 更多示例

请参见 [examples](examples/README.md) 。

## 📖 使用指导

- [服务启动](doc/usage_guide/starter.md)
  - [实例](doc/usage_guide/starter.md#实例)
  - [启动](doc/usage_guide/starter.md#启动) 
- [日志](doc/usage_guide/logger.md)
  - [默认日志](doc/usage_guide/logger.md#默认日志)
  - [请求访问日志](doc/usage_guide/logger.md#请求访问日志) 
- [路由](doc/usage_guide/routing.md)
  - [路由规则](doc/usage_guide/routing.md#路由规则)
  - [路由优先级](doc/usage_guide/routing.md#路由优先级)
  - [分组](doc/usage_guide/routing.md#分组)
- [请求处理](doc/usage_guide/handler.md)
  - [Handler](doc/usage_guide/handler.md#handler)
    - [实现接口](doc/usage_guide/handler.md#实现接口)
    - [Lambda表达式函数](doc/usage_guide/handler.md#Lambda表达式函数)
  - [处理上下文](doc/usage_guide/handler.md#处理上下文)
- [Middleware](doc/usage_guide/middleware.md)
  - [使用方式](doc/usage_guide/middleware.md#使用方式)
  - [内置Middleware](doc/usage_guide/middleware.md#内置Middleware)
- [路由宏](doc/usage_guide/macro.md)
  - [Handler宏](doc/usage_guide/macro.md#handler宏)
  - [Middleware宏](doc/usage_guide/macro.md#Middleware宏)
  - [注册](doc/usage_guide/macro.md#注册)
- [参数绑定](doc/usage_guide/binding.md)
- [Json](doc/usage_guide/json.md)
  - [基础用法](doc/usage_guide/json.md#基础用法)
  - [高级用法](doc/usage_guide/json.md#高级用法)
    - [多态](doc/usage_guide/json.md#多态)
    - [Any类型绑定](doc/usage_guide/json.md#Any类型绑定)
    - [获取原始Json内容](doc/usage_guide/json.md#获取原始Json内容)
    - [Schema](doc/usage_guide/json.md#Schema)
    - [DSL](doc/usage_guide/json.md#DSL)
- [校验](doc/usage_guide/validation.md)
  - [类与结构体](doc/usage_guide/validation.md#类与结构体) 
  - [函数参数](doc/usage_guide/validation.md#函数参数) 
  - [宏说明](doc/usage_guide/validation.md#宏说明) 
- [MCP](doc/usage_guide/mcp.md)
  - [服务端](doc/usage_guide/mcp.md#服务端) 
    - [Tool](doc/usage_guide/mcp.md#Tool) 
    - [Resource](doc/usage_guide/mcp.md#Resource) 
    - [Prompt](doc/usage_guide/mcp.md#Prompt)    
    - [注册](doc/usage_guide/mcp.md#注册) 
  - [客户端](doc/usage_guide/mcp.md#客户端)  
- [分块传输](doc/usage_guide/mcp.md)
  - [Chunked](doc/usage_guide/chunked.md#Chunked) 
  - [SSE](doc/usage_guide/chunked.md#SSE) 
- [文件服务器](doc/usage_guide/fileserver.md)
  - [单个文件路由](doc/usage_guide/fileserver.md#单个文件路由) 
  - [多文件路由](doc/usage_guide/fileserver.md#多文件路由) 
- [WebSocket](doc/usage_guide/websocket.md)
  - [路由注册](doc/usage_guide/websocket.md#路由注册) 
  - [Handler](doc/usage_guide/websocket.md#Handler) 
- [MultiPart](doc/usage_guide/multipart.md)
  - [内置缓存](doc/usage_guide/multipart.md#内置缓存) 
  - [自定义Handler](doc/usage_guide/multipart.md#自定义Handler)

## 🏁 版本说明

CJoy目前还在开发阶段，框架主要能力已完成开发，后续重点是提升测试覆盖率，以及增加各类中间件实现。

版本发布采用打Tag的方式。您引用Cjoy可以在你的项目cjpm.toml采用如下方式：

```
[dependencies]
  cjoy = { git = "https://gitcode.com/Cangjie-SIG/cjoy.git", tag = "lastest tag" }
```

## 🤝 参与贡献

欢迎给我们提交 PR，欢迎给我们提交 Issue，欢迎参与任何形式的贡献。

fork时请保留上游仓库地址 [Cangjie-SIG/cjoy](https://gitcode.com/Cangjie-SIG/cjoy) 或 [lanlingx/cjoy](https://gitcode.com/lanlingx/cjoy) 。

本项目的维护者是 [@lanlingx](https://gitcode.com/lanlingx) 。

开发指导请参见 [doc/dev_guide](doc/dev_guide/README.md) 。

## 🪪 协议

参考 [LICENSE](LICENSE) 文件。
