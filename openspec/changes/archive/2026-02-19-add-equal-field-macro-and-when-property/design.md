## Context

CJoy 框架的 validation 模块使用宏系统实现编译期代码生成的验证功能。当前支持多种约束宏（如 @Size、@Length、@Email 等），但缺少字段间值相等性校验和条件校验功能。

### 当前架构
- 宏定义在 `src/validation/macros/macros.cj`
- 约束解析和代码生成在 `src/validation/macros/constraint.cj`
- 约束类定义在 `src/validation/constraint.cj`
- 验证逻辑在 `src/validation/validation.cj`

## Goals / Non-Goals

**Goals:**
1. 实现 `@EqualField` 宏，支持字段间值相等性校验
2. 为所有验证宏添加 `when` 属性，支持条件校验
3. 更新 validation.md 文档，添加新功能的使用介绍
4. 保持与现有架构的一致性，确保编译期代码生成的性能优势

**Non-Goals:**
1. 不实现运行时动态条件表达式解析（保持编译期解析）
2. 不添加复杂的逻辑运算符支持（仅支持简单的布尔表达式）
3. 不修改验证框架的核心架构

## Decisions

### Decision 1: @EqualField 宏的实现方式

**选择：** 新增 `EqualFieldConstraint` 类和 `EqualFieldConstraintGenerator` 类

**原因：** 遵循现有架构模式，与其他约束的实现方式保持一致

**实现要点：**
- 在 `constraint.cj` 中新增 `EqualFieldConstraint` 类，实现 `JoyConstraint` 接口
- 在 `validation.cj` 中添加该约束的验证逻辑
- 在 `constraint.cj` 中新增 `EqualFieldConstraintGenerator` 类，继承自 `MsgBaseConstraintGenerator`
- 在 `macros.cj` 中声明 `@EqualField` 宏

### Decision 2: when 属性的设计

**选择：** 为所有约束宏添加可选的 `when` 属性，接受字符串表达式

**原因：** 简单且直观的 API 设计，符合用户预期

**实现要点：**
- 修改所有约束生成器类，添加对 `when` 属性的解析
- 在生成验证代码时，包裹条件判断逻辑
- 支持简单的布尔表达式，如 `!abc.isEmpty()`、`status == "active"` 等

### Decision 3: 条件表达式的解析时机

**选择：** 编译期解析和代码生成，不支持运行时解析

**原因：** 保持与现有框架的性能优势，避免运行时反射开销

**实现要点：**
- 在宏解析阶段，将 `when` 属性的值直接嵌入到生成的验证代码中
- 表达式会在运行时被直接执行，无需额外解析开销

### Decision 4: 错误信息处理

**选择：** 为 `@EqualField` 宏添加可选的 `msg` 属性，支持自定义错误信息

**原因：** 遵循现有宏的设计模式

## Risks / Trade-offs

### Risk 1: 条件表达式的复杂性

**风险：** 过于复杂的表达式可能导致代码生成错误或运行时异常

**缓解：**
- 限制表达式的复杂性，仅支持简单的字段访问和基本运算符
- 提供详细的错误提示和文档说明

### Risk 2: 字段名称的解析

**风险：** 在函数参数校验场景中，字段名称的解析可能会有差异

**缓解：**
- 复用现有的 `FieldInfoCache` 机制
- 确保在类/结构体和函数参数校验场景中的一致性

### Risk 3: 与现有功能的兼容性

**风险：** 添加新属性可能影响现有验证宏的功能

**缓解：**
- 确保 `when` 属性是可选的，默认值为 `true`（始终执行校验）
- 保留现有宏的所有功能和属性
- 编写完整的测试用例，覆盖所有场景

## 实现步骤

1. 在 `macros.cj` 中声明 `@EqualField` 宏
2. 在 `constraint.cj` 中新增 `EqualFieldConstraint` 类
3. 在 `constraint.cj` 中新增 `EqualFieldConstraintGenerator` 类
4. 在 `validation.cj` 中实现 `EqualFieldConstraint` 的验证逻辑
5. 修改所有约束生成器类，添加对 `when` 属性的支持
6. 修改验证代码生成逻辑，包裹条件判断
7. 更新 validation.md 文档
8. 编写测试用例，验证新功能
