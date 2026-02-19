## 1. 新增 @EqualField 宏

- [x] 1.1 在 `src/validation/macros/macros.cj` 中声明 `@EqualField` 宏
- [x] 1.2 在 `src/validation/constraint.cj` 中实现 `EqualFieldConstraint` 类
- [x] 1.3 在 `src/validation/validation.cj` 中添加 `EqualFieldConstraint` 的验证逻辑
- [x] 1.4 在 `src/validation/macros/constraint.cj` 中实现 `EqualFieldConstraintGenerator` 类
- [x] 1.5 编写 `@EqualField` 宏的单元测试

## 2. 为所有验证宏添加 when 属性

- [x] 2.1 修改 `src/validation/macros/macros.cj` 中所有宏的声明，添加 when 属性
- [x] 2.2 修改 `src/validation/macros/constraint.cj` 中的基类 `ConstraintGenerator`，添加对 when 属性的支持
- [x] 2.3 修改所有具体约束生成器类（如 SizeConstraintGenerator、LengthConstraintGenerator 等），添加 when 属性解析逻辑
- [x] 2.4 修改验证代码生成逻辑，在生成的代码中包裹条件判断
- [x] 2.5 为包含 when 属性的验证场景编写单元测试

## 3. 更新 validation.md 文档

- [x] 3.1 在 validation.md 文档中添加 `@EqualField` 宏的使用介绍和示例
- [x] 3.2 添加关于 when 属性的详细说明和使用示例
- [x] 3.3 更新所有验证宏的属性列表，添加 when 属性说明
- [x] 3.4 检查并完善文档的格式和结构

## 4. 集成测试和验证

- [x] 4.1 运行所有验证相关的单元测试
- [x] 4.2 创建集成测试，验证 `@EqualField` 宏的功能
- [x] 4.3 创建集成测试，验证 when 属性的条件校验功能
- [x] 4.4 检查是否有任何现有测试失败

## 5. 代码审查和优化

- [x] 5.1 审查新增代码的质量和一致性
- [x] 5.2 优化代码结构，确保与现有架构保持一致
- [x] 5.3 检查潜在的性能问题和边界情况
- [x] 5.4 修复发现的任何问题

## 验收标准

1. 所有任务完成后，项目能正常构建
2. 所有测试用例通过
3. `@EqualField` 宏能够正确验证两个字段的值是否相等
4. 所有验证宏的 when 属性能够正确工作
5. validation.md 文档更新完整
6. 代码质量符合项目标准
