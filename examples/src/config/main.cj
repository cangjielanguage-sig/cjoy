/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 */

package examples.config

import cjoy.*
import cjoy.macros.*
import cjoy.config.*
import cjoy.ioc.*
import cjoy.log.macros.*

@Get[path = "/config"]
func config(ctx: JoyContext): String {
    // 在Handler中使用配置项
    let config = ctx.getService<Config>("config").getOrThrow()
    config.getValue("joy.server.http.remote-ip-header", "")
}

@Component
class Handler {
    // 在Component中注入配置项，会自动根据项从配置中取值并赋值给成员变量
    @Value[#"${joy.server.address:127.0.0.1}"#]
    let address: String

    // 引用环境变量
    @Value[#"${HOME:/home/abc}"#]
    let home: String

    public init() {
        @LogInfo("address:${address}")
        @LogInfo("home:${home}")
    }
}

main(args: Array<String>): Int64 {
    // 配置加载
    let config = ConfigManager.INSTANCE;
    // 命令行参数，Properties与Json文件配置，根据优先级获取对应的配置
    let loader1 = ArgConfigLoader(args)
    let loader2 = PropertiesConfigLoader("../testdata/joy.properties")
    let loader3 = JsonConfigLoader("../testdata/joy.json")
    config.addLoader(loader1, loader2, loader3)

    // 创建joy实例
    let joy = Joy.default()
    // 注册生成的handlers
    JoyMiddlewares.registerTo(joy)
    JoyHandlers.registerTo(joy)
    // 使用配置项
    joy.run(config.getValue("joy.server.address", "127.0.0.1"), config.bind<UInt16>("joy.server.port") ?? 18881)
    return 0
}
