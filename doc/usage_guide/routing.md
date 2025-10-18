# 路由

## 路由规则

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

## 路由优先级

路由查找优先级：static路由 > regex路由 > param路由 > catchAll路由。

可以同时存在`/users/`开头的多个Path，路由匹配优先级与注册的顺序无关。

```cangjie
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

```cangjie
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

## 路由分组

```cangjie
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
  
----
<< [返回](../../README.md#使用指导)