# Middleware

CJoy提供扩展机制支持HTTP请求进行拦截处理，机制类似于Java的Servlet Filter。

Middleware需要实现JoyMiddlewareHandle接口，其中chain对象为所有MiddlewareHandler链，调用`chain.next(ctx)`执行下一个中间件，最后执行对应Handler。

```
public interface JoyMiddlewareHandler {
    func handle(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit
}
```

## 使用方式

使用方式有两种:

 - use(mw: JoyMiddlewareHandler)：作用于全局或对应的Group下所有请求Handler；
 - apply(mw: JoyMiddlewareHandler)：只作用于对应本次注册请求Handler；

```
// 如使用内置的BasicAuth中间件
// 作用于全局所有请求
joy.router.use(BasicAuth("test-realm", HashMap<String, String>([("test", "test")])))

// group("/users")下所有Handler都会使用BasicAuth
joy.router
  .group("/users")
  .use(BasicAuth(...)))

// BasicAuth 只会作用于 GET `/{name}`
joy.router
   .apply(BasicAuth(...))
   .apply(XXMiddleware)
   .get("/{name}", {ctx: JoyContext => })

// BasicAuth 只会作用于 GET `/users/{name}`
joy.router
  .group("/users")
  .apply(BasicAuth(...))
  .apply(XXMiddleware)
  .get("/{name}", {ctx: JoyContext => })
```


## 内置Middleware

|Middleware|说明|
|---|---|
|BasicAuth|[Basic认证](../../examples/src/simple/main.cj)||
|ExceptionHandler|异常兜底|
|AccessLog|[请求日志](../../doc/usage_guide/logger.md)|
|SessionManager|[会话管理](../../doc/usage_guide/session.md)|
|CORS|跨源资源共享(待验证)|
|RequestId|[请求Id](../../examples/src/requestid/main.cj)|
|NoCache|[禁用缓存](../../examples/src/nocache/main.cj)|
|TokenAuth|[Token认证](../../examples/src/tokenauth//main.cj)|
|CrsfProtect|[CRSF保护](../../examples/src/crsf/main.cj)|
|Security|安全头域设置|
|JwtAuth|[Jwt认证](../../examples/src/jwtauth//main.cj)|

----
<< [返回](../../README.md#使用指导)