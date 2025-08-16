# 服务启动

启动服务实例，如下所示：

```
main(): Int64 {
    // 创建joy实例
    let joy = Joy.default()
    // 运行并绑定在指定IP与Port
    joy.run("127.0.0.1", 18881)
    return 0
}
```

## 实例

`JoyConfig`结构体提供对服务实例一些个性化配置参数：

```
let cfg = JoyConfig(enableDebugLog: false)
let joy = Joy.create(cfg)
```

|参数|默认值|说明|
|---|---|---|
|remoteIPHeaders||设置信任的获取远端IP的头域名，如X-Forwarded-For，但头域通常可以伪造，需要结合前端Nginx这类配置一起审视|
|enableDebugLog|true|是否开启debug级别的日志，在生产环境需要设置为false|
|caseInsensitive|false|是否对路径的path大小写不敏感|
|escapeAddedRoutes|false|是否在添加路由时，对Path进行转义处理|
|notFoundHandler|JoyNotFoundHandler|找不到路由的Handler|
|methodNotAllowedHandler|JoyMethodNotAllowedHandler|Method不允许的Handler|

注：调用`Joy.default()`创建的实例，配置都采用默认值。

`Joy类`提供`create`方法，支持创建多个不同配置的实例，启动绑定在不同的IP与Port。

```
// 采用默认配置，创建名为inst1的实例
let joy1 = Joy.create("inst1")

// 指定配置，创建名为inst2的实例
let cfg = JoyConfig(enableDebugLog: false)
let joy2 = Joy.create(cfg, "inst2")
```

## 启动

`Joy类`提供`run`方法支持不同的启动方法，一旦调用`run`方法会阻塞当前线程：

```
// http，绑定在127.0.0.1:18881
joy.run("127.0.0.1", 18881)

// https 1.x，绑定在127.0.0.1:18881
let certificatePath = "src/tls/server_cert.pem"
let certificateKeyPath = "src/tls/server_key.pem"
joy.run("127.0.0.1", 18881, certificatePath, certificateKeyPath)

// http2，绑定在127.0.0.1:18881
joy.run("127.0.0.1", 18881, certificatePath, certificateKeyPath, h2: true)

// 调用官方SDK，创建serverBuidler，指定其它的参数，具体参数请参见官方SDK的API说明
let serverBuidler = ServerBuilder().addr(addr).port(port).tlsConfig(tlsConfig)
joy.run(serverBuidler)
```

也可以在其它线程中异步启动实例，在另一个线程主动关闭实例：

```
let joy = Joy.default()
spawn { =>
    joy.run("127.0.0.1", 18881)
}

// 在一些场景下主动关闭，调用shutdown方法
// gracefully 表示是否优雅关闭退出
joy.shutdown(gracefully: true)
```

