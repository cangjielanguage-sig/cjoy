# Json

CJoy内置支持采用宏对类与结构体标注，简化对HTTP Body的Json序列化与反序列化绑定与映射。

## 基础用法

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
|`@Json`|description:"..",superClass:""|作用于类与结构体上，标注其自动生成Json序列化与反序列化函数，类与结构体需要无参数的构建函数。|
|`@JsonField`|name:xx,omitempty:true,ignore:false,timeformat:"...",description:"..",required:false:schema={...}|作用类与结构体的成员变量上，变量需要采用var声明并要指定类型。|
|`@ToJson`||原生Json DSL，作用于满足JSON格式的一串符号上，把它转成JsonSerializable对象，可以调用JsonTool.toJson方法序列化为json字符串。|

以上宏的属性参数说明，属性可以采用`=`与`:`赋值，如`@JsonField[name=xx]`与`@JsonField[name:xx]`等价：

|宏属性参数|默认值|是否可选|说明|
|---|---|---|---|
|`name`||是|指定Json的字段名称，不指定为成员变量名|
|`omitempty`|false|是|值true/false，指定生成Json字符串时是否忽略空字符串或Option的None值|
|`ignore`|false|是|值true/false，指定是否忽略此字段|
|`timeformat`|DateTime.toString/parse方法默认格式|是|指定DateTime字段序列化的格式|
|`raw`|false|是|当类型为Any，不反序列化此字段赋值原始字符串字节Array<Byte>|
|`description`|false|是|用于构建字段的Json Schema中description|
|`required`|true|是|用于构建字段的Json Schema中required，当类型为Option时默认为false|
|`schema`|true|是|描述字段的完整Json Schema|

宏展开编译之后，此类或结构体:

- 并自动生成所有成员变量带命名参数的构造方法。成员变量未指定默认值时，会在构造方法采用系统默认值，如Int为`0`， String为`""`。
- 实现stdx.encoding.json.stream包下JsonSerializable与JsonDeserializable接口。

JoyContext提供两个函数支持对HTTP Body的绑定与映射：

 - `readJson` 或者 `bindJsonBody`：对Body内容反序列化为类与结构体
 - `json`: 序列化类与结构体对象序列化并设置Body内容

使用示例：[examples/rest](../../src/examples/rest/main.cj) 。

## 高级用法

更多的使用方式请参考 [test/json_test](../../src/test/json_test.cj) 。

### 多态

@`Json`默认情况下只会对自身的成员变量进行序列化和反序列化，并不包含其父类里的成员变量，提供一些属性支持序列化和反序列化时多态。

```
@Json[subTypeField = "mimeType", subTypes = {"text": "TextResourceContents", "blob": "BlobResourceContents"}]
public open class ResourceContents {
    public var mimeType: String = ""
}

@Json[superClass = ResourceContents]
public class TextResourceContents <: ResourceContents {
    public var text: String = ""
}

@Json[superClass = ResourceContents]
public class BlobResourceContents <: ResourceContents {
    public var blob: String = ""
}

@Json
public class ReadResourceResult {
    // 类型为基类，实际根据mimeType的值反序列化为TextResourceContents或BlobResourceContents
    public var contents: ArrayList<ResourceContents> = ArrayList()
}
```

下面属性用于帮助子类识别父类
- 属性`superClass=父类类型名`来指定父类类型
- 当序列化或反序列化为`TextResourceContents`时，可以同时对父类的成员变量进行序列化和反序列化

下面属性用于帮助父类识别与子类之间的关系
- 属性`subTypeField=字段名`来指定子类的区分字段
- 属性`subTypes={"字段值1":"子类类型名"}`来指定区分字段不同值时的子类类型
- 属性`subTypeField`与`subTypes`同时存在
- 当反序列化`ResourceContents`时，如果json字符串中存在mimeType=text时，即反序化为TextResourceContents对象；存在mimeType=blob时，即反序化为BlobResourceContents对象

**注：**继承是支持class类型，不支持struct类型

### Any类型绑定

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

### 获取原始Json内容

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

### DSL

宏`@ToJson`用于构建原生Json对象，如下所示：

```
let x = "xyz"
let d = @ToJson(
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

`@ToJson`支持：

 - Json字段值中变量替换，如上述的`x`变量
 - Json字段值中字符串插值，如@Jsonable(["${x}", "abc"])

搭配在请求处理Handler中使用示例：

```
@Get[path = "/json"]
func pathGet(): JsonSerializable {
  let x = "xyz"
  @ToJson({
      "a": x, 
      "b": "123"
  })
}
```

### Schema

宏`@Json`展开生成代码会实现`Jsonable`接口，调用`toJsonSchema`方法获取此类型的JSON Schema。

两种方式指定：

 - 通过`description`与`required`指定
 - 通过`schema` 指定完整的Json Schema，当schema属性存在时，忽略指定的`description`与`required`

```
@Json[description: "user info"]
class UserInfo {
    @JsonField[description: "the user name"]
    var name: String = ""
    @JsonField[description: "the address of user", required: false]
    var address: String = ""
    @JsonField[description: "the user gender"]
    var gender: Int = 0

    @JsonField[schema: {
      "type": "object",
      "description": "the user addon info",
      "properties": {
        "info1": {
           "type": "string",
           "description": "xxxx",
        }
      },
      "required": [info1]
    }]
    var addOnInfo: HashMap<String, String> = HashMap()
}
```

----
<< [返回](../../README.md#使用指导)