CJoy - a fast and joy web framework
=======

一个高性能、轻量、省事的Web框架。

## 样例

```
import cjoy.*

main(): Int64 {
    var cfg = JoyConfig()
    cfg.enableDebugLog=true
    // 创建joy实例
    let joy = Joy.create(cfg)

    // 注册路由
    joy.router.GET("/{name}", {ctx: JoyContext => 
        let name = ctx.getParam("name").getOrDefault({=>"no name"})
        ctx.string("name in paramter path, name=${name}")
    })
    joy.router.GET("/abc", {ctx: JoyContext => 
        ctx.string("static path abc")
    })

    // 启动服务
    joy.run("127.0.0.1", 18881)
    return 0
}
```

## 功能

本项目是基于Cangjie提供http框架，参考了一些其它语言的开源设计，在其API进一步封装以简化Web应用开发，增加如下能力：

- 基于patricia树的路由管理，支持静态Path，参数匹配Path，正则匹配Path，全路径通配符Path的高效注册与查找，支持路由组；
- 基于拦截器的中间件扩展能力，支持Basic认证等多种能力扩展；
- 基于Context的上下文管理，支持快速获取请求参数与构建Json/Text响应；
- 基于编译宏的Json序列化与反序列，支持对请求与响应消息的Json直接绑定映射。

应用场景 ：

- API服务：cjoy可以帮助你快速开发Restful服务并配置路由规则与管理各种资源；
- Web服务：cjoy的patricia树高性能路由查找，让你的Web服务更具有性能优势；
- 微服务框架： cjoy的路由组与内置Json编译宏，可以实现微服务各类接口分组管理与接口实现。

## 路由

### 路由规则

注册的path支持四种路由格式，示例如下：

* `/post/all`
* `/post/{postid}`
* `/post/{postid}/page/{page}`
* `/post/{postid}/{page}`
* `/images/*`
* `/favicon.ico`
* `/{year}/{month}`
* `/{year}/{month/{post}`
* `/{page:[0-9]+}`
* `/{page:[0-9]+}-delete`

示例说明：

- static路由： 静态路由，路径不存在`{}`或`*`参数，是path全匹配。
- param路由： 单字段参数通配符匹配，路径中字段以`{paramname}`命名。
  - 如`/post/{postid}`，可以匹配`/post/1`或`/post/2`，通过上下文接口可以获取参数`postid`值为`1`或`2`，但不能匹配 `/post/1/2`。
  - 如`/post/{postid}/{page}`，可以匹配`/post/1/2`，参数`postid`值为`1`，`page`值为`2`。
- regex路由： 单字段参数正则匹配，路径中字段以`{paramname:regex}`命名，以`:`分隔正则表达式。
  - 如`/{page:[0-9]+}`，可以匹配`/post/1`或`/post/2`。
  - 如`/{page:[0-9]+}-delete`，可以匹配`/post/1-delete`或`/post/2-delete`。
- catchAll路由： 捕获所有字段通配符匹配，路径中字段以`*`开头，可能匹配路径中多段。
  - 如`/images/*`： 
    - 可以匹配`/images/abc`，参数`*`值为`abc`; 
    - 也可以匹配`/images/abc/def`，参数`*`值为`abc/def`; 
    - 也可匹配只字符串`/images/`; 参数`*`值为``。


### 路由优先级

路由查找优先级： static路由 > regex路由 > param路由 > catchAll路由。

可以同时存在`/users/{name}`、`/users/abc`、`/users/{name:[a-z]{3,4}}`与`/users/*`，路由匹配优先级与注册的顺序无关。

```
router.GET("/users/:name", {ctx: JoyContext => })
router.GET("/users/abc", {ctx: JoyContext => })
router.GET("/users/{name:[a-z]{3,4}}", {ctx: JoyContext => })
router.GET("/users/*", {ctx: JoyContext => })
```

 - 当路径为`/users/abc`，先匹配到static路由`/users/abc`
 - 当路径为`/users/xiao`，匹配到regex路由`/users/{name:[a-z]{3,4}}`
 - 当路径为`/users/xiaoliu`，匹配到param路由`/users/{name}`
 - 当路径为`/users/xiao/abc`，匹配到catchAll路由`/users/*`

其它的示例:

```
router.GET("/{page}", {ctx: JoyContext => })
router.GET("/{year}/{month}/{post}", {ctx: JoyContext => })
router.GET("/{year}/{month}", {ctx: JoyContext => })
router.GET("/images/*", {ctx: JoyContext => })
router.GET("/favicon.ico", {ctx: JoyContext => })
```

- `/abc` 匹配到 `/{page}`
- `/2024/05` 匹配到 `/{year}/{month}`
- `/2024/05/really-great-blog-post` 匹配到 `/{year}/{month}/{post}`
- `/images/image.gif` 匹配到 `/images/*`
- `/images/2014/05/image.jpg` 匹配到 `/images/*`
- `/favicon.ico` 匹配到 `/favicon.ico`

### 分组

```
let router = joy.router
// group
let v1 = router.group("/v1")
v1.GET("/{name}", {ctx: JoyContext => })
v1.GET("/abc", {ctx: JoyContext => })
v1.GET("/*", {ctx: JoyContext => })
```

JoyRouters接口的group方法支持对path进行分组，分组支持多级，分组的特点：

 - 有相同的path前辍；
 - 同一组使用相同的中间件，并继承父一级path注册的中间件。

## Handler

Cjoy支持两种路由处理的Handler实现，一种是实现JoyRequestHandler，一种是Lambda表达式函数。

```
// 实现JoyRequestHandler
class UserHandler <: JoyRequestHandler {
    public func handle(ctx: JoyContext): Unit {
	   let name = ctx.getParam("name").getOrDefault({=>"no name"})
	   ...
    }
}

router.GET("/{name}", UserHandler())

// 直接采用Lambda表达式函数
router.GET("/{name}", {ctx: JoyContext => 
	let name = ctx.getParam("name").getOrDefault({=>"no name"})
	...
})
```


## 中间件

Cjoy提供扩展机制，支持Http请求进行拦截处理，机制类似于java的servlet的filter，其中chain中为所有MiddlewareHandler链。

```
// 如使用内置的BasicAuth中间件
router.use(BasicAuth("test-realm", HashMap<String, String>([("test", "test")])))
```

中间件需要实现JoyMiddlewareHandle接口。

```
public interface JoyMiddlewareHandler {
    func handle(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit
}
```

## 参与贡献

欢迎给我们提交 PR，欢迎给我们提交 Issue，欢迎参与任何形式的贡献。

fork时请保留上游仓库地址[Cangjie-SIG/cjoy](https://gitcode.com/Cangjie-SIG/cjoy) 或 [lanlingx/cjoy](https://gitcode.com/lanlingx/cjoy)

## 协议

参考 [LICENSE](LICENSE) 文件。