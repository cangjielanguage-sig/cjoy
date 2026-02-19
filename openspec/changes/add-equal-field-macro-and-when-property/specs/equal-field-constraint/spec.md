## Equal Field Constraint

### 功能概述

`@EqualField` 宏用于验证两个字段的值是否相等。当验证失败时，会抛出 `JoyValidationException` 异常。

### 适用类型

- 所有支持相等性比较的类型（String、数值类型、布尔类型、DateTime 等）
- 数组和集合类型（比较元素是否相等）
- 自定义类型（需实现相等性比较）

### 宏定义

```cangjie
@EqualField[field = "<字段名>", msg = "<错误信息>"]
```

### 属性说明

| 属性 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| field | String | 是 | 无 | 要比较的目标字段名 |
| msg | String | 否 | "字段值不相等" | 自定义错误信息 |
| when | String | 否 | 无 | 条件表达式，满足时才执行校验 |

### 使用示例

#### 1. 基本使用

```cangjie
@Valid
struct RegisterRequest {
    @NotEmpty
    var username: String = ""

    @NotEmpty
    var password: String = ""

    @EqualField[field = "password", msg = "两次输入的密码不一致"]
    var confirmPassword: String = ""
}
```

#### 2. 带条件校验

```cangjie
@Valid
struct UserProfile {
    var isEmailVerified: Bool = false

    @Email
    @EqualField[field = "primaryEmail", msg = "验证邮箱与主邮箱不一致", when = "isEmailVerified"]
    var verifyEmail: String = ""

    @Email
    var primaryEmail: String = ""
}
```

### 验证逻辑

当调用 `validate()` 方法时，会执行以下逻辑：

1. 获取当前字段的值
2. 获取目标字段的值
3. 比较两个值是否相等
4. 如果不相等，抛出 `JoyValidationException` 异常

### 注意事项

1. 目标字段必须是同一个类/结构体中的字段
2. 两个字段的类型必须兼容（支持相等性比较）
3. 对于复杂类型，需要正确实现相等性比较方法
4. 在函数参数校验场景中，同样支持该宏
