# Session

## 使用

HTTP 是无状态协议， Session是Web服务端存储特定用户会话所需的属性及配置信息。当用户在应用程序的Web页之间跳转时，存储在Session对象中的变量将不会丢失，而是在整个用户会话中一直存在下去。

当用户首次请求时，如果该用户还没有会话，则Web服务器将自动创建一个Session对象。并在头域中Set-Cookie指定Sessoin ID，用于关联会话内的多次请求。

当会话过期或被放弃后，服务器将终止该会话。

CJoy内置两个简易Session存储实现：

 - MemorySessionStorage：Session存储在内存中
 - FileSessionStorage：Session存储在指定目录下

使用示例：[examples/session](../../examples/src/session/main.cj) 。

1. 注册SessionManager中间件

```
// 给所有Path注册SessionManager，采用MemorySessionStorage
let memorySessionManager = SessionManager(MemorySessionStorage())
joy.router.use(memorySessionManager)

// 给某个Group注册SessionManager，采用FileSessionStorage
let group = joy.router.group("/file")
let fileSessionManager = SessionManager(FileSessionStorage("./sessions"), config: JoySessionConfig(cookiePath: "/file"))
group.use(fileSessionManager)
```

在注册SessionManager时，可能指定JoySessionConfig:

```
SessionManager(storage, config: JoySessionConfig(cookieName: "sid" ...))
```

 - cookieName: 会话Cookie名，默认为`sid`
 - cookiePath：会话Cookie的Path，默认为`/`
 - cookieSecure：是否只在Https下使用，默认为false
 - cookieHttpOnly：HttpOnly属性是Cooki 的扩展功能，使JavaScript脚本无法获得Cookie，默认为true。主要目的为防止跨站脚本攻击（Cross-sitescripting，XSS对Cookie 的信息窃取。
 - cookieMaxAge：会话Cookie存活时长，默认为`3600`秒
 - cookieDomain：会话Cookie的域名，默认为空

2. 使用Session

```
// 先获取Session对象
let session = GetSession(ctx).getOrThrow()
```

- set: 在Session上存储信息
- get: 在Session上获取信息
- remove: 在Session上删除信息
- invalidate: 让Sesson失效

## 扩展

开发者可以自已扩展Session存储（如Redis, DB），只需要实现如下两个接口。

 - JoySession
 - JoySessionStorage

----
<< [返回](../../README.md#使用指导)
