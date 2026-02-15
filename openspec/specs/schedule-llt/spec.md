# schedule-llt Specification

## Purpose
TBD - created by archiving change add-schedule-test-cases. Update Purpose after archive.
## Requirements
### Requirement: CronJob 解析各种 cron 表达式
CronJob SHALL 能够解析各种格式的 cron 表达式，包括标准的 5 字段和扩展的 6 字段（包含秒）格式。

#### Scenario: 解析标准 5 字段 cron 表达式
- **WHEN** 解析 "* * * * *" 表达式
- **THEN** 任务应在每分钟的第 0 秒执行

#### Scenario: 解析扩展 6 字段 cron 表达式
- **WHEN** 解析 "* * * * * *" 表达式
- **THEN** 任务应在每秒执行

#### Scenario: 解析包含步长的表达式
- **WHEN** 解析 "*/5 * * * *" 表达式
- **THEN** 任务应在每 5 分钟的第 0 秒执行

#### Scenario: 解析包含范围的表达式
- **WHEN** 解析 "0-10 * * * *" 表达式
- **THEN** 任务应在每分钟的第 0 到 10 秒执行

#### Scenario: 解析包含列表的表达式
- **WHEN** 解析 "1,5,10 * * * *" 表达式
- **THEN** 任务应在每分钟的第 1、5 和 10 秒执行

#### Scenario: 解析无效格式的表达式
- **WHEN** 解析无效格式的表达式（如 "* * * *"）
- **THEN** 应抛出 ScheduleException 异常

### Requirement: CronJob 匹配执行时间
CronJob SHALL 能够正确判断当前时间是否匹配定时任务的执行时间。

#### Scenario: 匹配精确时间
- **WHEN** 任务配置为 "30 14 * * *"（每天 14:30:00），且当前时间为 14:30:00
- **THEN** 任务应匹配执行时间

#### Scenario: 不匹配时间
- **WHEN** 任务配置为 "30 14 * * *"，且当前时间为 14:29:00
- **THEN** 任务不应匹配执行时间

#### Scenario: 匹配分钟范围
- **WHEN** 任务配置为 "0 0-5 * * *"（每小时的第 0 到 5 分钟），且当前时间为 0:3:00
- **THEN** 任务应匹配执行时间

### Requirement: Crontab 管理定时任务
Crontab SHALL 能够管理多个定时任务，包括添加、删除、查询和执行。

#### Scenario: 添加任务
- **WHEN** 向 Crontab 添加一个新任务
- **THEN** 任务应成功添加到调度器中

#### Scenario: 添加重复任务
- **WHEN** 向 Crontab 添加一个已存在名称的任务
- **THEN** 应抛出 ScheduleException 异常

#### Scenario: 查询任务存在性
- **WHEN** 查询已添加任务的名称
- **THEN** 应返回 true

#### Scenario: 删除任务
- **WHEN** 从 Crontab 中删除一个任务
- **THEN** 任务应不再存在于调度器中

### Requirement: Crontab 执行定时任务
Crontab SHALL 能够定时执行已添加的任务。

#### Scenario: 执行任务
- **WHEN** 任务配置为每秒执行，且时间经过 1 秒
- **THEN** 任务应被执行一次

#### Scenario: 并发执行多个任务
- **WHEN** 添加多个每秒执行的任务
- **THEN** 所有任务应被并发执行

### Requirement: 任务执行上下文
ScheduleContext SHALL 提供任务执行时的上下文信息，包括服务获取功能。

#### Scenario: 获取服务
- **WHEN** 在任务执行过程中通过 ScheduleContext.getService() 获取服务
- **THEN** 应返回正确的服务实例

