## ADDED Requirements

### Requirement: Conditional Validation

The `when` property MUST be supported by all validation macros. It SHALL allow specifying a boolean expression that determines when the validation should be executed.

#### Scenario: Basic conditional validation
- **Given**: 一个类有一个字段 `status` 和一个字段 `activeReason`
- **When**: `status` 等于 "active"
- **Then**: 验证 `activeReason` 字段是否不为空

## Conditional Validation

### 功能概述

`when` 属性允许为所有验证宏指定条件表达式，只有当表达式满足时才会执行对应的校验。

### 适用范围

所有 CJoy 验证宏都支持 `when` 属性：
- @Size、@Length、@NotEmpty、@NotBlank
- @NumberRange、@Pattern、@DateTimeRange
- @ChMobileNumber、@Email、@IPV4
- @EnumStr、@EnumInt
- @EqualField（新增）

### 属性语法

```cangjie
@<Macro>[..., when = "<表达式>"]
```

### 表达式语法

`when` 属性接受简单的布尔表达式：

#### 支持的语法

1. **字段访问**：直接访问当前类/结构体的其他字段
   ```cangjie
   when = #"status == "active""#
   when = "!name.isEmpty()"
   ```

2. **简单运算符**：
   - 比较运算符：`==`、`!=`、`<`、`>`、`<=`、`>=`
   - 逻辑运算符：`!`（非）
   - 算术运算符：`+`、`-`、`*`、`/`、`%`
   - 字符串拼接：`+`

3. **常量值**：
   - 字符串常量：`"string"`
   - 数值常量：`123`、`3.14`
   - 布尔常量：`true`、`false`
   - 空值：`null`

4. **其它**：
   - 复杂逻辑运算符：`&&`、`||`（暂不支持）
   - 方法调用：除字段的成员方法外（如 `isEmpty()`）  

#### 不支持的语法

- 三元运算符：`condition ? trueValue : falseValue`
- 变量声明：`let x = 1`
- 块语句：`{ ... }`

### 使用示例

#### 1. 基础条件校验

```cangjie
@Valid
struct Product {
    var type: String = ""

    @NumberRange[min=1, max=100, when = #"type == "digital""#]
    var stock: Int64 = 0

    @NumberRange[min=1, max=10, when = #"type == "physical""#]
    var weight: Float64 = 0.0
}
```

#### 2. 组合条件

```cangjie
@Valid
struct Order {
    var status: String = ""
    var paymentMethod: String = ""

    @NotEmpty[when = #"status == "pending" && paymentMethod == "credit""#]
    var creditCardNumber: String = ""
}
```

#### 3. 使用字段方法

```cangjie
@Valid
struct User {
    var roles: Array<String> = []

    @Email[when = #"roles.contains("admin")"#]
    var adminEmail: String = ""
}
```

### 实现原理

`when` 属性的表达式在**编译期解析**，并直接生成到验证代码中。这样可以保持与现有验证框架相同的性能优势。

### 注意事项

1. **性能**：条件表达式在编译期解析，运行时无额外开销
2. **类型安全**：表达式中的字段访问会进行类型检查
3. **错误处理**：如果表达式无效，会在编译期报错
4. **作用域**：表达式只能访问当前类/结构体的字段和常量
5. **调试**：生成的验证代码包含条件判断逻辑，便于调试

### 常见用例

- 状态驱动的验证
- 字段依赖验证
- 条件必填验证
- 权限相关验证

### 未来扩展

未来版本可能支持更复杂的表达式语法，如：
- 三元运算符
- 嵌套字段访问
