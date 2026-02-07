# JSON

CJoy 基于编译宏提供完整的JSON序列化与反序列化支持，实现零反射、高性能的JSON数据处理。

## 概述

CJoy JSON系统基于以下核心概念设计：

- **零反射设计**：基于编译宏生成序列化代码，运行时零性能损耗
- **类型安全**：编译时类型检查，避免运行时类型错误
- **编译宏驱动**：通过`@Json`、`@JsonField`、`@ToJson`宏简化配置
- **多态支持**：完整的继承体系序列化与反序列化
- **灵活配置**：支持字段映射、条件忽略、自定义格式等
- **Schema生成**：自动生成JSON Schema用于API文档
- **Any类型**：支持动态JSON数据的处理和转换

### 核心接口定义
- `JsonSerializable`：序列化接口，参见 [stdx.encoding.json.stream](../../src)
- `JsonDeserializable`：反序列化接口，参见 [stdx.encoding.json.stream](../../src)
- `JsonTool`：JSON工具类，参见 [json_tool.cj](../../src/json/json_tool.cj)
- `ToJson`：DSL宏，参见 [tojson.cj](../../src/json/macros/tojson.cj)

### 宏生成特性

| 特性 | 支持状态 | 说明 |
|------|----------|------|
| 自动构造函数生成 | ✅ | 基于字段生成带参构造函数 |
| 字段映射 | ✅ | 支持JSON字段名与类字段名不同 |
| 条件序列化 | ✅ | 支持空值和None值的条件忽略 |
| 类型转换 | ✅ | 自动处理基础类型和Option类型 |
| 继承支持 | ✅ | 支持类继承体系的序列化 |
| Schema生成 | ✅ | 自动生成JSON Schema文档 |

---

## 一、基础序列化与反序列化

### 1.1 @Json 宏使用

```cangjie
import cjoy.json.*

@Json[description = "用户信息模型"]
class UserInfo {
    var name: String = ""
    
    @JsonField[omitempty = true, description = "用户地址"]
    var address: String = ""
    
    @JsonField[name = "userGender", description = "用户性别"]
    var gender: Int = 0
    
    @JsonField[timeformat = "yyyy-MM-dd", description = "注册时间"]
    var registerDate: DateTime = DateTime.now()
}
```

### 1.2 HTTP请求处理

```cangjie
@Post[path = "/users", produce = "json"]
func createUser(ctx: JoyContext): Unit {
    // 反序列化请求体
    let user = ctx.bindJsonBody<UserInfo>()
    
    // 验证用户数据
    if (user.name.isEmpty) {
        ctx.status(400).string("用户名不能为空")
        return
    }
    
    // 业务逻辑处理
    println("创建用户: ${user.name}")
    
    // 序列化响应体
    ctx.status(201).json(user)
}

@Get[path = "/users/{id}", produce = "json"]
func getUser(ctx: JoyContext, @PathParam id: String): Unit {
    let user = findUserById(id)
    match (user) {
        case Some(u) => ctx.json(u)
        case _ => ctx.status(404).string("用户不存在")
    }
}
```

### 1.3 宏属性配置

| 属性 | 默认值 | 说明 | 示例 |
|------|--------|------|------|
| `name` | 变量名 | JSON字段名映射 | `@JsonField[name = "userId"]` |
| `omitempty` | `false` | 空值是否忽略 | `@JsonField[omitempty = true]` |
| `ignore` | `false` | 是否忽略字段 | `@JsonField[ignore = true]` |
| `timeformat` | DateTime默认格式 | DateTime格式化 | `@JsonField[timeformat = "yyyy-MM-dd"]` |
| `raw` | `false` | 原始字节处理 | `@JsonField[raw = true]` |
| `description` | - | 字段描述 | `@JsonField[description = "用户ID"]` |
| `required` | Option时为false | Schema必填字段 | `@JsonField[required = true]` |
| `schema` | - | 完整Schema定义 | `@JsonField[schema = {...}]` |

### 1.4 支持的数据类型

| 类型 | 序列化结果 | 反序列化支持 |
|------|------------|-------------|
| 基础类型 | 对应JSON值 | 自动转换 |
| `String` | JSON字符串 | ✅ |
| `Int64/Int32/Int16/Int8` | JSON数字 | ✅ |
| `Float64/Float32` | JSON数字 | ✅ |
| `Bool` | JSON布尔值 | ✅ |
| `Array<T>` | JSON数组 | ✅ |
| `HashMap<String, T>` | JSON对象 | ✅ |
| `Option<T>` | 可选JSON值 | ✅ |
| `DateTime` | 格式化字符串 | ✅ (需指定格式) |
| 实现JsonSerializable的类型 | 自定义序列化 | ✅ |

### 1.5 错误处理

```cangjie
@Post[path = "/data"]
func processData(ctx: JoyContext): Unit {
    try {
        let data = ctx.bindJsonBody<RequestData>()
        // 处理数据
        ctx.json(ResponseData(success: true, data: processData(data)))
    } catch (e: JsonException) {
        ctx.status(400).json(ErrorResponse(
            success: false, 
            message: "JSON解析错误: ${e.message}"
        ))
    }
}
```

## 二、高级功能

### 2.1 多态序列化与反序列化

CJoy支持完整的继承体系JSON处理，通过类型识别字段自动选择正确的子类。

#### 按字段值确定子类类型

```cangjie
@Json[subTypeField = "mimeType", subTypes = {
    "text": "TextResourceContents", 
    "blob": "BlobResourceContents",
    "json": "JsonResourceContents"
}]
public open class ResourceContents {
    public var id: String = ""
    public var mimeType: String = ""
}

@Json[superClass = ResourceContents]
public class TextResourceContents <: ResourceContents {
    public var text: String = ""
    public var encoding: String = "utf-8"
}

@Json[superClass = ResourceContents]
public class BlobResourceContents <: ResourceContents {
    public var blob: String = ""
    public var size: Int64 = 0
}

@Json[superClass = ResourceContents]
public class JsonResourceContents <: ResourceContents {
    public var data: HashMap<String, String> = HashMap()
}

@Json
public class ReadResourceResult {
    public var contents: ResourceContents = ResourceContents() // 基类引用
    public var metadata: HashMap<String, String> = HashMap()
}
```

#### 按字段存在性确定子类类型

```cangjie
@Json[subTypeAs = true, subTypes = {
    "hasText": "TextResourceContents", 
    "hasBlob": "BlobResourceContents"
}]
public open class ResourceContents {
    public var id: String = ""
}

@Json[superClass = ResourceContents]
public class TextResourceContents <: ResourceContents {
    public var text: String = ""
}

@Json[superClass = ResourceContents]
public class BlobResourceContents <: ResourceContents {
    public var blob: String = ""
}
```

### 2.2 Any类型动态处理

支持动态JSON数据的灵活处理：

```cangjie
@Json
public class DynamicData {
    public var stringValue: String = ""
    public var numberValue: Any = 0
    public var boolValue: Any = false
    public var objectValue: Any = HashMap<String, String>()
    public var arrayValue: Any = ArrayList<String>()
    public var optionalValue: Any = Option<String>.None
    @JsonField[raw = true]
    public var rawBytes: Any = Option<Array<Byte>>.None
}
```

#### Any类型转换规则

| JSON类型 | 仓颉类型 | 转换方式 |
|-----------|-----------|----------|
| JsonObject | `HashMap<String, JsonSerializable>` | 直接转换 |
| JsonArray | `ArrayList<JsonSerializable>` | 直接转换 |
| JsonBool | `Bool` | 直接转换 |
| JsonNumber | `Int64` 或 `Float64` | 自动判断 |
| JsonString | `String` | 直接转换 |
| JsonNull | `Option<T>.None` | 转换为None |

### 2.3 原始数据获取

对于需要保持原始JSON内容的场景：

```cangjie
@Json
public class RawDataContainer {
    public var processedData: String = ""
    
    @JsonField[raw = true, description = "原始JSON字节"]
    public var rawJson: Any = Option<Array<Byte>>.None
    
    @JsonField[raw = true, description = "原始文本内容"]
    public var rawText: Any = Option<Array<Byte>>.None
}
```

### 2.4 @ToJson DSL构建

原生JSON对象构建DSL，支持变量替换和字符串插值：

```cangjie
@Get[path = "/dynamic"]
func createDynamicJson(ctx: JoyContext): Unit {
    let userId = ctx.getParam("userId") ?? "anonymous"
    let timestamp = DateTime.now().toUnixTimeStamp().toSeconds()
    
    // 构建动态JSON对象
    let response = @ToJson({
        "user": {
            "id": userId,
            "timestamp": timestamp,
            "profile": {
                "name": "User ${userId}",
                "level": if (userId == "anonymous") { "guest" } else { "member" }
            }
        },
        "data": ["item1", "item2", "item3"],
        "metadata": {
            "version": "1.0.0",
            "generated": "${DateTime.now()}"
        }
    })
    
    ctx.json(response)
}

// 支持数组和对象混合
@Get[path = "/complex"]
func complexJson(ctx: JoyContext): Unit {
    let items = ["product1", "product2", "product3"]
    
    let complex = @ToJson([
        {
            "id": 1,
            "name": items[0],
            "available": true
        },
        {
            "id": 2, 
            "name": items[1],
            "available": false
        }
    ])
    
    ctx.json(complex)
}
```

### 2.5 时间格式处理

```cangjie
@Json
public class TimeSensitiveData {
    @JsonField[timeformat = "yyyy-MM-dd HH:mm:ss"]
    public var createTime: DateTime = DateTime.now()
    
    @JsonField[timeformat = "ISO8601"]
    public var updateTime: DateTime = DateTime.now()
    
    @JsonField[timeformat = "yyyy/MM/dd"]
    public var displayDate: DateTime = DateTime.now()
    
    @JsonField[description = "创建时间戳"]
    public var timestamp: Int64 = DateTime.now().toUnixTimeStamp().toSeconds()
}

// 使用示例
@Get[path = "/time-data"]
func getTimeData(ctx: JoyContext): Unit {
    let data = TimeSensitiveData()
    ctx.json(data)
    // 输出：
    // {
    //   "createTime": "2025-01-15 14:30:25",
    //   "updateTime": "2025-01-15T14:30:25Z",
    //   "displayDate": "2025/01/15", 
    //   "timestamp": 1705313425
    // }
}
```

用于帮助父类识别与子类之间的关系：
 - 属性`subTypeField=字段名`来指定子类的区分字段
 - 属性`subTypes={"字段值1":"子类类型名"}`来指定区分字段不同值时的子类类型
 - 属性`subTypeField`与`subTypes`同时存在
 - 当反序列化`ResourceContents`时，如果json字符串中存在mimeType="text"时，即反序列化为TextResourceContents对象；存在mimeType="blob"时，即反序列化为BlobResourceContents对象

#### 按是否存在字段来确定子类

```cangjie
@Json[subTypeAs = true, subTypes = {"text": "TextResourceContents", "blob": "BlobResourceContents"}]
public open class ResourceContents {
   
}

@Json[superClass = ResourceContents]
public class TextResourceContents <: ResourceContents {
    public var text: String = ""
}

@Json[superClass = ResourceContents]
public class BlobResourceContents <: ResourceContents {
    public var blob: String = ""
}
```

用于帮助父类识别与子类之间的关系：
 - 属性`subTypeAs=true`来指定子类
 - 属性`subTypes={"字段名1":"子类类型名"}`来指定区分字段时的子类类型
 - 属性`subTypeAs`与`subTypes`同时存在
 - 当反序列化`ResourceContents`时，如果json字符串中存在text字段时，即反序列化为TextResourceContents对象；存在blob字段时，即反序列化为BlobResourceContents对象

**注：** 继承只支持class类型，不支持struct类型

### Any类型绑定

一些反序列化场景，可以通过定义Any类型泛化接收不同Json类型，如下所示。

假设字符串为：

```cangjie
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

```cangjie
@Json
public class DataAny {
    var a: Any = 1 // 实际反序列化之后类型为Int64
    var b: Any = 2 // 实际反序列化之后类型为Float64
    var c: Any = Option<Any>.None // 实际反序列化之后类型为HashMap<String, JsonSerializable>
    var d: Any = Option<Any>.None // 实际反序列化之后类型为ArrayList<HashMap<String, JsonSerializable>>
}
```

反序列化映射关系如下，可以把Any向下转型为对应的仓颉数据类型。

|Json类型|仓颉类型|
|---|---|
|JsonObject|`HashMap<String, JsonSerializable>`|
|JsonArray|`ArrayList<JsonSerializable>`|
|JsonBool|Bool|
|JsonNumber|Int64或Float64|
|JsonString|String|
|JsonNull|`Option<String>.None`|

### 获取原始Json内容

当一个字段反序列化时，不展开解释只获取原始字节，可以指定`@JsonField[raw=true]`：

```cangjie
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

```cangjie
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

宏`@ToJson`用于快速原生Json格式风格的对象，如下所示：

```cangjie
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

上述变量`d`实际类型为`HashMap<String, JsonSerializable>`或`ArrayList<JsonSerializable>`，调用`JsonTool.toJson(d)`转成Json字符串。

`@ToJson`支持：

 - Json字段值中变量替换，如上述的`x`变量
 - Json字段值中字符串插值，如@ToJson(["${x}", "abc"])

搭配在请求处理Handler中使用示例：

```cangjie
@Get[path = "/json"]
func pathGet(): JsonSerializable {
  let x = "xyz"
  @ToJson({
      "a": x, 
      "b": "123"
  })
}
```

## 三、JSON Schema生成

### 3.1 Schema概述

CJoy自动为`@Json`标注的类生成JSON Schema，支持API文档生成和数据验证。

### 3.2 Schema配置方式

#### 方式一：字段级描述

```cangjie
@Json[description = "用户信息模型"]
class UserInfo {
    @JsonField[description = "用户唯一标识", required = true]
    var id: String = ""
    
    @JsonField[description = "用户姓名", required = true]
    var name: String = ""
    
    @JsonField[description = "用户邮箱", required = false]
    var email: String = ""
    
    @JsonField[description = "用户年龄"]
    var age: Int = 0
    
    @JsonField[description = "用户地址，可选字段"]
    var address: ?String = None
}
```

#### 方式二：完整Schema定义

```cangjie
@Json[description = "复杂用户配置"]
class UserConfig {
    @JsonField[schema = {
        "type": "object",
        "description": "用户偏好设置",
        "properties": {
            "theme": {
                "type": "string",
                "enum": ["light", "dark", "auto"],
                "description": "界面主题",
                "default": "auto"
            },
            "language": {
                "type": "string",
                "pattern": "^[a-z]{2}(-[A-Z]{2})?$",
                "description": "语言代码"
            }
        },
        "required": ["theme"]
    }]
    var preferences: HashMap<String, String> = HashMap()
    
    @JsonField[schema = {
        "type": "array",
        "items": {
            "type": "string",
            "format": "email"
        },
        "description": "备用邮箱列表"
    }]
    var backupEmails: Array<String> = []
}
```

### 3.3 Schema获取与使用

```cangjie
@Get[path = "/schema/{type}"]
func getSchema(ctx: JoyContext, @PathParam type: String): Unit {
    match (type) {
        case "user" => {
            let schema = UserInfo().toJsonSchema()
            ctx.header("Content-Type", "application/schema+json")
            ctx.json(schema)
        }
        case "config" => {
            let schema = UserConfig().toJsonSchema()
            ctx.json(schema)
        }
        case _ => ctx.status(404).string("未找到指定类型的Schema")
    }
}
```

### 3.4 生成的Schema示例

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "description": "用户信息模型",
  "properties": {
    "id": {
      "type": "string",
      "description": "用户唯一标识"
    },
    "name": {
      "type": "string", 
      "description": "用户姓名"
    },
    "email": {
      "type": "string",
      "description": "用户邮箱"
    },
    "age": {
      "type": "integer",
      "description": "用户年龄"
    },
    "address": {
      "type": ["string", "null"],
      "description": "用户地址，可选字段"
    }
  },
  "required": ["id", "name", "age"]
}
```

## 四、性能优化与注意事项

### 4.1 性能优化建议

#### 零拷贝优化
```cangjie
// ✅ 推荐：使用原生类型
@Json
class OptimizedUser {
    var id: String = ""
    var name: String = ""
    var scores: Array<Int> = []
}

// ⚠️ 避免：过度嵌套
@Json
class NestedUser {
    var profile: UserProfile = UserProfile() // 额外对象层
    var settings: UserSettings = UserSettings() // 额外对象层
}
```

#### 内存使用优化
```cangjie
@Json
class MemoryEfficientData {
    // 使用Option避免空值占用内存
    var optionalField: ?String = None
    
    // 合理设置默认值
    @JsonField[omitempty = true]
    var nullableField: String = ""
    
    // 避免深拷贝
    var cacheData: Array<Byte> = Array<Byte>()
}
```

### 4.2 错误处理最佳实践

```cangjie
@Post[path = "/safe-parse"]
func safeJsonParse(ctx: JoyContext): Unit {
    try {
        let request = ctx.bindJsonBody<ApiRequest>()
        
        // 验证必需字段
        if (request.id.isEmpty) {
            ctx.status(400).json(ApiError(
                code: "MISSING_ID",
                message: "请求ID不能为空"
            ))
            return
        }
        
        // 处理业务逻辑
        let result = processRequest(request)
        ctx.status(200).json(ApiResponse(
            success: true,
            data: result
        ))
        
    } catch (e: JsonException) {
        ctx.status(400).json(ApiError(
            code: "JSON_PARSE_ERROR",
            message: "JSON解析失败: ${e.message}"
        ))
    } catch (e: Exception) {
        ctx.status(500).json(ApiError(
            code: "INTERNAL_ERROR", 
            message: "服务器内部错误"
        ))
    }
}
```

### 4.3 注意事项

| 约束 | 说明 | 解决方案 |
|------|------|----------|
| **字段类型** | 每个成员变量需要指定类型与默认值 | 使用明确的类型标注和合理的默认值 |
| **继承支持** | 只支持class类型，不支持struct | 使用class定义继承体系 |
| **循环引用** | 避免对象间的循环引用 | 使用Option打破循环或重新设计数据结构 |
| **大数据处理** | 大JSON对象可能占用大量内存 | 使用流式处理或分批处理 |
| **版本兼容** | Schema变更时考虑向后兼容 | 使用可选字段和版本标记 |

### 4.4 常见问题解决

**Q: 为什么反序列化失败？**
A: 检查JSON格式、字段类型匹配、必需字段是否缺失

**Q: 如何处理动态JSON结构？**
A: 使用Any类型结合模式匹配，或定义灵活的数据结构

**Q: 如何优化JSON性能？**
A: 避免过度嵌套、使用合适的数据类型、考虑流式处理

**Q: Schema生成不准确怎么办？**
A: 检查字段描述、required配置、自定义schema定义

---
 << [返回](../../README.md#使用指导)