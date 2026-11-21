/*
 * Copyright (c) 2026 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.ioc

import std.unittest.testmacro.*

class TestLifecycleBean <: BeanLifecycle {
    var destroyed = false

    public override func beforeDestroy(): Unit {
        destroyed = true
    }
}

class TestBeanFactory <: BeanFactory {
    TestBeanFactory(let beanTypeName: String, let scope: BeanScope) {}

    public prop beanType: String {
        get() { beanTypeName }
    }

    public prop beanScope: BeanScope {
        get() { scope }
    }

    public func create(ctx: ApplicationContext): (String, BeanLifecycle) {
        ("test-bean", TestLifecycleBean())
    }
}

@Test
public class DefaultApplicationContextTestCaseSuit {
    /**
     * 测试销毁后重新初始化 - 验证按类型缓存被清理且容器可以再次创建 Bean
     */
    @TestCase
    public func testDestroyAndReinit(): Unit {
        let ctx = DefaultApplicationContext()
        ctx._beanDependManager.addDepends("X", [])
        ctx._factories.add("X", TestBeanFactory("X", SINGLETON))

        ctx.createAllBeans()
        @Assert(ctx.getBeanByTypeName<TestLifecycleBean>("X").isSome(), true)

        ctx.destroyAllBeans()
        @Assert(ctx.getBeanByTypeName<TestLifecycleBean>("X").isNone(), true)

        ctx.createAllBeans()
        @Assert(ctx.getBeanByTypeName<TestLifecycleBean>("X").isSome(), true)
    }

    /**
     * 测试复数查询包含原型 Bean - 验证接口存在多个实现时不会抛异常
     */
    @TestCase
    public func testPrototypeBeansInPluralLookup(): Unit {
        let ctx = DefaultApplicationContext()
        ctx._beanDependManager.addDepends("A", [])
        ctx._beanDependManager.addDepends("B", [])
        ctx._beanDependManager.addTypes("A", ["I"])
        ctx._beanDependManager.addTypes("B", ["I"])
        ctx._factories.add("A", TestBeanFactory("A", PROTOTYPE))
        ctx._factories.add("B", TestBeanFactory("B", PROTOTYPE))

        let beans = ctx.getBeansByTypeName<TestLifecycleBean>("I")
        @Assert(beans.size, 2)
    }
}
