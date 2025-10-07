# 服务框架

服务指为应用开发提供一些功能的实例，如调试任务服务，Cache服务等。

CJoy提供服务注册与使用能力。

## 注册

```
let joy = Joy.default()
// 注册服务给Joy实例，指定服务名，与服务实例
joy.addService("crontab", Crontab())
```

## 使用

可以在Handler与Middleware中使用注册的服务，如下所示：

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

# 内置服务

 - [IoC服务](../../doc/usage_guide/ioc.md)
 - [调度任务](../../doc/usage_guide/schedule.md)
 - [Http服务](../../doc/usage_guide/httpx.md)
 - [事件总线](../../doc/usage_guide/eventbus.md)

----
<< [返回](../../README.md#使用指导)