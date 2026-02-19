# 校验

---

## 概述

CJoy 内置校验框架，支持通过宏对类、结构、函数参数进行校验。

核心概念：
- **编译时生成代码**：宏在编译时展开，生成校验方法实现
- **自动接口实现**：`@Valid` 宏展开后自动实现 `JoyValidatable` 接口
- **组合使用**：校验宏可以与 `@Json`、`@Bind` 等其他宏一起使用
- **嵌套校验**：通过 `@NestedValid` 支持对容器内元素的嵌套验证
- **自定义错误消息**：每个校验宏都支持自定义错误消息

校验证失败时抛出 `JoyValidationException` 异常。

注意：函数参数校验 (`@Validated`) 目前仅为实验性探索，参见 [Issue说明](https://gitcode.com/Cangjie/UsersForum/issues/1924)。

---

## 一、类与结构体校验

### 1.1 基本用法

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

### 1.2 使用示例

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
@Validated
func createUser(ctx: JoyContext, @NestedValid user: User): Unit {
    // 绑定通过，保存用户
    ctx.json(@ToJson({"message": "用户创建成功"}))
}
```

### 1.3 手动调用校验

```cangjie
// 创建用户对象
let user = User(
    username: "john",
    email: "test@example.com",
    password: "secret",
    age: 25
)

try {
    // 调用 validate 方法进行校验
    user.validate()
} catch(e: JoyValidationException) {
     // 处理校验错误
}
```

---

## 二、校验宏

| 宏 | 说明 |
|------|------|
| `@Valid` | 作用于类或结构体，生成 `JoyValidatable` 接口的实现 |
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
| `@EqualField` | 校验字段值与另一个字段值相等 |
| `@NestedValid` | 表示成员变量需要嵌套校验，验证容器内元素，作用于类或结构体的成员变量 |
| `@Validated` | 作用于函数上，生成代码会修改函数体增加调用参数的 `validate` 方法 |

---

## 三、宏详细说明

### 3.1 @Size

校验 Collection 对象（Array、ArrayList、HashMap 等）的 Size：

```cangjie
@Size[max = 6, msg = "标签最多6个"]
var tags: Array<String> = []
```

**参数**：
- `min`：最小 size（可选）
- `max`：最大 size（可选）
- `msg`：自定义错误消息（可选）
- `when`：条件表达式，满足时才执行校验（可选）

### 3.2 @EqualField

校验字段值与另一个字段值相等：

```cangjie
@Valid
struct User {
    @NotBlank
    var password: String = ""

    @EqualField[field = "password", msg = "密码确认失败"]
    var confirmPassword: String = ""

    @EqualField[field = "password", when = "needChangePassword"]
    var newPassword: String = ""

    var needChangePassword: Bool = false
}
```

**参数**：
- `field`：要比较的字段名（必填）
- `msg`：自定义错误消息（可选）
- `when`：条件表达式，满足时才执行校验（可选）

### 3.3 @Length

校验字符串的长度：

```cangjie
@Length[min = 3, max = 20, msg = "用户名长度应在3-20之间"]
var username: String = ""
```

**参数**：
- `min`：最小长度（可选）
- `max`：最大长度（可选）
- `msg`：自定义错误消息（可选）
- `when`：条件表达式，满足时才执行校验（可选）

### 3.3 @NumberRange

校验数字范围：

```cangjie
@NumberRange[min = 0, max = 123456789, msg = "数量超出范围"]
var amount: UInt64 = 0
```

**参数**：
- `min`：最小值（字符串，支持写表达式）
- `max`：最大值（字符串，支持写表达式）
- `msg`：自定义错误消息（可选）
- `when`：条件表达式，满足时才执行校验（可选）

### 3.4 @NotEmpty 和 @NotBlank

校验字符串非空或非空白：

```cangjie
@NotEmpty[msg = "内容不能为空"]
var content: String = ""

@NotBlank[msg = "名称不能为空白"]
var name: String = ""

// 使用条件校验
@NotEmpty[when = #"status == "active""#]
var activeReason: String = ""
```

**参数**：
- `msg`：自定义错误消息（可选）
- `when`：条件表达式，满足时才执行校验（可选）

### 3.5 @Pattern

使用正则表达式校验字符串或数字：

```cangjie
@Pattern[regex = "^[a{,A}-z{,Z}0-9]+$", msg = "只允许字母和数字"]
var code: String = ""

// 使用预定义的常量
const USERNAME_REGEX = "^[a-z0-9_]{3,16}$"
@Pattern[regex = USERNAME_REGEX, msg = "用户名格式不正确"]
var username: String = ""

// 使用条件校验
@Pattern[regex = "^[0-9]{11}$", when = #"contactMethod == "phone""#]
var contactNumber: String = ""
```

**参数**：
- `regex`：正则表达式模式（必填）
- `msg`：自定义错误消息（可选）
- `when`：条件表达式，满足时才执行校验（可选）

### 3.6 @DateTimeRange

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
- `when`：条件表达式，满足时才执行校验（可选）
- `msg`：自定义错误消息（可选）

### 3.7 @ChMobileNumber

校验字符串为中国手机号码：

```cangjie
@ChMobileNumber[msg = "请输入有效的手机号码"]
var mobile: String = ""

// 使用条件校验
@ChMobileNumber[when = #"contactMethod == "phone""#]
var contactNumber: String = ""
```

格式支持：
- 带 `+` 或 `86` 前缀
- 3 位或 4 位区号
- `s` 号结尾

**参数**：
- `msg`：自定义错误消息（可选）
- `when`：条件表达式，满足时才执行校验（可选）

### 3.8 @Email

校验字符串为 Email 格式：

```cangjie
@Email[msg = "邮箱格式不正确"]
var email: String = ""

// 使用条件校验
@Email[when = #"contactMethod == "email""#]
var contactEmail: String = ""
```

### 3.9 @IPV4

校验字符串为 IP V4 格式：

```cangjie
@IPV4[msg = "请输入有效的IP地址"]
var ipAddress: String = ""

// 使用条件校验
@IPV4[when = "isOnline"]
var serverAddress: String = ""
```

### 3.10 @EnumInt

校验数字是枚举值：

```cangjie
@EnumInt[values = [1, 2, 3], msg = "状态值无效"]
var status: Int32 = 1

// 使用条件校验
@EnumInt[values = [1, 2], when = "isActive"]
var userStatus: Int32 = 1
```

### 3.11 @EnumStr

校验字符串是为枚举值：

```cangjie
@EnumStr[values = ["admin", "user", "guest"], msg = "角色无效"]
var role: String = "user"

// 使用条件校验
@EnumStr[values = ["admin", "superadmin"], when = "isAdmin"]
var accessLevel: String = "user"
```

### 3.12 @NestedValid

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

---

## 四、JoyValidatable 接口

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

---

## 五、JoyValidationException

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

---

## 六、函数参数校验

`@Validated` 宏用于函数参数校验，在函数调用前自动验证参数值。校验失败时抛出 `JoyValidationException`。

**注意**：函数参数校验目前仅为实验性探索。参见 [Issue说明](https://gitcode.com/Cangjie/UsersForum/issues/1924)。

### 6.1 基本用法

在函数定义前添加 `@Validated` 宏，然后在函数参数上使用校验注解：

```cangjie
import cjoy.validation.*

// 校验数组大小
@Validated
func validateArraySize(@Size[max = 6] arr: Array<Int32>): Unit {
    // 校验通过后执行函数体
    println("Array size: ${arr.size}")
}

// 校验字符串长度
@Validated
func validateStringLength(@Length[max = 6] str: String): Unit {
    println("String: ${str}")
}
```

### 6.2 各种参数类型校验

```cangjie
// @NotEmpty - 校验字符串非空
@Validated
func validateNotEmpty(@NotEmpty str: String): Unit {
}

// @NotBlank - 校验字符串非空白（先 trim 再检查）
@Validated
func validateNotBlank(@NotBlank str: String): Unit {
}

// @NumberRange - 校验数字范围
@Validated
func validateNumberRange(@NumberRange[min = 1, max = 100] num: Int): Unit {
}

// @Pattern - 使用正则表达式校验
@Validated
func validatePattern(@Pattern[regex = "^[0-9]+$"] num: String): Unit {
}

// @DateTimeRange - 校验日期时间范围
@Validated
func validateDateTimeRange(
    @DateTimeRange[after = "DateTime.now().addMinutes(-1)", before = "DateTime.now().addDays(1)"]
    dt: DateTime
): Unit {
}

// @ChMobileNumber - 校验中国手机号码
@Validated
func validateMobile(@ChMobileNumber num: String): Unit {
}

// @Email - 校验邮箱格式
@Validated
func validateEmail(@Email email: String): Unit {
}

// @IPV4 - 校验 IP V4 格式
@Validated
func validateIPV4(@IPV4 ip: String): Unit {
}

// @EnumStr - 校验字符串枚举值
@Validated
func validateEnumStr(@EnumStr[values = ["a", "b", "c"]] str: String): Unit {
}

// @EnumInt - 校验数字枚举值
@Validated
func validateEnumInt(@EnumInt[values = [2, 4, 6]] number: Int): Unit {
}
```

### 6.3 嵌套对象校验

校验嵌套的对象结构：

```cangjie
import cjoy.validation.*
import cjoy.json.*

@Valid
@Json
public struct Data {
    @Length[min = 0, max = 10]
    @NotBlank
    @NotEmpty
    var str: String = "str"

    @NumberRange[min = 0, max = 123456789]
    var u32: UInt32 = 12345678

    @Size[max = 6]
    var arr: Array<Int32> = [1, 2, 3, 4]

    @DateTimeRange[before = "DateTime.now().addDays(1)"]
    var data: DateTime = DateTime.now()
}

// 校验嵌套的 @Valid 对象
@Validated
func validateNestedData(@NestedValid data: Data): Unit {
}
```

### 6.4 DateTimeRange 表达式用法

对于复杂的表达式，可以使用闭包形式：

```cangjie
// 简单表达式
@Validated
func simpleDateTime(
    @DateTimeRange[after = "DateTime.now().addMinutes(-1)", before = "DateTime.now().addDays(1)"]
    dt: DateTime
): Unit {
}

// 使用闭包表达式（更灵活）
@Validated
func complexDateTime(
    @DateTimeRange[
        after = "{=>DateTime.now().addMinutes(-1)}()",
        before = "{=>let x=DateTime.now().addDays(1);x}()"
    ]
    dt: DateTime
): Unit {
}
```

### 6.5 异常处理

捕获校验失败的异常：

```cangjie
@Validated
func validateAge(@NumberRange[min = 0, max = 150] age: Int32): Unit {
    println("Age: ${age}")
}

main(): Int64 {
    try {
        validateAge(200)  // 校验失败
    } catch (e: JoyValidationException) {
        println("校验失败: ${e.message}")
        // e.message 可能是: "this constraint of value is NumberRange[0, 150]"
    }
    return 0
}
```

### 6.6 在 Handler 中使用

```cangjie
import cjoy.Joy
import cjoy.validation.*

@Valid
@Json
public struct UserRequest {
    @Length[min = 3, max = 20]
    @NotBlank
    var username: String = ""
}

// 使用 @Validated 自动校验参数
@Post[path = "/users"]
@Validated
func createUser(
    ctx: JoyContext,
    @NestedValid user: UserRequest  // 自动校验 user 对象
): Unit {
    ctx.json(@ToJson({"message": "用户创建成功", "username": user.username}))
}

// 手动校验 + 处理异常
@Post[path = "/users/manual"]
func createUserManual(ctx: JoyContext): Unit {
    if (let Some(req) <- ctx.bindJsonBody<UserRequest>()) {
        try {
            req.validate()  // 手动调用校验
            ctx.json(@ToJson({"message": "用户创建成功"}))
        } catch (e: JoyValidationException) {
            ctx.status(400).json(@ToJson({
                "error": "校验失败",
                "message": e.message
            }))
        }
    } else {
        ctx.status(400).json(@ToJson({"error": "请求数据格式错误"}))
    }
}
```

---

## 七、完整示例

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
            try {
                req.validate()
                @JoyLogInfo("用户登录: ${req.username}")
                ctx.json(@ToJson({"message": "登录成功"}))
            } catch (e: JoyValidationException) {
                ctx.status(400).json(@ToJson({"message": "请求数据格式错误"}))
            }
        } else {
            ctx.status(400).json(@ToJson({"message": "请求数据格式错误"}))
        }
    })

    // 注册接口
    joy.router.post("/api/register", {ctx: JoyContext =>
        if (let Some(req) <- ctx.bindJsonBody<RegisterRequest>()) {
            // 校验通过，处理注册
            try {
                @JoyLogInfo("用户注册: ${req.email}")
                ctx.json(@ToJson({"message": "注册成功"}))
            } catch (e: JoyValidationException) {
                ctx.status(400).json(@ToJson({"message": "请求数据格式错误"}))
            }
        } else {
            ctx.status(400).json(@ToJson({"message": "请求数据格式错误"}))
        }
    })

    joy.run("127.0.0.1", 8080)
    return 0
}
```

---

## 八、注意事项

1. **@Valid 与 @Json**：可以一起使用，同时启用 JSON 序列化和校验

2. **嵌套校验**：使用 `@NestedValid` 标记需要嵌套校验的集合成员

3. **错误消息**：每个宏都支持自定义错误消息，未指定时使用默认消息

4. **函数参数校验**：`@Validated` 宏目前仅为实验性探索，生产环境建议使用手动校验（`req.validate()`）和 try-catch 处理异常的方式

5. **表达式支持**：`@NumberRange` 和 `@DateTimeRange` 的 min/max/before/after 参数支持写表达式

6. **验证顺序**：校验按照字段定义顺序进行，遇到第一个验证失败即抛出异常

7. **手机号格式**：`@ChMobileNumber` 支持多种中国手机号格式，包括带 `+` 或 `86` 前缀、3 位或 4 位区号

8. **DateTime 闭包表达式**：对于复杂的 `DateTimeRange` 表达式，可以使用闭包形式 `{=>表达式}()`

---

<< [返回](../../README.md#使用指导)
