
<div align="center">
<h1>CJoy</h1>
a fast，lightweight and joy web framework.<br/>
一个高性能、轻量、省心的Web框架。
</div>

<p align="center">
<img alt="" src="https://img.shields.io/badge/release-v0.20.0-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/cjc-v0.58.3-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/cjcov-70%25+-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/state-孵化-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/domain-HOS/Cloud-brightgreen" style="display: inline-block;" />
</p>

## 样例

### 使用API

```
import cjoy.*

main(): Int64 {
    var cfg = JoyConfig()
    cfg.enableDebugLog=true
    // 创建joy实例
    let joy = Joy.create(cfg)

    // 注册路由
    joy.router.get("/{name}", {ctx: JoyContext => 
        let name = ctx.getParam("name").getOrDefault({=>"no name"})
        ctx.string("name in paramter path, name=${name}")
    })
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

@Get[path = "/users/{name}"]
func getUserName(@PathParam name: String): (UInt16, String) {
    (200, "/users/${name}")
}

@Get[path = "/users", provider="json"]
func listUsers(@QueryParam[name=id] id: String): UserInfo {
    let usr = UserInfo()
    usr.id = id
    usr.name = "xiao"
    usr.address = "shenzhen"
    usr
}

main(): Int64 {
    var cfg = JoyConfig()
    cfg.enableDebugLog = true
    // 创建joy实例
    let joy = Joy.create(cfg)
    // 注册生成的handlers
    JoyHandlers.registerTo(joy)
    joy.run("127.0.0.1", 18881)
    return 0
}
```

更多的样例请参见 [examples](examples/README.md) 。

## 功能

本项目参考了一些其它语言的开源设计与实现，基于Cangjie提供HTTP框架，在其API进一步封装以简化Web应用开发，增加如下能力：

- 基于压缩前辍树的路由管理，支持静态Path，参数匹配Path，正则匹配Path，全路径通配符Path的高效注册与查找，支持路由组；
- 基于拦截器的中间件扩展能力，支持Basic认证等多种能力扩展；
- 基于Context的上下文管理，支持快速获取请求参数与构建Json/Text响应；
- 基于编译宏的Json序列化与反序列，支持对请求与响应消息的Json直接绑定映射；
- 基于编译宏自动注册与参数注入请求处理函数与中间件函数；

应用场景 ：

- API服务：CJoy 可以帮助你快速开发Restful服务并配置路由规则与管理各种资源；
- Web服务：CJoy 的压缩前辍树高性能路由查找，让你的Web服务更具有性能优势；
- 微服务框架：CJoy 的路由组与内置Json编译宏，可以实现微服务各类接口分组管理与接口实现。

## 路由

### 路由规则

注册的path支持四种路由匹配模式，示例如下：

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
* `/articles/{id}:{op}`

示例说明：

- static路由：静态路由，路径不存在`{}`或`*`参数，是path全匹配。
- param路由：单字段参数通配符匹配，路径中字段以`{paramname}`命名，一个Path分段可以存在多个`{paramname}`。
  - 如`/post/{postid}`，可以匹配`/post/1`或`/post/2`，通过上下文接口可以获取参数`postid`值为`1`或`2`，但不能匹配 `/post/1/2`。
  - 如`/post/{postid}/{page}`，可以匹配`/post/1/2`，参数`postid`值为`1`，`page`值为`2`。
  - 如`/articles/{id}:{op}`，可以匹配`/post/1/delete`，参数`id`值为`1`，`op`值为`delete`。
- regex路由：单字段参数正则匹配，路径中字段以`{paramname:regex}`命名，以`:`分隔正则表达式。
  - 如`/{page:[0-9]+}`，可以匹配`/post/1`或`/post/2`。
  - 如`/{page:[0-9]+}-delete`，可以匹配`/post/1-delete`或`/post/2-delete`。
- catchAll路由：捕获所有字段通配符匹配，路径中字段以`*`开头，可能匹配路径中多段。
  - 如`/images/*`： 
    - 可以匹配`/images/abc`，参数`*`值为`abc`; 
    - 也可以匹配`/images/abc/def`，参数`*`值为`abc/def`; 
    - 也可匹配只字符串`/images/`; 参数`*`值为``。

### 路由优先级

路由查找优先级：static路由 > regex路由 > param路由 > catchAll路由。

可以同时存在`/users/{name}`、`/users/abc`、`/users/{name:[a-z]{3,4}}` 与 `/users/*`，路由匹配优先级与注册的顺序无关。

```
router.get("/users/{name}", {ctx: JoyContext => })
router.get("/users/abc", {ctx: JoyContext => })
router.get("/users/{name:[a-z]{3,4}}", {ctx: JoyContext => })
router.get("/users/*", {ctx: JoyContext => })
```

 - 当路径为`/users/abc`，先匹配到static路由`/users/abc`
 - 当路径为`/users/xiao`，匹配到regex路由`/users/{name:[a-z]{3,4}}`
 - 当路径为`/users/xiaoliu`，匹配到param路由`/users/{name}`
 - 当路径为`/users/xiao/abc`，匹配到catchAll路由`/users/*`

其它的示例:

```
router.get("/{page}", {ctx: JoyContext => })
router.get("/{year}/{month}/{post}", {ctx: JoyContext => })
router.get("/{year}/{month}", {ctx: JoyContext => })
router.get("/images/*", {ctx: JoyContext => })
router.get("/favicon.ico", {ctx: JoyContext => })
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
v1.get("/{name}", {ctx: JoyContext => })
v1.get("/abc", {ctx: JoyContext => })
v1.get("/*", {ctx: JoyContext => })
```

JoyRouters接口的group方法支持对path进行分组，分组支持多级，分组的特点：

 - 有相同的path前辍；
 - 同一组使用相同的中间件，并继承父一级path注册的中间件；
 - 调用`v1 = router.group("/v1")`：
   - 会自动注册两个 (`/v1/`, `/v1/*`) NotFound的Handler，匹配所有Method，可用中间件拦截处理；
   - 可以再注册 `v1.get("/"..)`  `v1.get("/*"..)` 覆盖上面的默认Handler；

## Handler

CJoy支持两种路由处理的Handler实现：

  - 实现JoyRequestHandler接口；
  - 使用Lambda表达式函数；

```
// 实现JoyRequestHandler
class UserHandler <: JoyRequestHandler {
    public func handle(ctx: JoyContext): Unit {
	    let name = ctx.getParam("name").getOrDefault({=>"no name"})
	    ...
    }
}
router.get("/{name}", UserHandler())

// 直接采用Lambda表达式函数
router.get("/{name}", {ctx: JoyContext => 
	let name = ctx.getParam("name").getOrDefault({=>"no name"})
	...
})
```

## 中间件

CJoy提供扩展机制支持Http请求进行拦截处理，机制类似于Java的Servlet的Filter。

中间件需要实现JoyMiddlewareHandle接口，其中chain中为所有MiddlewareHandler链，调用`chain.next(ctx)`执行下一个中间件，最后执行对应Handler。

```
public interface JoyMiddlewareHandler {
    func handle(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit
}
```

使用方式有两种:

 - use(mw: JoyMiddlewareHandler)：作用于全局或对应的Group下所有请求Handler；
 - apply(mw: JoyMiddlewareHandler)：只作用于对应注册的Handler；

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

注：
  - 所有中间件与路由Handler注册目前只支持单线程

## 宏

### Handler宏

CJoy提供一系列的宏简化Handler的注册与参数展开，业务只需要实现最简洁的函数，样例可以参见 [test/macro_test.cj](src/test/macro_test.cj) 。

```
@Get[path = "/path/{p}"]
func pathGet(@PathParam[name = p] a: ?String): String {
    println(a)
    a.getOrDefault({=> "p"})
}

@Get[path = "/test"]
func testGet(c: JoyContext): (UInt16, String) {
    c.setCtxParam("Test", 1)
    (200, "helloword")
}
```

Handler注册宏，作用在函数上：

 - `@Get[path="/abc/{id}", provider=json]`
 - `@Post[path="/abc/{name:[a-z]{3,4}}", provider=json]`
 - `@Put[path="/abc/def", provider=json]`
 - `@Delete[path="/abc", provider=json]`
 - `@Patch[path="/abc", provider=json]`
 - `@Header[path="/abc", provider=json]`
 - `@Methods[path="/abc", methods="PUT,POST", provider=json]`

参数说明：

 - `path`：必选，指定handler处理的URL全路由，如果存在对应Group，框架会自动查找，注册到对应的Group上；
 - `provider`：可选，只有响应返回json时指定，且方法返回值必须实现JsonSerializable接口；
 - `methods`: 只有在Methods宏上使用，注册handler处理Method列表；
  
函数参数展开宏，作用在函数入参上：
  
  - `@PathParam[name=id]`：获取param路由的参数值，指定`/abc/{id}`名称，当方法参数名与URL的提取参数名不一样时指定；
  - `@PathParam`：获取param路由的参数值，方法参数名与URL的提取参数名一样；
  - `@QueryParam[name=id，default="abc"]`：获取URL Query参数值，default可选；
  - `@QueryParam`: 获取URL Query参数值，default可选；
  - `@PostFormParam[name=id，default="abc"]`：获取PostForm参数值，default可选；
  - `@PostFormParam`: 获取PostForm参数值，default可选；
  - `@HeaderParam[name=id，default="abc"]`: 获取Header参数值，default可选；
  - `@HeaderParam`: 获取Header参数值，default可选；
  - `@ContextParam[name=id]`: 获取Context参数值；
  - `@ContextParam`: 获取Context参数值；
  - `@CookieParam[name=id]`: 获取Cookie参数值；
  - `@CookieParam`: 获取Cookie参数值；
  - `@BodyParam`: 获取Context参数值；

支持的函数入参类型：

  - `String` ：对于QueryParam, PostFormParam, HeaderParam, CookieParam宏标注的参数；
  - `基本类型`：如Int，PathParam，QueryParam, PostFormParam, HeaderParam宏标注的参数，String转换对应的基本类型；
  - `?String`：QueryParam, PostFormParam, HeaderParam, CookieParam宏标注的参数；
  - `Option<String>`：QueryParam, PostFormParam, HeaderParam, CookieParam宏标注的参数；
  - `ArrayList<String>`：QueryParam, PostFormParam, HeaderParam宏标注的参数有多个值时；
  - `Array<String>` ：QueryParam, PostFormParam, HeaderParam宏标注的参数有多个值时；
  - `任一类型`：ContextParam宏标注的参数；
  - `Option<T> when T <: JsonDeserializable`: BodyParam宏标注的参数；
  - `JoyContext`: 不需要宏标注；

不支持的入参名称：

  - `_`： 不支持忽略参数名称为`_`；

支持的函数返回类型：

  - `String`：响应为`Content-Type=plain/text`，`StatusCode=200`；
  - `(UInt16, String)`：响应为`Content-Type=plain/text`，`StatusCode=${statusCode}`；
  - `(String, UInt16)`：同上；
  - `T when T <: JsonSerializable` ：响应为`Content-Type=application/json`，同时Handler需要指定`provider=json`，`StatusCode=200`；
  - `(UInt16, T when T <: JsonSerializable)`：响应为`Content-Type=application/json`，响应的状态码statusCode，同时Handler需要指定`provider=json`，`StatusCode=${statusCode}`；
  - `(T when T <: JsonSerializable, UInt16)`： 同上；
  - `(UInt16, T <: ToString)`：响应为`Content-Type=plain/text`，`StatusCode=${statusCode}`；
  - `(T <: ToString, UInt16)`：同上；
  - `UInt16`: 响应`StatusCode=${statusCode}`；
  - `Unit`: 无返回类型，响应`StatusCode=200`；
  - ` `: 无返回类型，响应`StatusCode=200`；

### Middleware宏

```
@Middleware[groups="/a/b/c,/a/c"]
func testMiddleware(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
    chain.next(ctx)
}
```

Middleware注册宏，作用在函数上：

- `@Middleware[groups="/a,/b"]`

参数说明：

- `groups`: 多个group的全路径。如果路径是/a/b/c，会自动生成`let g = group("/a").group("/b").group("/c")`，但Middleware只会注册到`group /a/b/c`

注：
 
 - Middleware要先于Handler注册
 - 即`JoyMiddlewares.registerTo(joy)` 需要在 `JoyHandlers.registerTo(joy)` 前调用 

## Json

CJoy内置支持采用宏对类与结构体标注，简化对HTTP Body的Json序列化与反序列化绑定与映射。

```
import cjoy.json.*

@Json
class UserInfo {
    var name: String = ""
    @JsonField[omitempty = true]
    var address: String = ""
    @JsonField[name = gender]
    var gender: Int = 0
}
```

- `@Json`：作用于类与结构体上，标注其自动生成Json序列化与反序列化函数，类与结构体需要无参数的构建函数。
- `@JsonField`：作用类与结构体的成员变量上，变量需要采用var声明，并支持指定类型，宏JsonField有如下参数：
  - `name`：指定Json的字段名称；
  - `omitempty`：值true/false，指定生成Json字符串时是否忽略空字符串或Option的None值，默认为false；
  - `ignore`：值true/false，指定是否忽略此字段，默认为false；
  - `timeformat`：指定DateTime字段序列化的格式，默认为DateTime.toString/parse方法默认格式。

宏展开编译之后，此类与结构体会实现encoding.json.stream包下JsonSerializable与JsonDeserializable接口。

JoyContext提供两个函数支持对HTTP Body的绑定与映射：

 - `readJsonBody`：对Body内容反序列化为类与结构体
 - `json`: 序列化类与结构体对象序列化并设置Body内容

使用示例：[examples/rest](examples/rest/src/main.cj)

## 参与贡献

欢迎给我们提交 PR，欢迎给我们提交 Issue，欢迎参与任何形式的贡献。

fork时请保留上游仓库地址[Cangjie-SIG/cjoy](https://gitcode.com/Cangjie-SIG/cjoy) 或 [lanlingx/cjoy](https://gitcode.com/lanlingx/cjoy) 。

本项目的维护者是 [@lanlingx](https://gitcode.com/lanlingx) 。

## 协议

参考 [LICENSE](LICENSE) 文件。