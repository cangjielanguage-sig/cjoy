# 调度任务

## Crontab

CJoy提供Linux风格的crontab定时调度任务管理。

支持两种风格：

 - 六段式：second minute hour day month week
 - 五段式：minute hour day month week

取值范围：
  - second: 0~59
  - minute: 0~59
  - hour: 0~23
  - day: 1~31
  - month: 1~12
  - week: 0~6

示例：

 - `* * * * * *`: 每 1 秒钟执行一次
 - `* * * * *`: 每 1 分钟执行一次 
 - `0,15,30,45,8-12 * * *`:  在 8 点 到12 点每隔 15 分钟执行
 - `3,15 8-11 * * *`: 在上午 8 点到 11 点的第 3 和第 15 分钟执行
 - `3,15 8-11 */2 * *` : 每隔两天的上午 8 点到 11 点的第 3 和第 15 分钟执行
  

任务回调函数原型：

```
public type ScheduleFunc = (ctx: ScheduleContext) -> Unit
```

 - 只有一个入参：ScheduleContext，调度任务多次执行时，您可以在上下文中记录一些信息在下次回调时再使用。

## 使用方式1：

使用示例：[examples/schedule](../../examples/src/schedule/main.cj) 。

采用宏标注，CJoy框架会自动把回调函数注册给全局的Crontab服务。

```
@Scheduled[name = "metric job", cron = "*/2 * * * * *"]
func logMetric(ctx: ScheduleContext): Unit {
    LogTool.info("log metric in crontab ...")
}
```

|宏属性参数|默认值|是否可选|说明|
|---|---|---|---|
|`name`|函数名|是|Job名称，要求全局唯一|
|`cron`||否|crontab表达式|

注：宏@Scheduled也可以配合IoC框架，在Bean上的函数上使用。

## 使用方式2：

在Http Handler或Midlleware中使用，适合于收到Http请求时再创建调度任务

```
@Post[path = "/crontab"]
func addCrontab(ctx: JoyContext): Unit {
    // 先根据服务名获取服务
    let crontab = ctx.getService<Crontab>("crontab").getOrThrow()
    crontab.addJobIfAbsent("the name", "*/5 * * * * *",
        {
            schedCtx: ScheduleContext => LogTool.info("another crontab ...")
        })
}
```

注：每个Joy实例会默认存在一个名为`crontab`的Crontab服务。


----
<< [返回](../../README.md#使用指导)