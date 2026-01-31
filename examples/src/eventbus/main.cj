/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 */

package examples.eventbus

import cjoy.*
import cjoy.macros.*
import cjoy.eventbus.*
import cjoy.ioc.*
import cjoy.middleware.ExceptionHandler

@JoyCreateLogger("examples.eventbus")

// 采用宏标注函数，函数有两个参数
@SubscribeEvent[name = "sub1", pattern = "a.b.**"]
func handleEvent1(ctx: Context, evt: Event): Unit {
    @JoyLogInfo("handle event ${evt.name} in func")
}

@Post[path = "/publish-event"]
func doSomething(ctx: JoyContext): Unit {
    let bus = ctx.getService<EventBus>("event").getOrThrow()
    // 异步发送事件
    bus.fireEventAsync(ctx, Event.of("a.b.c.d").addData("a", "v"))
}

@Component
class Bean {
    // 在Bean中宏标注函数
    @SubscribeEvent[name = "sub2", pattern = "a.b.c.d"]
    func handleEvent(ctx: Context, evt: Event): Unit {
        @JoyLogInfo("handle event ${evt.name} in bean")
    }
}

main(): Int64 {
    let joy = Joy.default()
    joy.router.use(ExceptionHandler())

    // 注册所有生成的handlers
    JoyMiddlewares.registerTo(joy)
    JoyHandlers.registerTo(joy)
    joy.run("127.0.0.1", 18881)
    return 0
}
