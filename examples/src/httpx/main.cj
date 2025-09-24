/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 */

package examples.httpx

import cjoy.*
import cjoy.macros.*
import cjoy.httpx.*
import cjoy.middleware.ExceptionHandler

@Get[path = "/page"]
func page(ctx: JoyContext): Unit {
    // 使用Http服务
    let client = ctx.getService<JoyHttpClient>("cj").getOrThrow()
    let rsp = client.get(ctx, "/docs")
    println(rsp.status)
    ctx.string(rsp.text)
}

main(): Int64 {
    let joy = Joy.default()
    joy.router.use(ExceptionHandler())
    // 注册Http服务，配置地址，ClienBudiler配置，你可以定制budilerFn，默认是对https证书全信任
    var client: JoyHttpClient = JoyHttpClientService("https://cangjie-lang.cn/")
    // 配置Basic认证
    client = BasicAuthClient(client, username: "test", password: "test")
    // 配置重试次数
    client = RetryClient(client, maxRetries: 3)
    joy.addService("cj", client)
    JoyHandlers.registerTo(joy)
    joy.run("127.0.0.1", 18881)
    return 0
}
