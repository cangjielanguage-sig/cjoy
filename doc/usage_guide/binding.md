# 参数绑定

CJoy提供宏与API支持对HTTP请求的Query，PostForm，Header多个参数绑定到一个对象上。

示例一：

```cangjie
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

示例二：

```cangjie
import cjoy.bind.*

@Get[path = "/bind"]
func handleBing(ctx: JoyContext, @QueryBindParam params BindParam): Unit {

}
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

宏展开编译之后，此类与结构体：

 - 并自动生成所有成员变量带命名参数的构造方法。因此let成员变量未指定默认值时，会在构造方法采用系统默认值，如Int为`0`， String为`""`。
 - 实现`cjoy.JoyBindable`接口，

字段类型支持：

  - `String`, `?String`
  - `基本类型`, `?基本类型`
  - `Array<String>`, `ArryList<Strng>`
  - `DateTime`, `?DateTime`

JoyContext提供三个方法：

 - `bindQuery`：把Query参数绑定到对象上；
 - `bindPostForm`：把PostForm参数绑定到对象上；
 - `bindHeader`：把Header参数绑定到对象上；

另外提供三个宏，用在方法参数上：

 - `QueryBindParam`：URL Query多个参数绑定到对象
 - `PostFormBindParam`：PostForm多个参数绑定到对象
 - `HeaderBindParam`：Header多个参数绑定到对象。

----
<< [返回](../../README.md#使用指导)