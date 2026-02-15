## Context

schedule 模块是 CJoy 框架中用于处理定时任务的核心组件，基于 cron 表达式实现任务调度。该模块包含以下核心类：

- `CronJob`: 表示一个定时任务，负责解析 cron 表达式和执行任务
- `Crontab`: 定时任务调度器，负责管理多个 CronJob 并定时执行
- `CronTick`: 表示一个时间点，用于匹配定时任务的执行时间
- `ScheduleContext`: 任务执行上下文，提供服务获取功能

现有测试情况：
- `cron_job_test.cj`: 包含 CronJob 的解析测试，但覆盖不全面
- `crontab_test.cj`: 包含 Crontab 的简单运行测试
- `cron_tick_test.cj`: 包含 CronTick 的测试

## Goals / Non-Goals

**Goals:**
- 为 schedule 模块添加全面的低级别测试（LLT）用例，覆盖核心功能和边界条件
- 为 schedule 模块添加高级别测试（HLT）用例，验证定时任务的整体运行流程
- 确保所有测试用例能够通过 `cjpm test` 命令执行
- 提高 schedule 模块的测试覆盖率和代码质量

**Non-Goals:**
- 不修改 schedule 模块的现有功能
- 不添加新的功能或特性
- 不重构现有代码结构

## Decisions

### 1. 测试用例组织方式

**决策**: 采用与现有测试一致的组织方式

- 低级别测试（LLT）：在每个模块的 `*_test.cj` 文件中添加
- 高级别测试（HLT）：在 `src/test/` 目录下添加，使用 `@Test` 和 `@TestCase` 注解

**理由**: 保持与项目现有测试结构一致，便于维护和执行

### 2. 测试框架选择

**决策**: 使用 Cangjie 内置的测试框架

- 使用 `@Test` 注解标记测试类
- 使用 `@TestCase` 注解标记测试方法
- 使用 `@Assert` 进行断言
- 使用 `std.sync.SyncCounter` 进行同步操作

**理由**: 项目已经使用内置测试框架，无需引入额外依赖

### 3. 测试覆盖范围

**决策**: 覆盖以下核心功能

**LLT 覆盖范围**:
- CronJob 解析：各种 cron 表达式的解析测试
- CronJob 匹配：任务匹配时间的测试
- CronJob 执行：任务执行的测试
- Crontab 管理：任务添加、删除、查询的测试
- CronTick：时间点匹配的测试
- 边界条件：无效 cron 表达式、任务执行异常等

**HLT 覆盖范围**:
- 定时任务调度：验证任务按预期时间执行
- 并发任务：多个任务同时执行的测试
- 任务依赖：任务之间的依赖关系测试
- 错误处理：任务执行出错的处理测试

### 4. 测试执行策略

**决策**: 使用 `cjpm test` 命令执行所有测试

- 低级别测试：`cjpm test --filter=CronJobTestCaseSuit.*`
- 高级别测试：`cjpm test --filter=ScheduleHLTTestCaseSuit.*`

**理由**: 保持与项目现有测试执行方式一致

## Risks / Trade-offs

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 定时任务测试不确定性 | 定时任务的执行时间依赖于系统时间，可能导致测试不稳定 | 使用超时机制和灵活的时间匹配策略 |
| 并发任务测试复杂度 | 并发任务测试可能导致竞态条件和资源冲突 | 使用同步机制和隔离的测试环境 |
| 测试执行时间过长 | 定时任务测试需要等待实际时间，可能导致测试执行时间过长 | 使用较短的 cron 表达式（如每秒执行）和超时机制 |

## Migration Plan

无

## Open Questions

无
