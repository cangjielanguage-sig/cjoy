# 调度任务

CJoy 提供完整的定时任务调度系统，支持crontab表达式和动态任务管理。

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
| 秒(可选) | 0-59 | 秒级精度 |
| 分 | 0-59 | 分钟 |
| 小时 | 0-23 | 24小时制 |
| 日 | 1-31 | 月份中的日期 |
| 月 | 1-12 | 月份 |
| 周 | 0-6 | 星期日(0)到星期六(6) |

### 时间单位符号

| 符号 | 说明 | 示例 |
|------|------|------|
| `*` | 任意值 | `*` 表示每分钟 |
| `,` | 多个值 | `0,15,30,45` 表示每15分钟 |
| `-` | 范围 | `8-12` 表示8到12点 |
| `/` | 步长 | `*/2` 表示每2个单位 |
| `?` | 特定时间 | `0 8 * * 5` 表示每周五8点 |

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
 << [返回](../../README.md#使用指导)