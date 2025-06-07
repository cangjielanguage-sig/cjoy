<div align="center">
<h1>CJoy</h1>
a fast，lightweight and joy web framework.<br/>
一个高性能、轻量、省心的Web框架。
<br/>
<img alt="" src="doc/imgs/logo.png" height="118" width="200" style="display: inline-block;" />
</div>

<p align="center">
<img alt="" src="https://img.shields.io/badge/release-v0.30.0-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/cjc-v0.60.5-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/cjcov-70%25+-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/state-孵化-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/domain-HOS/Cloud-brightgreen" style="display: inline-block;" />
</p>

## 快速开始

**⚠️注意**

请选择对应的仓颉版本：<img alt="" src="https://img.shields.io/badge/cangjie-v0.60.5-brightgreen" style="display: inline-block;" />

本项目依赖Cangjie stdx包，请先下载对应版本的stdx包，使用说明参见 [仓颉编程语言 stdx](https://gitcode.com/Cangjie/Cangjie-STDX) 。

本项目配置要求，请把对应的stdx包解压到与Cangjie SDK并列目录cangjiestdx下：

 - cangjie ： Cangjie SDK目录
 - cangjiestdx ： 新建此目录
   - linux_x86_64_llvm ： 解压对应的stdx包，不同OS目录名称不同

如果stdx包不是按上述目录配置，请修改cjoy中cjpm.toml对应`[target.xx.bin-dependencies]`的`path-option`。

推荐在Linux(或WSL)，MacOS中运行仓颉。

### 运行本项目的示例

您可以先 `git clone https://gitcode.com/Cangjie-SIG/cjoy.git` 到您本地。

通过 `cjpm run --name <package-name>` 运行对应样例：

```
cjpm test 
cjpm build 
cjpm run --name cjoy.examples.tls
```

### 添加对本项目的依赖

在您的项目cjpm.toml文件增加如下：

```
[dependencies]
  cjoy = { git = "https://gitcode.com/Cangjie-SIG/cjoy.git", branch = "main" }
```


## 快速了解

### 使用API

```
import cjoy.*

main(): Int64 {
    var cfg = JoyConfig()
    cfg.enableDebugLog = true
    // 创建joy实例
    let joy = Joy.create(cfg)

    // 注册路由
    joy.router.get("/{name}", {ctx: JoyContext => 
        let name = ctx.getParam("name") ?? "no name"
        ctx.string("name in parameter path, name=${name}")
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
func listUsers(@QueryParam[name = id, default = 00009527] id: String): Array<UserInfo> {
    let usr = UserInfo()
    usr.id = id
    usr.name = "xiao"
    usr.address = "shenzhen"
    [usr]
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

更多的样例请参见 [examples](src/examples/README.md) 。

## 特性

本项目参考了一些其它语言的开源设计与实现，在Cangjie提供的HTTP框架基础上进一步封装以简化Web应用开发，增加如下能力：

- 基于压缩前辍树的路由管理，支持静态Path，参数匹配Path，正则匹配Path，全路径通配符Path的高效注册与查找，支持路由组；
- 基于拦截器的中间件扩展能力，支持Basic认证等多种能力扩展；
- 基于Context的上下文管理，支持快速获取请求参数与构建Json/Text响应；
- 基于编译宏的Json序列化与反序列，支持对请求与响应消息的Json直接绑定映射;
- 基于编译宏支持自动注册与参数注入请求处理函数与中间件函数;
- 基于编译宏支持对请求参数校验；
- 支持文件下载与上传，WebSocket，SSE等内置能力;

应用场景 ：

- API服务：CJoy 可以帮助你快速开发Restful服务并配置路由规则与管理各种资源；
- Web服务：CJoy 的压缩前辍树高性能路由查找，让你的Web服务更具有性能优势；
- 微服务框架：CJoy 的路由组与内置Json编译宏，可以实现微服务各类接口分组管理与接口实现。

## 功能介绍

### 路由

#### 路由规则

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
  - 如`/articles/{id}:{op}`，可以匹配`/post/1:delete`，参数`id`值为`1`，`op`值为`delete`。
- regex路由：单字段参数正则匹配，路径中字段以`{paramname:regex}`命名，以`:`分隔正则表达式。
  - 如`/{page:[0-9]+}`，可以匹配`/post/1`或`/post/2`。
  - 如`/{page:[0-9]+}-delete`，可以匹配`/post/1-delete`或`/post/2-delete`。
- catchAll路由：捕获所有字段通配符匹配，路径中字段以`*`开头，可能匹配路径中多段。
  - 如`/images/*`： 
    - 可以匹配`/images/abc`，参数`*`的值为`abc`; 
    - 也可以匹配`/images/abc/def`，参数`*`的值为`abc/def`; 
    - 也可以匹配`/images/`; 参数`*`的值为空字符串。

#### 路由优先级

路由查找优先级：static路由 > regex路由 > param路由 > catchAll路由。

可以同时存在`/users/`开头的多个Path，路由匹配优先级与注册的顺序无关。

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

#### 分组

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
 - 使用相同的中间件，并继承父一级Path注册的中间件；
 - 调用`router.group("/v1")`：
   - 会默认自动注册三个Path: `/v1`,  `/v1/`,  `/v1/*`的`NotFoundHandler`，Method为"GET", "POST", "DELETE", "PUT", "PATCH", "HEAD", "OPTIONS"，以便让其Group的中间件可拦截此Group的所有URL；
   - 可以再注册 `v1.get("", ...)`  `v1.get("/", ...)`  `v1.get("/*", ...)` 覆盖上面的默认Handler；
  

### 请求处理

#### Handler

CJoy支持两种请求处理Handler实现。

##### 实现接口

JoyRequestHandler定义参见  [handler.cj](src/framework/handler.cj) 。

```
// 实现JoyRequestHandler
class UserHandler <: JoyRequestHandler {
    public func handle(ctx: JoyContext): Unit {
	    let name = ctx.getParam("name") ?? "no name"	    ...
    }
}
router.get("/{name}", UserHandler())
```

##### Lambda表达式函数

```
// 直接采用Lambda表达式函数
router.get("/{name}", {ctx: JoyContext => 
	let name = ctx.getParam("name") ?? "no name"
	...
})
```

HTTP的Handler通过调用JoyRouters的get, post, put等方法注册到路由分组上。JoyRouters接口定义参见 [route.cj](src/framework/route.cj) 。

#### 处理上下文

Handler的入参JoyContext提供上下文支持对HTTP获取与回响应处理，主要API如下，请多的API请参见源码 [context.cj](src/framework/context.cj)  。

|函数|说明|
|---|---|
|getCtxParm|获取上下文参数，如在Middleware中设置上下文信息|
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

#### Middleware

CJoy提供扩展机制支持HTTP请求进行拦截处理，机制类似于Java的Servlet Filter。

中间件需要实现JoyMiddlewareHandle接口，其中chain对象为所有MiddlewareHandler链，调用`chain.next(ctx)`执行下一个中间件，最后执行对应Handler。

```
public interface JoyMiddlewareHandler {
    func handle(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit
}
```

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

注：
  - 所有中间件与路由Handler注册目前只支持单线程

### 宏

#### Handler宏

CJoy提供一系列的宏简化Handler的注册与参数展开，业务只需要实现最简洁的函数。样例可以参见 [test/macro_test.cj](src/test/macro_test.cj) 。

```
@Get[path = "/path/{p}"]
func pathGet(@PathParam[name = p] a: ?String): String {
    println(a)
    a ?? "p"
}

@Get[path = "/test"]
func testGet(c: JoyContext): (UInt16, String) {
    c.setCtxParam("Test", 1)
    (200, "helloword")
}
```

Handler注册宏，作用在函数上：

|宏|属性参数|说明|
|---|---|---|
|`@Get`|path="/abc/{id}",produce=json|GET请求。|
|`@Post`|path="/abc/{name:[a-z]{3,4}}",produce=json|POST请求。|
|`@Put`|path="/abc/def",produce=json|PUT请求。|
|`@Delete`|path="/abc",produce=json|DELETE请求。|
|`@Patch`|path="/abc",produce=json|PATCH请求。|
|`@Head`|path="/abc",produce=json|HEAD请求。|
|`@Handler`|path="/abc",produce=json，methods="PUT,POST"|通过methods指定METHOD请求。|

|宏属性参数|默认值|是否可选|说明|
|---|---|---|---|
|`path`||否|指定handler处理的URL全路由，如果存在对应Group，框架会自动查找，注册到对应的Group上|
|`produce`|text|是|值为text/json，只有响应返回json时指定，且方法返回值必须实现JsonSerializable接口，默认是返回文本Body|
|`methods`||是|只有在Handler宏上使用，注册handler的Method列表|

备注：

  - `@Get[path="/users/{id}"]`，如果存在`@Middleware[groups="/users"]`，则它会创建`Group /users`，则此GET Handler会注册到`Group /users`下
  
函数参数展开宏，作用在函数入参上：

|宏|属性参数|说明|
|---|---|---|
|`@PathParam`|name=id, timeformat="HH:mm:ss MM/dd/yyyy OO"|获取param路由的参数值，如`/abc/{id}`，当方法参数名与URL的提取参数名不一样时指定name属性，属性都可选。|
|`@QueryParam`|name=id，default="abc", timeformat="HH:mm:ss MM/dd/yyyy OO"|获取URL Query参数值，属性都可选。|
|`@PostFormParam`|name=id，default="abc", timeformat="HH:mm:ss MM/dd/yyyy OO"获取PostForm参数值，属性都可选。|
|`@HeaderParam`|name=id，default="abc", timeformat="HH:mm:ss MM/dd/yyyy OO"|获取Header参数值，属性都可选。|
|`@ContextParam`|name=id|获取Context参数值，属性都可选。|
|`@CookieParam`|name=id|获取Cookie参数值，属性都可选。|
|`@BodyParam`||获取Body参数值。|
|`@QueryBindParam`||URL Query多个参数绑定到对象。|
|`@PostFormBindParam`||PostForm多个参数绑定到对象。|
|`@HeaderBindParam`||Header多个参数绑定到对象。|

以上宏属性参数说明： 

|宏属性参数|是否可选|说明|
|---|---|---|
|`name`|是|映射的参数名称，不指定取方法参数名称。|
|`default`|是|获取不到时的默认值。|
|`timeformat`|是|当方法入参是`DateTime`，`?DateTime`时，指定转换的格式。|

支持的函数入参类型：

|参数类型|绑定的宏|说明|
|---|---|---|
|`String`, `?String`|PathParam，QueryParam, PostFormParam, HeaderParam, CookieParam, BodyParam||
|`基本类型`, `?基本类型`|PathParam，QueryParam, PostFormParam, HeaderParam, CookieParam|如Int,String转换对应的基本类型|
|`DateTime`, `?DateTime`|PathParam，QueryParam, PostFormParam, HeaderParam|String转换Datetime|
|`ArrayList<String>`|QueryParam, PostFormParam, HeaderParam|宏标注的参数有多个值时|
|`Array<String>`|QueryParam, PostFormParam, HeaderParam|宏标注的参数有多个值时|
|`任一类型`|ContextParam||
|`T <: JsonDeserializable`，`?T where T <: JsonDeserializable`|BodyParam|Json Body|
|`T <: JoyBindable`, `?T where T <: JoyBindable`|QueryBindParam, PostFormBindParam, HeaderBindParam|参见绑定参数章节|
|`JoyContext`||不需要宏标注|


不支持的入参名称：

  - `_`： 不支持忽略参数名称为`_`；

支持的函数返回类型：

|返回值个数|类型|说明|
|---|---|---|
|0||无返回类型，响应`StatusCode=200`|
|1|`String`|响应为`Content-Type=plain/text`，`StatusCode=200`|
|1|`T where T <: JsonSerializable`|响应为`Content-Type=application/json`，同时Handler需要指定`produce=json`，`StatusCode=200`|
|1|`UInt16`|响应`StatusCode=${statusCode}`|
|1|`Unit`|响应`StatusCode=200`|
|2|`(UInt16, String)`|响应为`Content-Type=plain/text`，`StatusCode=${statusCode}`|
|2|`(String, UInt16)`|同上|
|2|`(UInt16, T where T <: JsonSerializable)`|响应为`Content-Type=application/json`，响应的状态码statusCode，同时Handler需要指定`produce=json`，`StatusCode=${statusCode}`|
|2|`(T where T <: JsonSerializable, UInt16)`|同上|
|2|`(UInt16, T where T <: ToString)`|响应为`Content-Type=plain/text`，`StatusCode=${statusCode}`|
|2|`(T where T <: ToString, UInt16)`|同上|

#### Middleware宏

```
@Middleware[groups = "/a/b/c,/a/c"]
func testMiddleware(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
    chain.next(ctx)
}
```

Middleware注册宏，作用在函数上：

|宏|属性参数|说明|
|---|---|---|
|`@Middleware`|groups="/a,/b"|指定多个Group的全路径。<br/>如果路径是`/a/b/c`，会自动生成`let g = group("/a").group("/b").group("/c")`，<br/>但Middleware只会注册到`Group /a/b/c`，如果不带groups属性，则Middleware注册到根Group。|

#### 注册

所有的 Handler 注册宏生成的类会自动加到JoyHandlers上，Middleware注册宏生成的类会自动加到JoyMiddlewares上，但目前没有自动加到在服务实例Joy上。

```
JoyMiddlewares.registerTo(joy)
JoyHandlers.registerTo(joy)
joy.run("127.0.0.1", 18881)
```

 - 需要在服务实例启动之前，需要显式地调用`JoyMiddlewares.registerTo(joy)`与`JoyHandlers.registerTo(joy)`，把自动生成Handler注册到实例上；
 - Middleware要先于Handler注册，即`JoyMiddlewares.registerTo(joy)` 需要在 `JoyHandlers.registerTo(joy)` 前调用；

### 参数绑定

CJoy提供宏与API支持对Query，PostForm，Header多个参数绑定到一个对象上。

```
import cjoy.bind.*

@Bind
public struct BindParam {
    let str: String // 宏展开时会生成构造函数对其赋值，也可@BindField[default = abc] 指定默认值
    var str2: ?String = None
    var i64: Int64 = 0
    @BindField[name = int]
    var i2_64: Int = 0
    var i3_64: ?Int = None
    var arr: Array<String> = []
    var list: ArrayList<String> = ArrayList<String>()
}

router.get("/bind", {ctx: JoyContext =>
    // 自动把query参数绑定对BindParam对象上
    let params = ctx.bindQuery<BindParam>()
    ctx.string("bind")
})
```

|宏|属性参数|说明|
|---|---|---|
|`@Bind`||作用于类与结构体上，支持对参数的绑定映射。|
|`@BindField`|name=xx,default=xxx,timeformat="..."| 作用类与结构体的成员变量上，变量需要指定类型。|

以上宏的属性参数说明：

|宏属性参数|默认值|是否可选|说明|
|---|---|---|---|
|`name`||是|指定绑定映射的字段名称，不指定为成员变量名|
|`default`||是|当参数不存在时的默认值|
|`timeformat`|DateTime.toString/parse方法默认格式|是|指定DateTime字段序列化的格式|

宏展开编译之后，此类与结构体会：

 - 并自动生成所有成员变量带命名参数的构造方法。因此let成员变量未指定默认值时，会在构造方法采用系统默认值，如Int为`0`， String为`""`。
 - 实现`cjoy.JoyBindable`接口，

字段类型支持：

  - `String`, `?String`
  - `基本类型`, `?基本类型`
  - `Array<String>`, `ArryList<Strng>`
  - `DateTime`, `?DateTime`

JoyContext提供三个方法

 - `bindQuery`：把Query参数绑定到对象上；
 - `bindPostForm`：把PostForm参数绑定到对象上；
 - `bindHeader`：把Header参数绑定到对象上；

### Json

CJoy内置支持采用宏对类与结构体标注，简化对HTTP Body的Json序列化与反序列化绑定与映射。

#### 基础用法

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

约束：

 - 每个成员变量需要指定类型与默认值

|宏|属性参数|说明|
|---|---|---|
|`@Json`||作用于类与结构体上，标注其自动生成Json序列化与反序列化函数，类与结构体需要无参数的构建函数。|
|`@JsonField`|name=xx,omitempty=true,ignore=false,timeformat="..."|作用类与结构体的成员变量上，变量需要采用var声明并要指定类型。|
|`@Jsonable`||原生Json DSL，作用于满足JSON格式的一串符号上，把它转成JsonSerializable对象，可以调用JsonTool.toJson方法序列化为json字符串。|

以上宏的属性参数说明：

|宏属性参数|默认值|是否可选|说明|
|---|---|---|---|
|`name`||是|指定Json的字段名称，不指定为成员变量名|
|`omitempty`|false|是|值true/false，指定生成Json字符串时是否忽略空字符串或Option的None值|
|`ignore`|false|是|值true/false，指定是否忽略此字段|
|`timeformat`|DateTime.toString/parse方法默认格式|是|指定DateTime字段序列化的格式|
|`raw`|false|是|当类型为Any，不反序列化此字段赋值原始字符串字节Array<Byte>|

宏展开编译之后，此类或结构体:

- 并自动生成所有成员变量带命名参数的构造方法。成员变量未指定默认值时，会在构造方法采用系统默认值，如Int为`0`， String为`""`。
- 实现stdx.encoding.json.stream包下JsonSerializable与JsonDeserializable接口。

JoyContext提供两个函数支持对HTTP Body的绑定与映射：

 - `readJson` 或者 `bindJsonBody`：对Body内容反序列化为类与结构体
 - `json`: 序列化类与结构体对象序列化并设置Body内容

使用示例：[examples/rest](src/examples/rest/main.cj) 。

#### 高级用法

更多的使用方式请参考 [test/json_test](src/test/json_test.cj) 。

##### Any类型绑定

一些反序列化场景，可以通过定义Any类型泛化接收不同Json类型，如下所示。

假定字符串为：

```
{
  "a": 1, 
  "b": 1.1, 
  "c": {
    "c1": "c1v", 
    "c2": 1.1
  }, 
  "d":[
    {
      "d1": true, 
      "d2": null
    },
    {
      "d1": false, 
      "d2": "d2v"
    }
  ]
}
```

可以指定如下类来接收绑定：

```
@Json
public class DataAny {
    var a: Any = 1 // 实际反序列化之后类型为Int64
    var b: Any = 2 // 实际反序列化之后类型为Float64
    var c: Any = Option<Any>.None // 实际反序列化之后类型为HashMap<String, Any>
    var d: Any = Option<Any>.None // 实际反序列化之后类型为List<HashMap<String, Any>>
}
```

反序列化映射关系如下，可以把Any向下转型为对应仓颉数据类型。

|Json类型|仓颉类型|
|---|---|
|JsonObject|`HashMap<String, Any>`|
|JsonAray|`ArrayList<Any>`|
|JsonBool|Bool|
|JsonNumber|Int64或Float64|
|JsonString|String|
|JsonNull|`Option<Any>.None`|

##### 获取原始Json内容

当一个字段反序列化时，不展开解释只获取原始字节，可以通过`@JsonField`指定`raw=true`：

```
@Json
public class DataAny {
    var a: Any = 1 
    var b: Any = 2 
    var c: Any = Option<Any>.None 
    @JsonField[raw = true]
    var d: Any = Option<Any>.None // 实际反序列化之后类型为Array<Byte>
}
```

上述`d`的实际值为下面的字符串对应的`Array<Byte>`类型：

```
[
  {
    "d1": true, 
    "d2": null
  },
  {
    "d1": false, 
    "d2": "d2v"
  }
]
```

##### Json DSL

宏`@Jsonable`用于构建原生Json对象，如下所示：

```
let x = "xyz"
let d = @Jsonable(
    {
        "a":{
            "a1":1,
            "a2":x,
            "a3":{
                "a3a":1,
                "a3b":x,
                "a3c":true
            },
            "a4":[1,2]
        },
        "b":[1,2],
        "c":true
    }
)
let str = JsonTool.toJson(d)
println(str) // 输出 {"a":{"a1":1,"a2":"xyz","a3":{"a3a":1,"a3b":"xyz","a3c":true},"a4":[1,2]},"b":[1,2],"c":true}
```

`@Jsonable`支持：

 - 变量替换，如上述的`x`变量
 - 字符串插值，如@Jsonable(["${x}", "abc"])

搭配在请求处理Handler中使用示例：

```
@Get[path = "/json"]
func pathGet(): JsonSerializable {
  let x = "xyz"
  @Jsonable({
      "a": x, 
      "b": "123"
  })
}
```

### 校验

CJoy 内置校验框架，支持通过宏对类，结构，函数参数进行校验。

#### 类与结构体

```
import cjoy.validation.*
import cjoy.json.*

@Valid
@Json
public struct Data {
    @Length[min = 0, max = 10, msg = "failure message tip"]
    @NotBlank
    @NotEmpty
    var str: String = "str"

    @NumberRange[min = 0, max = 123456789]
    var u32: UInt32 = 12345678

    @Size[max = 6]
    @NestedValid
    @NumberRange[min = 0, max = 123456789]
    var arr: Array<Int32> = [1, 2, 3, 4]

    @DateTimeRange[before = "DateTime.now().addDays(1)"]
    var data: DateTime = DateTime.now()

    @NestedValid
    var nestedData: NestedData = NestedData()
}
```

- 宏展开之后，会自动实现`JoyValidatable`接口，可以调用其`validate`方法进行对成员属性校验，若校验未通过，则抛出`JoyValidationException`异常。
- 宏`@Valid`可以与`@Json`,`@Bind`一起使用。

#### 函数参数

```
@Validated
func test(@Size[max = 6] arrparam: Array<Int32>): Unit {
}
```

宏展开之后会修改函数的实现，在最前面对宏标注的参数进行检查。

```
func test( arrparam: Array<Int32>): Unit {
    // 自动插入代码
    arrparam.validate("", false, SizeConstraint(0, 6, ""))
}
```

**注：** 目前受仓颉宏限制，不支持一个函数参数使用多个宏标注。函数参数校验 **仅为实验性探索**。参见Issue：[【需求】函数的参数支持多个宏标注](https://gitcode.com/Cangjie/UsersForum/issues/1924)

#### 宏说明

|宏|属性参数|说明|
|---|---|---|
|`@Size`|min=0, max=100, msg="..."|对Collection对象的Size进行校验|
|`@Length`|min=0, max=100, msg="..."|对字符串对象的长度进行校验|
|`@NumberRange`|min=0, max=100, msg="..."|对数字范围进行校验|
|`@NotEmpty`|msg="..."|对字符串对象非空进行校验|
|`@NotBlank`|msg="..."|对字符串对象非空白进行校验，先trim再检查|
|`@Patten`|regex="...", msg="..."|对字符串，数字正则检查|
|`@DateTimeRange`|before="...", after="...", msg="..."|对DateTime范围进行校验，before与before支持写表达式，要求值为DateTime|
|`@Valid`||作用于类或结构体，生成代码实现`JoyValidatable`接口|
|`@NestedValid`||作用于类或结构体的成员变量，表示对此成员类与结构嵌套校验，如果是HashMap，Array, ArrayList，则会对其容器内元素校验，校验规则共用此成员变量的宏标注|
|`@Validated`||作用于函数上，生成代码会修改函数体增加调用参数的`validate`方法|

### 分块传输

CJoy 提供对Chunked的封装，支持Chunked数据以及SSE(Server-Sent Events)的发送。

#### Chunked

```
router.get("/chuncked", {ctx: JoyContext =>
    let writer = ctx.chunkedWriter()
    for (num in 1..10) {
        writer.write(num.toString())
        sleep(Duration.millisecond*200)
    }
    writer.end()
})
```

 - 调用`JoyContext.chunkedWriter()` 创建 JoyPusherWriter
 - 调用`JoyChunkedWriter.write(...)` 写块数据，每调用一次发送一次Chunked
 - 调用`JoyChunkedWriter.end` 写结束块

#### SSE

```
router.get("/sse", {ctx: JoyContext =>
    let emitter = ctx.eventEmitter()
    for (num in 1..10) {
        emitter.sendEvent(JobServerEventBuilder().data("{\"num\":\"${num}\"}"))
        sleep(Duration.millisecond*200)
    }
    emitter.end()
})
```
 - 调用`JoyContext.eventEmitter()` 创建 JoySseEmitter
 - 使用`JobServerEventBuilder` 构建 SSE 数据，调用`JoySseEmitter.sendEvent(...)`，每调用一次发送一次Event
 - 调用`JoySseEmitter.end` 写结束块


### 文件服务器

CJoy 提供文件服务器的封装，提供两个API：`staticFile` 与 `staticFs`。

#### 单个文件路由

示例：`router.staticFile("/static/favicon.ico", "./resources/favicon.ico")`

#### 多文件路由

示例：`router.staticFs("/static", "/var/www")`

指定URL Path与本地路径，框架会注册`/static/*`的路由，支持如下映射：

  - `/static/a.png` <--> `/var/www/a.png`
  - `/static/a/b/c/d.png` <--> `/var/www/a/b/c/d.png`

约束：

- URL Path映射只能是本地文件，且不能是隐藏文件，不能是子目录;
- URL Path中禁止使用`..` 遍历上层路径;

### WebSocket

CJoy 提供WebSocket的封装，简化WebSocket消息接收与响应。

#### 路由注册

示例：`router.websocket("/ws/chat/{name}", TextEchoJoyWebSocketHandler())`

调用`JoyRouters.websocket`注册路由，与调用`get`函数类似，也支持中间件拦截WebSocket握手时的请求消息。

#### Handler

接收消息需要实现接口`JoyWebSocketHandler`，回调函数说明：

 - `supportedSubProtocols`：设置支持的SubProtocols，默认为空
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

使用示例：[examples/websocket](src/examples/websocket/main.cj) 。

### MultiPart

CJoy 提供对 `multipart` 的解释、数据缓存，提供API简化使用。

使用示例：[examples/multipart](src/examples/multipart/main.cj) 。

#### 内置缓存

框架内置缓存支持文本的内存与文件磁盘缓存，通过API直接获取缓存内容。

```
import cjoy.*
import cjoy.multipart.*

router.post("/saveUserInfo1", {ctx: JoyContext =>
    var config = JoyMultiPartConfig()
    config.fileCacheDir = "./test_tmp"
    try (form = JoyMultiPartForm.create(ctx, config)) {
        form.parse()
        // 获取form-data; name="id"
        if (let Some(id) <- (form.getPart("id")?.getText() ?? None)) {
            println(id)
        }
        // 获取form-data; name="photo"; filename="00009527.png"
        if (let Some(file) <- (form.getPart("photo")?.getFile() ?? None)) {
            let tempPath = Path("./photos")
            copy(file.info.path, to: tempPath.join(file.info.name))
        }
    }
    ctx.ok()
  }
)
```

- `JoyMultiPartForm `：实现 `Resource` 接口，需要使用 `try()` 确保缓存的临时对象在退出时被清理。
  - `parse()`: 解释表单内容
  - `getPart(name)`: 获取MultiPart对象
- `JoyMultiPart`
  - `text`: 获取表单文本内容
  - `file`: 获取表单上传文件缓存磁盘文件对象，用户可移动，拷贝到其它目标目录。当`JoyMultiPartConfig.fileCacheDir`不为空时，文件缓存在指定的目录下
  - `fileContent`: 获取表单上传文件缓存在内存中内容。当`JoyMultiPartConfig.fileCacheDir`为空时，默认缓存在内存中
  - `name`: 获取表单名称
  - `fileName`: 获取表单上传文件名
  - `contentType` : 获取表单上传文件类型

#### 自定义Handler

框架支持对每个Part注册处理类，可在边解释Http Body时边回调，减少对内存与文件复制，适合于上传的文件直接存储到第三方的文件系统。

```
router.post("/saveUserInfo2", {ctx: JoyContext =>
    var config = JoyMultiPartConfig()
    try (form = JoyMultiPartForm.create(ctx, config)) {
        // 先注册回调的Handler
        // 处理form-data; name="id"
        form.handlePart("id", {part: JoyMultiPart, data: Array<Byte> =>
            let text = String.fromUtf8(data)
            println("${part.name}=${text}")
          }
        )
        // 处理form-data; name="photo"; filename="00009527.png"
        let tempPath = Path("./photos")
        form.handlePart("photo", {part: JoyMultiPart, data: Array<Byte> =>
            // 会多次回调，性能优化可以考虑减少File打开
            let fileName = tempPath.join(part.fileName)
            try (file = File(fileName, OpenMode.Append)) {
                file.write(data)
            }
          }
        )
        // 解释内容，触发回调Handler
        form.parse()
    }
    ctx.ok()
  }
)
```

- `JoyMultiPartForm`
  - `form.handlePart(name, handler)`: 注册Part的处理类

当用户有注册自定义Handler时，框架会优先调用Handler进行回调，不再做内存或磁盘缓存。同一个HTTP请求存在多个MultiPart时，不同的Part可以采用不同处理策略，如示例中的`id`可以采用内置缓存，`photo`可以注册自定义Handler。

## 参与贡献

欢迎给我们提交 PR，欢迎给我们提交 Issue，欢迎参与任何形式的贡献。

fork时请保留上游仓库地址 [Cangjie-SIG/cjoy](https://gitcode.com/Cangjie-SIG/cjoy) 或 [lanlingx/cjoy](https://gitcode.com/lanlingx/cjoy) 。

本项目的维护者是 [@lanlingx](https://gitcode.com/lanlingx) 。

开发指导请参见 [doc/dev_guide.md](doc/dev_guide.md) 。

## 协议

参考 [LICENSE](LICENSE) 文件。
