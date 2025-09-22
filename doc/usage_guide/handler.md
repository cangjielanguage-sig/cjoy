# 请求处理

## Handler

CJoy支持两种请求处理Handler实现。

### 实现接口

JoyRequestHandler定义参见  [handler.cj](../../src/framework/handler.cj) 。

```
// 实现JoyRequestHandler
class UserHandler <: JoyRequestHandler {
    public func handle(ctx: JoyContext): Unit {
        let name = ctx.getParam("name") ?? "no name"
    }
}
router.get("/{name}", UserHandler())
```

### Lambda表达式函数

```
// 直接采用Lambda表达式函数
router.get("/{name}", {ctx: JoyContext => 
    let name = ctx.getParam("name") ?? "no name"
    ...
})
```

HTTP的Handler通过调用JoyRouters的get, post, put等方法注册到路由分组上。JoyRouters接口定义参见 [route.cj](../../src/framework/route.cj) 。

## 处理上下文

Handler的入参JoyContext提供上下文支持对HTTP获取请求内容与回响应，主要API如下，请多的API请参见源码 [context.cj](../../src/framework/context.cj)  。

|函数|说明|
|---|---|
|getCtxParam|获取上下文参数，如在Middleware中设置上下文信息|
|getParam|获取URL Path上的参数|
|getQuery|获取URL QueryString上的参数|
|getPostForm|获取PostForm的参数|
|getHeader|获取Header|
|getCookie|获取Cookie|
|bindJsonBody|获取Body并绑定为Json对象|
|readString|获取String Body|
|setCtxParam|设置上下文参数|
|json|回响应Json Body|
|string|回响应Text Body|
|data|回响应Binary Body|
|header|设置Header|
|cookie|设置Cookie|

给HTTP回响应，支持链式调用，如`ctx.status(HttpStatusCode.STATUS_OK).header(hname, value).json(obj)`，当Handler函数返回时，构建响应消息回给客户端。

----
<< [返回](../../README.md#使用指导)