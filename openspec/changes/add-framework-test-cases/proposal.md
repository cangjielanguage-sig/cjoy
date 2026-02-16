## Why

CJoy 框架的 src/framework 目录包含了核心组件（引擎、路由、上下文、中间件等），这些组件是整个框架的基础。虽然已有一些测试用例，但测试覆盖率仍有提升空间，需要补充更多的 HLT（高层测试）和 LLT（低层测试）用例，以确保框架的稳定性和可靠性。

## What Changes

- 为 src/framework 目录下的核心组件补充全面的 LLT（低层测试）用例，覆盖边界条件、异常场景和核心功能
- 为框架的主要功能（路由匹配、中间件处理、请求响应、WebSocket 等）添加 HLT（高层测试）用例
- 优化现有测试用例的结构和覆盖范围
- 确保所有测试用例能够通过 cjpm test 命令成功执行

## Capabilities

### New Capabilities
- `framework-test-cases`: 为 src/framework 代码补充 HLT 与 LLT 用例，覆盖引擎、路由、上下文、中间件、WebSocket 等核心组件的测试

### Modified Capabilities
<!-- 无现有功能的需求变更 -->

## Impact

- 受影响的代码：src/framework 目录下的所有文件
- 测试文件：src/test/ 目录下的 HLT 测试文件，以及各组件对应的 *_test.cj 文件
- 依赖：Cangjie SDK 的测试框架
- 构建：使用 cjpm test 命令执行测试

## 回滚计划

如果补充的测试用例引入了问题，可以通过以下步骤回滚：
1. 删除新增的测试文件
2. 恢复被修改的现有测试文件
3. 重新运行测试以确保框架功能正常
