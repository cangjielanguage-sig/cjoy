# 路由宏

## Handler宏

CJoy提供一系列的宏简化Handler的注册与参数展开，业务只需要实现最简洁的函数。

使用示例: [test/macro_test.cj](../../src/test/macro_test.cj) 。

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

## Middleware宏

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

## 注册

所有的 Handler 注册宏生成的类会自动加到JoyHandlers上，Middleware注册宏生成的类会自动加到JoyMiddlewares上，但目前没有自动加到在服务实例Joy上。

```
JoyMiddlewares.registerTo(joy)
JoyHandlers.registerTo(joy)
joy.run("127.0.0.1", 18881)
```

 - 需要在服务实例启动之前，需要显式地调用`JoyMiddlewares.registerTo(joy)`与`JoyHandlers.registerTo(joy)`，把自动生成Handler注册到实例上；
 - Middleware要先于Handler注册，即`JoyMiddlewares.registerTo(joy)` 需要在 `JoyHandlers.registerTo(joy)` 前调用；

----
<< [返回](../../README.md#使用指导)
