## Context

CJoy 框架的 config 模块提供了配置管理的核心功能，支持多种配置源：
- 命令行参数配置 (`ArgConfigLoader`)
- JSON 文件配置 (`JsonConfigLoader`)
- Properties 文件配置 (`PropertiesConfigLoader`)
- 环境变量配置 (自动加载)

配置管理器 (`ConfigManager`) 负责加载和合并这些配置源，并提供统一的访问接口。当前 config 模块已有一些测试用例，但覆盖范围不够全面，部分核心功能缺乏单元测试。

## Goals / Non-Goals

**Goals:**
- 补充 config 模块各子模块的单元测试用例
- 增加边界条件和异常场景的测试
- 提高测试覆盖率
- 优化现有测试用例的结构和可读性

**Non-Goals:**
- 不修改 config 模块的核心功能实现
- 不添加新的配置源类型
- 不重构现有测试框架

## Decisions

### 测试策略
- 对每个 ConfigLoader 类补充全面的测试用例
- 对 ConfigManager 的核心功能补充测试
- 重点测试边界条件和异常场景
- 保持与现有测试风格一致（使用 `@Test` 和 `@TestCase` 注解）

### 测试内容规划
1. **ArgConfigLoader 补充测试**：
   - 测试值包含等号的情况
   - 测试无效参数格式
   - 测试优先级参数

2. **JsonConfigLoader 补充测试**：
   - 测试文件不存在的情况
   - 测试无效 JSON 文件
   - 测试空文件
   - 测试 JSON 中包含复杂结构
   - 测试优先级参数

3. **PropertiesConfigLoader 补充测试**：
   - 测试文件不存在的情况
   - 测试无效 properties 文件
   - 测试空文件
   - 测试值包含等号的情况
   - 测试注释行处理
   - 测试优先级参数

4. **ConfigManager 补充测试**：
   - 测试环境变量配置
   - 测试配置合并优先级
   - 测试配置未找到的情况
   - 测试 bind 方法的更多类型
   - 测试 resolve 方法的复杂表达式
   - 测试配置链的解析

### 风险 / Trade-offs

| 风险 | 缓解措施 |
|------|----------|
| 测试用例可能与现有测试重复 | 仔细分析现有测试，避免重复 |
| 测试文件路径依赖可能导致测试失败 | 使用项目根目录相对路径，确保测试数据文件存在 |
| 环境变量测试可能受系统环境影响 | 使用可控的环境变量，测试后恢复 |

## Migration Plan

无需迁移，这是纯粹的测试补充任务。

## Open Questions

无
