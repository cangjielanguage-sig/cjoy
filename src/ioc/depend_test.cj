/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.ioc

@Test
public class BeanDependManagerTestCaseSuit {
    /**
     * 测试所有 Bean 依赖深度为 0 的场景 - 验证无依赖的 Bean 排序
     */
    @TestCase
    public func testAllDepth0(): Unit {
        let manager = BeanDependManager()
        manager.addDepends("b1", [])
        manager.addDepends("b2", [])
        let r = manager.getSortedBeanDepends()
        @Assert("${r}", "[{beanType:b1,depth:0}, {beanType:b2,depth:0}]")
    }

    /**
     * 测试深度为 2 的 Bean 依赖场景 - 验证单级依赖的 Bean 排序
     */
    @TestCase
    public func testDepth2(): Unit {
        let manager = BeanDependManager()
        manager.addDepends("b1", ["b2"])
        manager.addDepends("b2", [])
        let r = manager.getSortedBeanDepends()
        @Assert("${r}", "[{beanType:b2,depth:0}, {beanType:b1,depth:1}]")
    }

    /**
     * 测试深度为 2 的多依赖 Bean 场景 - 验证具有多个同级依赖的 Bean 排序
     */
    @TestCase
    public func testDepth2_2(): Unit {
        let manager = BeanDependManager()
        manager.addDepends("b1", ["b2", "b3"])
        manager.addDepends("b2", [])
        manager.addDepends("b3", [])
        let r = manager.getSortedBeanDepends()
        @Assert("${r}", "[{beanType:b2,depth:0}, {beanType:b3,depth:0}, {beanType:b1,depth:1}]")
    }

    /**
     * 测试深度为 3 的 Bean 依赖场景 - 验证多级嵌套依赖的 Bean 排序
     */
    @TestCase
    public func testDepth3(): Unit {
        let manager = BeanDependManager()
        manager.addDepends("b1", ["b2"])
        manager.addDepends("b2", ["b3"])
        manager.addDepends("b3", [])
        let r = manager.getSortedBeanDepends()
        @Assert("${r}", "[{beanType:b3,depth:0}, {beanType:b2,depth:1}, {beanType:b1,depth:2}]")
    }

    /**
     * 测试深度为 3 的复杂依赖场景 - 验证具有分支依赖的 Bean 排序
     */
    @TestCase
    public func testDepth3_2(): Unit {
        let manager = BeanDependManager()
        manager.addDepends("b1", ["b4", "b3"])
        manager.addDepends("b2", ["b3"])
        manager.addDepends("b3", [])
        manager.addDepends("b4", ["b3"])
        let r = manager.getSortedBeanDepends()
        @Assert("${r}", "[{beanType:b3,depth:0}, {beanType:b4,depth:1}, {beanType:b2,depth:1}, {beanType:b1,depth:2}]")
    }

    /**
     * 测试深度为 3 的另一种复杂依赖场景 - 验证多种路径依赖的 Bean 排序
     */
    @TestCase
    public func testDepth3_3(): Unit {
        let manager = BeanDependManager()
        manager.addDepends("b1", ["b4", "b2"])
        manager.addDepends("b2", ["b3"])
        manager.addDepends("b3", [])
        manager.addDepends("b4", ["b3"])
        let r = manager.getSortedBeanDepends()
        @Assert("${r}", "[{beanType:b3,depth:0}, {beanType:b4,depth:1}, {beanType:b2,depth:1}, {beanType:b1,depth:2}]")
    }

    /**
     * 测试深度为 4 的 Bean 依赖场景 - 验证更深层次嵌套依赖的 Bean 排序
     */
    @TestCase
    public func testDepth4(): Unit {
        let manager = BeanDependManager()
        manager.addDepends("b1", ["b2"])
        manager.addDepends("b2", ["b3"])
        manager.addDepends("b3", [])
        manager.addDepends("b4", ["b1"])
        let r = manager.getSortedBeanDepends()
        @Assert("${r}", "[{beanType:b3,depth:0}, {beanType:b2,depth:1}, {beanType:b1,depth:2}, {beanType:b4,depth:3}]")
    }

    /**
     * 测试包含接口类型的深度为 5 的依赖场景 - 验证接口依赖的解析和排序
     */
    @TestCase
    public func testInterfaceDepth5(): Unit {
        let manager = BeanDependManager()
        manager.addTypes("b2", ["i2"])
        manager.addDepends("b1", ["i2"])
        manager.addDepends("b2", ["b3"])
        manager.addDepends("b3", [])
        manager.addDepends("b4", ["b1"])
        let r = manager.getSortedBeanDepends(onlyClass: false)
        @Assert("${r}", "[{beanType:b3,depth:0}, {beanType:b2,depth:1}, {beanType:i2,depth:2}, {beanType:b1,depth:3}, {beanType:b4,depth:4}]")
    }

    /**
     * 测试包含接口类型的深度为 6 的依赖场景 - 验证多层接口依赖的解析和排序
     */
    @TestCase
    public func testInterfaceDepth6(): Unit {
        let manager = BeanDependManager()
        manager.addTypes("b2", ["i2"])
        manager.addTypes("b3", ["i3"])
        manager.addDepends("b1", ["i2"])
        manager.addDepends("b2", ["i3"])
        manager.addDepends("b3", [])
        manager.addDepends("b4", ["b1"])
        let r = manager.getSortedBeanDepends(onlyClass: false)
        @Assert("${r}", "[{beanType:b3,depth:0}, {beanType:i3,depth:1}, {beanType:b2,depth:2}, {beanType:i2,depth:3}, {beanType:b1,depth:4}, {beanType:b4,depth:5}]")
    }

    /**
     * 测试包含多个接口类型的深度为 4 的依赖场景 - 验证一个 Bean 实现多个接口的依赖解析
     */
    @TestCase
    public func testInterfaceDepth4(): Unit {
        let manager = BeanDependManager()
        manager.addTypes("b2", ["i2a", "i2b"])
        manager.addDepends("b1", ["i2a"])
        manager.addDepends("b2", ["b3"])
        manager.addDepends("b3", [])
        manager.addDepends("b4", ["i2b"])
        let r = manager.getSortedBeanDepends(onlyClass: false)
        @Assert("${r}", "[{beanType:b3,depth:0}, {beanType:b2,depth:1}, {beanType:i2a,depth:2}, {beanType:i2b,depth:2}, {beanType:b1,depth:3}, {beanType:b4,depth:3}]")
    }

    /**
     * 测试循环依赖错误场景 1 - 验证双向循环依赖会抛出异常
     */
    @TestCase
    public func testErrorDependCycle1(): Unit {
        let manager = BeanDependManager()
        manager.addDepends("b1", ["b2"])
        manager.addDepends("b2", ["b1"])
        try {
            manager.getSortedBeanDepends()
            @Fail("shoud throw a exception")
        } catch (ex: IocException) {
            @Assert(ex.message.contains("depend cycle"))
        }
    }

    /**
     * 测试循环依赖错误场景 2 - 验证三角循环依赖会抛出异常
     */
    @TestCase
    public func testErrorDependCycle2(): Unit {
        let manager = BeanDependManager()
        manager.addDepends("b1", ["b2"])
        manager.addDepends("b2", ["b3"])
        manager.addDepends("b3", ["b1"])
        manager.addDepends("b4", [])
        try {
            manager.getSortedBeanDepends()
            @Fail("shoud throw a exception")
        } catch (ex: IocException) {
            @Assert(ex.message.contains("depend cycle"))
        }
    }

    /**
     * 测试循环依赖错误场景 3 - 验证包含分支的循环依赖会抛出异常
     */
    @TestCase
    public func testErrorDependCycle3(): Unit {
        let manager = BeanDependManager()
        manager.addDepends("b1", ["b2", "b4"])
        manager.addDepends("b2", ["b3"])
        manager.addDepends("b3", ["b1"])
        manager.addDepends("b4", [])
        try {
            manager.getSortedBeanDepends()
            @Fail("shoud throw a exception")
        } catch (ex: IocException) {
            @Assert(ex.message.contains("depend cycle"))
        }
    }

    /**
     * 测试循环依赖错误场景 4 - 验证更复杂的循环依赖结构会抛出异常
     */
    @TestCase
    public func testErrorDependCycle4(): Unit {
        let manager = BeanDependManager()
        manager.addDepends("b1", ["b2"])
        manager.addDepends("b2", ["b3"])
        manager.addDepends("b3", ["b1", "b4"])
        manager.addDepends("b4", [])
        try {
            manager.getSortedBeanDepends()
            @Fail("shoud throw a exception")
        } catch (ex: IocException) {
            @Assert(ex.message.contains("depend cycle"))
        }
    }

    /**
     * 测试未实现接口的错误场景 1 - 验证依赖未实现的接口会抛出异常（当前被跳过）
     */
    @TestCase
    @Skip // 支持接口可选依赖
    public func testErrorNotImplInterface1(): Unit {
        let manager = BeanDependManager()
        manager.addDepends("b1", ["i2a"])
        manager.addDepends("b2", [])
        try {
            manager.getSortedBeanDepends()
            @Fail("shoud throw a exception")
        } catch (ex: IocException) {
            @Assert(ex.message.contains("not found any class implements inferface"))
        }
    }

    /**
     * 测试未实现接口的错误场景 2 - 验证依赖指定类未实现的接口会抛出异常
     */
    @TestCase
    public func testErrorNotImplInterface2(): Unit {
        let manager = BeanDependManager()
        manager.addTypes("x", ["i2a", "i2b"])
        manager.addDepends("b1", ["i2a"])
        manager.addDepends("b2", [])
        try {
            manager.getSortedBeanDepends()
            @Fail("shoud throw a exception")
        } catch (ex: IocException) {
            @Assert(ex.message.contains("not found class `x` implements interface `i2a`"))
        }
    }

    /**
     * 测试依赖变化后重新计算深度 - 验证新注册的无依赖 Bean 排在已有依赖者之前
     */
    @TestCase
    public func testDepthInvalidatedOnRegister(): Unit {
        let manager = BeanDependManager()
        manager.addDepends("a", [])
        manager.addDepends("b", ["a"])
        let first = manager.getSortedBeanDepends()
        @Assert(first.size, 2)

        manager.addDepends("c", [])
        let second = manager.getSortedBeanDepends()
        @Assert(second.size, 3)
        @Assert(second[1].beanType, "c")
        @Assert(second[2].beanType, "b")
    }
}
