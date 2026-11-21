/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.test

import cjoy.*
import cjoy.ioc.*
import cjoy.macros.*
import cjoy.schedule.*
import cjoy.validation.*
import cjoy.eventbus.*
import cjoy.config.*

// -------- @Autowired指定名称注入
@Component
class Bean1 {
    private let _bean2: Bean2
    init(@Autowired[name = "bean2"] b2: Bean2) {
        _bean2 = b2
    }
}

@Component[name = "bean2"]
class Bean2 {}

// -------- 可选注入接口测试
interface Inter1 {}

@Component
class Bean3 {
    init(itner: ?Inter1) {
    }
}

// -------- Array注入接口测试
interface Inter2 {}

@Component[extends = ["Inter2"]]
class Bean4 <: Inter2 {}

@Component[extends = ["Inter2"]]
class Bean5 <: Inter2 {}

@Component
class Bean6 {
    init(arr: Array<Inter2>) {
    }
}

// -------- 多个注入
@Component
class Bean7 {
    init(b6: Bean6, b1: Bean1) {
    }

    @Validated
    public func validate(@NotEmpty input: String): Unit {
    }

    @Scheduled[cron = "*/20 3-5/2 22 */5 4"]
    func schuedule(ctx: ScheduleContext): Unit {
    }
}

// -------- @Controller + @Get等方法
@Controller[path = "/test"]
class BeanController {
    @Get[path = "/p1"]
    func get(ctx: JoyContext): Unit {
    }

    @Post[path = "/p2/{name}"]
    func post(ctx: JoyContext, @PathParam name: String): Unit {
    }

    @Patch[path = "/p3"]
    func patch(ctx: JoyContext): Unit {
    }

    @Head[path = "/p4"]
    func head(ctx: JoyContext): Unit {
    }

    @Scheduled[cron = "*/20 3-5/2 22 */5 4"]
    func schuedule(ctx: ScheduleContext): Unit {
    }

    @SubscribeEvent[name = "sub2", pattern = "a.b.c.d"]
    func handleEvent(ctx: Context, evt: Event): Unit {
    }
}

// -------- 配置注入
@Component
class Bean8 {
    @Value[#"${a.b.c:1}"#]
    let v1: Int // @Value会自动赋值

    @Value[#"${a.b.d:abc}"#]
    let v2: String

    @Value[#"${a.b.d:abc}"#]
    let v3: ?Int

    @Value[#"${a.b.d:abc}"#]
    let v4: ?String
}

@Test
public class IocTestCaseSuit {
    /**
     * 测试 IoC 容器功能 - 验证各种 IoC 容器功能，包括组件注册、依赖注入等
     */
    @TestCase
    public func test(): Unit {
        let joy = Joy.default()
        JoyMiddlewares.registerTo(joy)
        JoyHandlers.registerTo(joy)
        let fut = spawn {
            joy.run("127.0.0.1", 18882)
        }
        sleep(Duration.second)
        fut.cancel()
    }
}
