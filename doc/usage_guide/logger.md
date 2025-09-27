# 日志

## 默认日志

CJoy内置一个日志工具类LogTool，默认日志输出到Console。

注意：`Joy.default()` 创建的实例，默认为把日志级别设置为Debug级。

您可以

 - 修改日志输出方式：在main方法最开始的地方，设置 LogTool.logger = Logger对象
 - 关闭日志调试： 指定enableDebugLog: false

```
let cfg = JoyConfig(enableDebugLog: false)
let joy = Joy.create(cfg)
```

## 请求访问日志

CJoy内置请求访问日志AccessLog中间件，您可以指定如下：

```
// 方式1：使用LogTool.logger输出访问日志
joy.router.use(AccessLog())

// 方式2：指定自己的Logger对象
joy.router.use(AccessLog(logger: logger))

// 方式3：指定自己过滤条件
joy.router.use(AccessLog(filterFn: {
    ctx: JoyContext =>
    // 忽略/heartbeat
    ctx.path != "/heartbeat"
}))
```

说明： 
- enableDebugLog通常只在调试阶段开启，在生产环境下您应该关闭以获取更好的性能。
- 生产环境下打开AccessLog用于记录每次的请求访问。

使用示例: [examples/logger](../../examples/src/logger/main.cj) 。

## 日志宏

CJoy提供如下几个日志宏，建议应用优先采用宏打印日志，后续框架考虑扩展其它附加信息丰富日志内容。

 - `@LogDebug`
 - `@LogInfo`
 - `@LogWarn`
 - `@LogError`
  
实现参见: [log/macros](../../src/log/macros/macros.cj) 。宏当前增加如下日志内容：

 - 当前线程名或ID
 - 日志输出所在文件名
 - 日志输出所在行号

----
<< [返回](../../README.md#使用指导)
