## Why

在 CJoy 框架的 validation 模块中，当前缺少两个重要功能：
1. 字段间值相等性校验的宏
2. 条件校验功能，允许在特定条件满足时才执行校验

这些功能是常见的验证场景需求，例如：
- 确认密码字段必须与密码字段相等
- 某些字段仅在特定条件下需要校验（如状态为"激活"时才校验邮箱格式）

## What Changes

1. **新增 `@EqualField` 宏**：用于判断两个字段的值是否相等，支持自定义错误信息
2. **为所有验证宏添加 `when` 属性**：允许指定表达式，当表达式满足时才对字段进行校验
3. **更新 validation.md 文档**：添加新功能的使用介绍和示例代码

## Capabilities

### New Capabilities
- `equal-field-constraint`: 字段间值相等性校验功能
- `conditional-validation`: 基于条件表达式的校验功能

### Modified Capabilities
- `validation-macros`: 所有现有验证宏（@Size、@Length、@NotEmpty、@NotBlank、@NumberRange、@Pattern、@Email、@IPV4 等）添加 when 属性

## Impact

- **源代码修改**：
  - `src/validation/macros/macros.cj`: 新增 @EqualField 宏声明，为所有宏添加 when 属性支持
  - `src/validation/macros/constraint.cj`: 新增 EqualFieldConstraintGenerator 类，修改所有约束生成器支持条件表达式
  - `src/validation/constraint.cj`: 新增 EqualFieldConstraint 类
  - `src/validation/validation.cj`: 添加 EqualFieldConstraint 的验证逻辑
- **文档修改**：
  - `doc/usage_guide/validation.md`: 新增 @EqualField 宏和 when 属性的使用介绍

## 回滚计划

1. 如果需要回滚，删除新增的 `@EqualField` 宏声明和实现
2. 从所有其他验证宏中移除 when 属性支持
3. 恢复 validation.md 文档到变更前的版本
4. 运行所有验证相关的测试以确保功能正常
