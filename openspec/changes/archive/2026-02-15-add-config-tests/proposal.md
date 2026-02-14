## Why

CJoy 框架的 config 模块提供了配置管理的核心功能，包括命令行参数解析、JSON 配置、Properties 配置等。当前 config 模块已有一些测试用例，但覆盖范围不够全面，部分核心功能缺乏单元测试，可能存在潜在的 bug 风险。为了提高代码质量和稳定性，需要补充 config 模块的测试用例。

## What Changes

- 补充 config 模块各子模块的单元测试用例
- 增加边界条件和异常场景的测试
- 提高测试覆盖率
- 优化现有测试用例的结构和可读性

## Capabilities

### New Capabilities
- `config-tests`: 补充 config 模块的测试用例，包括 arg_conf.cj、json_conf.cj、properties_conf.cj、conf_manager.cj 等核心文件的测试

### Modified Capabilities
<!-- 无现有功能的需求变更 -->

## Impact

- 受影响的代码：`src/config/` 目录下的所有文件
- 测试文件：`src/config/*_test.cj`
- 构建工具：cjpm test
