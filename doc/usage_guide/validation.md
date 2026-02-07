# 校验

CJoy 内置校验框架，支持通过宏对类、结构、函数参数进行校验。

## 概述

校验框架通过编译时宏生成校验代码，在运行时对成员变量或函数参数进行验证。验证失败时抛出 `JoyValidationException` 异常。

- 宏展开后，会自动实现 `JoyValidatable` 接口，可以调用其 `validate` 方法对成员属性进行校验
- 宏可以与 `@Json`、`@Bind` 一起使用
- 函数参数校验仅为实验性探索，参见 [Issue说明](https://gitcode.com/Cangjie/UsersForum/issues/1924)

## 类与结构体校验

### 基本用法

```cangjie
import cjoy.validation.*
import cjoy.json.*

@Valid
@Json
public struct User {
    @Length[min = 3, max = 20, msg = "用户名长度应在3-20之间"]
    @NotBlank
    var username: String = ""

    @Email[msg = "邮箱格式不正确"]
    var email: String = ""

    @Size[max = 6, msg = "密码不能超过6个字符"]
    var password: String = ""

    @NestedValid
    var address: Address = Address()
}
```

### 使用示例

```cangjie
import cjoy.Joy
import cjoy.validation.*
import cjoy.json.*

// 定义嵌套数据结构
@Valid
@Json
public struct Address {
    @NotBlank
    var province: String = ""

    @NotBlank
    var city: String = ""

    @Pattern[regex = "^[0-9]{6}$", msg = "邮编必须为6位数字"]
    var zipCode: String = ""
}

// 定义用户数据结构
@Valid
@Json
public struct User {
    @Length[min = 2, max = 20, msg = "用户名长度应在2-20之间"]
    @NotBlank
    var username: String = ""

    @Email[msg = "邮箱格式不正确"]
    var email: String = ""

    @Size[max = 6, msg = "密码不能超过6个字符"]
    var password: String = ""

    @NumberRange[min = 0, max = 150, msg = "年龄必须在0-150之间"]
    var age: Int32 = 0

    @Size[max = 3, msg = "标签最多3个"]
    var tags: Array<String> = []

    @NestedValid
    var address: Address = Address()

    @DateTimeRange[before = "DateTime.now().addYears(-120)", msg = "出生日期不能为120年前"]
    var birthDate: DateTime = DateTime.now()
}

// Handler 中使用校验
@Post[path = "/users", produce = "json"]
func createUser(ctx: JoyContext): Unit {
    // 尝试绑定并验证 JSON Body
    if (let Some(user) <- ctx.bindJsonBody<User>()) {
        // 绑定通过，保存用户
        ctx.json(@ToJson({"message": "用户创建成功"}))
    } else {
        ctx.status(400).json(@ToJson({"message": "用户数据校验失败"}))
    }
}
```

### 手动调用校验

```cangjie
// 创建用户对象
let user = User(
    username: "john",
    email: "test@example.com",
    password: "secret",
    age: 25
)

// 调用 validate 方法进行校验
user.validate("", false)

// 调用 getViolations 获取校验错误
if (!user.getViolations().isEmpty()) {
    // 校验通过
} else {
    // 处理校验错误
}
```

## 校验宏

| 宏 | 说明 |
|------|------|
| `@Valid` | 作用于类或结构体，生成 `JoyValidatable` 接口的实现 |
| `@NestedValid` | 表示成员变量需要嵌套校验，验证容器内元素 |
| `@Size` | 校验 Collection 对象的 Size |
| `@Length` | 校验字符串长度 |
| `@NotEmpty` | 校验字符串非空 |
| `@NotBlank` | 校验字符串非空白，先 trim 再检查 |
| `@NumberRange` | 校验数字范围 |
| `@Pattern` | 校验字符串或数字正则检查 |
| `@DateTimeRange` | 对 DateTime 范围进行校验，before 和 after 支持写表达式 |
| `@ChMobileNumber` | 校验字符串为中国手机号码 |
| `@Email` | 校验字符串为 Email 格式 |
| `@IPV4` | 校验字符串为 IP V4 格式 |
| `@EnumInt` | 校验数字是枚举值 |
| `@EnumStr` | 校验字符串是为枚举值 |
| `@NestedValid` | 作用于类或结构体的成员变量，表示对此成员类与结构嵌套校验 |
| `@Validated` | 作用于函数上，生成代码会修改函数体增加调用参数的 `validate` 方法 |

## 宏详细说明

### @Size

校验 Collection 对象（Array、ArrayList、HashMap 等）的 Size：

```cangjie
@Size[max = 6, msg = "标签最多6个"]
var tags: Array<String> = []
```

**参数**：
- `min`：最小 size（可选）
- `max`：最大 size（可选）
- `msg`：自定义错误消息（可选）

### @Length

校验字符串的长度：

```cangjie
@Length[min = 3, max = 20, msg = "用户名长度应在3-20之间"]
var username: String = ""
```

**参数**：
- `min`：最小长度（可选）
- `max`：最大长度（可选）
- `msg`：自定义错误消息（可选）

### @NumberRange

校验数字范围：

```cangjie
@NumberRange[min = 0, max = 123456789, msg = "数量超出范围"]
var amount: UInt64 = 0
```

**参数**：
- `min`：最小值（字符串，支持写表达式）
- `max`：最大值（字符串，支持写表达式）
- `msg`：自定义错误消息（可选）

### @NotEmpty 和 @NotBlank

校验字符串非空或非空白：

```cangjie
@NotEmpty[msg = "内容不能为空"]
var content: String = ""

@NotBlank[msg = "名称不能为空白"]
var name: String = ""
```

### @Pattern

使用正则表达式校验字符串或数字：

```cangjie
@Pattern[regex = "^[a-zA-Z0-9]+$", msg = "只允许字母和数字"]
var code: String = ""

// 使用预定义的常量
const USERNAME_REGEX = "^[a-z0-9_]{3,16}$"
@Pattern[regex = USERNAME_REGEX, msg = "用户名格式不正确"]
var username: String = ""
```

### @DateTimeRange

对 DateTime 范围进行校验：

```cangjie
@DateTimeRange[before = "DateTime.now().addDays(-1)", msg = "出生日期不能为未来"]
var birthDate: DateTime = DateTime.now()

@DateTimeRange[after = "DateTime.now()", before = "DateTime.now().addYears(-18)", msg = "入职日期必须在18年内"]
var hireDate: DateTime = DateTime.now()
```

**参数**：
- `before`：边界时间（字符串，支持写表达式，要求值为 DateTime）
- `after`：边界时间（字符串，支持写表达式，要求值为 DateTime）
- `msg`：自定义错误消息（可选）

### @ChMobileNumber

校验字符串为中国手机号码：

```cangjie
@ChMobileNumber[msg = "请输入有效的手机号码"]
var mobile: String = ""
```

格式支持：
- 带 `+` 或 `86` 前缀
- 3 位或 4 位区号
- `s` 号结尾

### @Email

校验字符串为 Email 格式：

```cangjie
@Email[msg = "邮箱格式不正确"]
var email: String = ""
```

### @IPV4

校验字符串为 IP V4 格式：

```cangjie
@IPV4[msg = "请输入有效的IP地址"]
var ipAddress: String = ""
```

### @EnumInt

校验数字是枚举值：

```cangjie
@EnumInt[values = [1, 2, 3], msg = "状态值无效"]
var status: Int32 = 1
```

### @EnumStr

校验字符串是为枚举值：

```cangjie
@EnumStr[values = ["admin", "user", "guest"], msg = "角色无效"]
var role: String = "user"
```

### @NestedValid

表示成员变量需要嵌套校验，验证容器内元素：

```cangjie
@Valid
@Json
public struct Order {
    @NotBlank
    var orderId: String = "ORDER001"

    @NumberRange[min = 1, max = 1000]
    var quantity: Int32 = 1

    @NestedValid
    var items: Array<OrderItem> = []
}
```

对于标记 `@NestedValid` 的成员：
- `Array<T>`：验证每个元素
- `ArrayList<T>`：验证每个元素
- `HashMap<K, V>`：验证每个值
- 元素必须是标记 `@Valid` 的类或结构体

## JoyValidatable 接口

`@Valid` 宏展开后，类或结构体会自动实现 `JoyValidatable` 接口：

```cangjie
public interface JoyValidatable {
    /**
     * 验证对象
     *
     * @param field: 要验证的字段名
     * @param nestedValid: 是否为嵌套验证
     * @param constraints: 校验约束列表
     * @throws JoyValidationException 当校验失败时
     */
    func validate(field: String, nestedValid: Bool, constraints: Array<JoyConstraint>): Unit
}
```

## JoyValidationException

校验失败时抛出的异常：

```cangjie
try {
    user.validate("", false)
} catch (e: JoyValidationException) {
    @JoyLogError("校验失败: ${e.message}")
    ctx.status(400).json(e.toMap())
}
```

异常包含以下信息：
- `field`：校验失败的字段名
- `constraint`：校验失败的约束对象
- `message`：错误消息

## 完整示例

```cangjie
import cjoy.Joy
import cjoy.validation.*
import cjoy.json.*

// 定义数据结构
@Valid
@Json
public struct LoginRequest {
    @Length[min = 3, max = 20, msg = "用户名长度应为3-20"]
    @NotBlank
    var username: String = ""

    @Size[min = 6, max = 20, msg = "密码长度应为6-20"]
    @NotBlank
    var password: String = ""
}

@Valid
@Json
public struct RegisterRequest {
    @Email[msg = "邮箱格式不正确"]
    var email: String = ""

    @Length[min = 8, max = 20, msg = "密码长度应为8-20"]
    var password: String = ""

    @EnumStr[values = ["male", "female"], msg = "性别必须为male或female"]
    var gender: String = "male"

    @NumberRange[min = 0, max = 150, msg = "年龄必须在0-150之间"]
    var age: Int32 = 18
}

@JoyCreateLogger("validation")

main(): Int64 {
    let joy = Joy.default()

    // 登录接口
    joy.router.post("/api/login", {ctx: JoyContext =>
        if (let Some(req) <- ctx.bindJsonBody<LoginRequest>()) {
            // 校验通过，处理登录
            @JoyLogInfo("用户登录: ${req.username}")
            ctx.json(@ToJson({"message": "登录成功"}))
        } else {
            ctx.status(400).json(@ToJson({"message": "请求数据格式错误"}))
        }
    })

    // 注册接口
    joy.router.post("/api/register", {ctx: JoyContext =>
        if (let Some(req) <- ctx.bindJsonBody<RegisterRequest>()) {
            // 校验通过，处理注册
            @JoyLogInfo("用户注册: ${req.email}")
            ctx.json(@ToJson({"message": "注册成功"}))
        } else {
            ctx.status(400).json(@ToJson({"message": "请求数据格式错误"}))
        }
    })

    joy.run("("127.0.0.1", 8080)
    return 0
}
```

## 注意事项

1. **@Valid 与 @Json**：可以一起使用，同时启用 JSON 序列化和校验
2. **嵌套校验**：使用 `@NestedValid` 标记需要嵌套校验的集合成员
3. **错误消息**：每个宏都支持自定义错误消息，未指定时使用默认消息
4. **函数参数校验**：`@Validated` 宏目前仅为实验性探索，生产环境不建议使用
5. **表达式支持**：`@NumberRange` 和 `@DateTimeRange` 的 min/max/before/after 参数支持写表达式

----
<< [返回](../../README.md#使用指导)
