CJoy - a fast and joy web framework
=======
一个高性能、轻量、省事的Web框架。

## 样例

```
import cjoy.*

main(): Int64 {
    var cfg = JoyConfig()
    cfg.enableDebugLog=true
    // 创建joy实例
    let joy = Joy.create(cfg)

    // 注册路由
    joy.router.GET("/:name", {ctx: JoyContext => 
        let name = ctx.getParam("name").getOrDefault({=>"no name"})
        ctx.writeStr("name in wildcard path, name=${name}")
    })
    joy.router.GET("/abc", {ctx: JoyContext => 
        ctx.writeStr("static path abc")
    })

    // 启动服务
    joy.run("127.0.0.1", 18881)
    return 0
}
```