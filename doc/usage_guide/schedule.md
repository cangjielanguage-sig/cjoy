# 调度任务

CJoy 提供完整的定时任务调度系统，支持crontab表达式和动态任务管理。

---

## 概述

CJoy 调度系统基于以下核心概念设计：

- **Crontab表达式**：支持标准Linux crontab语法
- **宏驱动**：通过`@Scheduled`宏自动注册任务
- **IoC集成**：完美集成IoC容器的Bean管理
- **上下文传递**：支持任务执行上下文信息传递
- **异常处理**：完整的任务异常处理和日志记录

### Crontab表达式支持

| 字段 | 取值范围 | 说明 |
|------|-----------|------|
| 秒(可选） | 0-59 | 秒级精度 |
| 分 | 0-59 | 分钟 |
| 小时 | 0-23 | 24小时制 |
| 日 | 1-31 | 月份中的日期 |
| 月 | 1-12 | 月份 |
| 周 | 0-6 | 星期日(0）到星期六(6） |

### 时间单位符号

| 符号 | 说明 | 示例 |
|------|------|------|
| `*` | 任意值 | `*` 表示每分钟 |
| `,` | 多个值 | `0,15,30,45` 表示每15分钟 |
| `-` | 范围 | `8-12` 表示8到12点 |
| `/` | 步长 | `*/2` 表示每2个单位 |
| `?` | 特定时间 | `0 8 * * 5` 表示每周五8点 |

核心类：`ScheduleContext`，参见 [schedule.cj](../../src/schedule/schedule.cj)

---

## 一、基本用法

### 1.1 简单定时任务

```cangjie
import cjoy.schedule.*
import cjoy.macros.*

// 每分钟执行一次
@Scheduled[name = "minuteTask", cron = "* * * * *"]
func minuteTask(ctx: ScheduleContext): Unit {
    @JoyLogInfo("每分钟执行的任务")
}
```

### 1.2 指定执行时间

```cangjie
// 每天凌晨2点执行
@Scheduled[name = "dailyTask", cron = "0 2 * * *"]
func dailyTask(ctx: ScheduleContext): Unit {
    @JoyLogInfo("每天凌晨2点执行的任务")
}

// 每周一到周五的上午9点执行
@Scheduled[name = "workdayTask", cron = "0 9 * * 1-5"]
func workdayTask(ctx: ScheduleContext): Unit {
    @JoyLogInfo("工作日上午9点执行")
}
```

---

## 二、Crontab表达式示例

### 2.1 常用表达式

| 表达式 | 说明 |
|---------|------|
| `* * * * *` | 每分钟执行 |
| `*/5 * * * *` | 每5分钟执行 |
| `0 * * * *` | 每小时的第0分钟执行 |
| `0 0 * * *` | 每天凌晨执行 |
| `0 0 * * 0` | 每周日凌晨执行 |
| `0 0 1 * *` | 每月1号凌晨执行 |
| `0,30 * * * *` | 每小时的第0和第30分钟执行 |
| `0 9-17 * * *` | 每天9点到17点每小时执行 |
| `0 9 * * 1-5` | 周一到周五每天9点执行 |

### 2.2 复杂表达式

```cangjie
// 每15分钟执行
@Scheduled[name = "quarterHour", cron = "*/15 * * * *"]
func quarterHour(ctx: ScheduleContext): Unit {
    @JoyLogInfo("每15分钟执行")
}

// 工作日每小时执行
@Scheduled[name = "workdayHourly", cron = "0 * * * 1-5"]
func workdayHourly(ctx: ScheduleContext): Unit {
    @JoyLogInfo("工作日每小时执行")
}

// 每月最后一天执行
@Scheduled[name = "monthEnd", cron = "0 0 L * *"]
func monthEnd(ctx: ScheduleContext): Unit {
    @JoyLogInfo("每月最后一天执行")
}
```

---

## 三、ScheduleContext

`ScheduleContext` 提供任务执行的上下文信息：

```cangjie
@Scheduled[name = "contextTask", cron = "0 * * * *"]
func contextTask(ctx: ScheduleContext): Unit {
    // 获取任务名称
    @JoyLogInfo("任务名称: ${ctx.name}")

    // 获取任务执行时间
    @JoyLogInfo("执行时间: ${ctx.executionTime}")

    // 存储自定义数据
    ctx.put("customKey", "customValue")

    // 获取自定义数据
    if (let Some(value) <- ctx.get<String>("customKey")) {
        @JoyLogInfo("自定义数据: ${value}")
    }
}
```

---

## 四、性能优化与注意事项

### 4.1 Cron表达式优化

| 表达式类型 | 示例 | 说明 | 性能考虑 |
|------------|------|------|-----------|
| 固定时间 | `0 12 * * *` | 每天中午12点 | 性能最优 |
| 间隔执行 | `*/15 * * * *` | 每15分钟 | 性能良好 |
| 范围限制 | `0 9-17 * * 1-5` | 工作日9-17点 | 避免非工作时间 |
| 复杂组合 | `0,30 8-12,14-17 * * 1-5` | 复杂业务规则 | 合理使用 |

### 4.2 任务执行优化

```cangjie
// 异步执行长时间任务
@Scheduled[name = "asyncTask", cron = "0 2 * * *"]
func asyncScheduledTask(ctx: ScheduleContext): Unit {
    // 使用spawn异步执行，避免阻塞调度器
    spawn {
        let startTime = DateTime.now()

        try {
            // 长时间任务
            performLongRunningOperation()

            let duration = startTime.elapsedMilliseconds()
            ctx.put("executionTime", "${duration}ms")
            println("异步任务完成，耗时: ${duration}ms")

        } catch (e: Exception) {
            ctx.put("error", e.message)
            println("异步任务失败: ${e.message}")
        }
    }
}

// 批量处理优化
@Scheduled[name = "batchProcessor", cron = "*/30 * * * *"]
func batchProcessor(ctx: ScheduleContext): Unit {
    let batchSize = 100
    let processedCount = 0

    try {
        // 分批处理大量数据
        while (true) {
            let batch = getPendingDataBatch(batchSize)
            if (batch.isEmpty) {
                break
            }

            processBatch(batch)
            processedCount += batch.size

            // 短暂休息，避免资源占用过高
            if (processedCount % 10 == 0) {
                Thread.sleep(Duration.millisecond * 100)
            }
        }

        ctx.put("processedCount", "${processedCount}")

    } catch (e: Exception) {
        ctx.put("error", e.message)
        println("批量处理失败: ${e.message}")
    }
}
```

### 4.3 错误处理策略

```cangjie
// 任务执行超时控制
@Scheduled[name = "timeoutTask", cron = "*/10 * * * *"]
func timeoutTask(ctx: ScheduleContext): Unit {
    let timeout = Duration.second * 60  // 60秒超时

    // 使用spawn配合超时控制
    let task = spawn {
        try {
            executeWithTimeout(timeout, {
                // 可能长时间运行的任务
                performTimeoutOperation()
            })

        } catch (e: TimeoutException) {
            ctx.put("status", "timeout")
            ctx.put("error", "任务执行超时")
            println("任务执行超时")

        } catch (e: Exception) {
            ctx.put("status", "error")
            ctx.put("error", e.message)
            println("任务执行失败: ${e.message}")
        }
    }

    // 等待任务完成（带超时）
    task.join()
}
```

### 4.4 注意事项

| 注意事项 | 说明 | 最佳实践 |
|----------|------|----------|
| **资源竞争** | 多个任务同时访问共享资源 | 使用锁或事务机制 |
| **异常隔离** | 一个任务异常不应影响调度器 | 完善的异常处理和日志记录 |
| **内存管理** | 长时间任务可能导致内存泄漏 | 及时释放资源，避免循环引用 |
| **时钟同步** | 依赖系统时间的准确性 | 使用NTP同步，考虑时区问题 |
| **任务依赖** | 复杂任务可能有依赖关系 | 设计合理的任务执行顺序或使用状态机 |

### 4.5 常见问题解决

**Q: Cron表达式不生效？**
A: 检查表达式语法、时区设置、系统时间

**Q: 任务执行延迟？**
A: 检查任务执行时间、系统负载、调度器队列状态

**Q: 任务突然停止执行？**
A: 检查异常处理、内存使用、日志中的错误信息

**Q: 如何处理任务堆积？**
A: 优化任务执行时间、增加并发处理能力、考虑任务优先级

---
## 五、注意事项

1. **任务名称唯一**：每个任务的 `name` 参数必须唯一

2. **Cron表达式格式**：确保使用标准的 crontab 表达式格式

3. **线程安全**：任务执行函数应该是线程安全的

4. **异常处理**：任务内部应做好异常处理，避免影响调度器

5. **执行时间控制**：长时间任务应使用 `spawn` 异步执行

6. **资源清理**：任务完成后应释放占用的资源

7. **日志记录**：建议记录任务执行的开始、结束和异常信息

---
<< [返回](../../README.md#使用指导)
