/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.test

import cjoy.*
import cjoy.macros.*
import cjoy.validation.*

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
}

@Controller[path = "/test"]
class BeanController {
    @Get[path = "/p1"]
    func get(ctx: JoyContext): Unit {
    }

    @Post[path = "/p2/{name}"]
    func post(ctx: JoyContext, @PathParam name: String): Unit {
    }
}

@Test
public class IocTestCaseSuit {
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
