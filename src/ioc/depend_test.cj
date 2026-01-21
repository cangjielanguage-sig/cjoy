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
    @TestCase
    public func testAllDepth0(): Unit {
        let manager = BeanDependManager()
        manager.addDepends("b1", [])
        manager.addDepends("b2", [])
        let r = manager.getSortedBeanDepends()
        @Assert("${r}", "[{beanType:b1,depth:0}, {beanType:b2,depth:0}]")
    }

    @TestCase
    public func testDepth2(): Unit {
        let manager = BeanDependManager()
        manager.addDepends("b1", ["b2"])
        manager.addDepends("b2", [])
        let r = manager.getSortedBeanDepends()
        @Assert("${r}", "[{beanType:b2,depth:0}, {beanType:b1,depth:1}]")
    }

    @TestCase
    public func testDepth2_2(): Unit {
        let manager = BeanDependManager()
        manager.addDepends("b1", ["b2", "b3"])
        manager.addDepends("b2", [])
        manager.addDepends("b3", [])
        let r = manager.getSortedBeanDepends()
        @Assert("${r}", "[{beanType:b2,depth:0}, {beanType:b3,depth:0}, {beanType:b1,depth:1}]")
    }

    @TestCase
    public func testDepth3(): Unit {
        let manager = BeanDependManager()
        manager.addDepends("b1", ["b2"])
        manager.addDepends("b2", ["b3"])
        manager.addDepends("b3", [])
        let r = manager.getSortedBeanDepends()
        @Assert("${r}", "[{beanType:b3,depth:0}, {beanType:b2,depth:1}, {beanType:b1,depth:2}]")
    }

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
            @Assert(ex.message.contains("not found the class `x` implements inferface"))
        }
    }
}
