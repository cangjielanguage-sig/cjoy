# 日志

## 默认日志

CJoy内置一个日志工具JoyLoggerFactory，用于创建Logger对象，默认日志输出到Console。

您可以修改日志输出方式：
 - 单独一个package(假定名为abcd.log)下一个文件, 此package不会引入cjoy非cjoy.log其它package 
 - 调用 let _ : Unit = JoyLoggerFactory.registerCreator(...) 来注册其它的日志框架生成器
 - 在main方法，最先import abcd.log，让JoyLoggerFactory.registerCreator先于所有静态初始化

## 请求访问日志

CJoy内置请求访问日志AccessLog中间件，您可以指定如下：

```cangjie
// 方式1：使用JoyLoggerFactory.createLogger(...)输出访问日志
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
- 生产环境下打开AccessLog用于记录每次的请求访问。

使用示例: [examples/logger](../../examples/src/logger/main.cj) 。

## 日志宏

CJoy提供如下几个日志宏，建议应用优先采用宏打印日志。

 - `@JoyCreateLogger`: 创建日志对象
 - `@JoyLogDebug`: 使用日志对象打印DEBUG级日志
 - `@JoyLogInfo`: 使用日志对象打印INFO级日志
 - `@JoyLogWarn`: 使用日志对象打印WARN级日志
 - `@JoyLogError`: 使用日志对象打印ERROR级日志

使用方式：
 
 - 在package这一层，任一文件指定@JoyCreateLogger("name")
 - 在此package下任一文件中使用@JoyLogXXX宏打印日志

实现参见: [log/macros](../../src/log/macros/macros.cj) 。宏当前增加如下日志内容：

 - 当前线程名或ID
 - 日志输出所在文件名
 - 日志输出所在行号
 - 日志输出所在package名

格式示例：`2026-01-31T22:18:19.233594401+08:00 INFO 1 [cjoy.framework/engine.cj:72] create joy app default`

----
<< [返回](../../README.md#使用指导)
