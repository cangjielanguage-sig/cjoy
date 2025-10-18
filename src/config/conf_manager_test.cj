/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.config

import std.collection.{HashMap, ArrayList}
import cjoy.bind.*

@Test
public class ConfigManagerTestCaseSuit {
    @TestCase
    public func testSimple1(): Unit {
        let loader = ArgConfigLoader(["-Da=1", "-Db=2"])
        let manager = ConfigManager()
        manager.addLoader(loader)
        @Assert(manager.hashKey("a"), true)
        @Assert(manager.hashKey("b"), true)
        @Assert(manager.getValue("a") ?? "", "1")
        @Assert(manager.getValue("b") ?? "", "2")
        @Assert(manager.bind<Int>("a") ?? 0, 1)
        @Assert(manager.bind<Int>("b") ?? 0, 2)
    }

    @TestCase
    public func testSimpleArray1(): Unit {
        let loader = ArgConfigLoader(["-Da[0]=1", "-Da[1]=2"])
        let manager = ConfigManager()
        manager.addLoader(loader)
        @Assert(manager.getValue("a[0]") ?? "", "1")
        @Assert(manager.getValue("a[1]") ?? "", "2")
        @Assert(manager.bind<Int>("a[0]") ?? 0, 1)
        @Assert(manager.bind<Int>("a[1]") ?? 0, 2)
    }

    @TestCase
    public func testChain1(): Unit {
        let loader = ArgConfigLoader(["-Da.b.c=1", "-Da.b.d=2"])
        let manager = ConfigManager()
        manager.addLoader(loader)
        @Assert(manager.getValue("a.b.c") ?? "", "1")
        @Assert(manager.getValue("a.b.d") ?? "", "2")
        @Assert(manager.bind<Int>("a.b.c") ?? 0, 1)
        @Assert(manager.bind<Int>("a.b.d") ?? 0, 2)
    }

    @TestCase
    public func testChainArray1(): Unit {
        let loader = ArgConfigLoader(["-Da.b[0].c=1", "-Da.b[1].c=2"])
        let manager = ConfigManager()
        manager.addLoader(loader)
        @Assert(manager.getValue("a.b[0].c") ?? "", "1")
        @Assert(manager.getValue("a.b[1].c") ?? "", "2")
        @Assert(manager.bind<Int>("a.b[0].c") ?? 0, 1)
        @Assert(manager.bind<Int>("a.b[1].c") ?? 0, 2)
    }

    @TestCase
    public func testChainArray2(): Unit {
        let loader = ArgConfigLoader(["-Da.b[0]=1", "-Da.b[1]=2"])
        let manager = ConfigManager()
        manager.addLoader(loader)
        @Assert(manager.getValue("a.b[0]") ?? "", "1")
        @Assert(manager.getValue("a.b[1]") ?? "", "2")
        @Assert(manager.bind<Int>("a.b[0]") ?? 0, 1)
        @Assert(manager.bind<Int>("a.b[1]") ?? 0, 2)
    }

    @TestCase
    @Skip
    public func testBindChainArray(): Unit {
        let loader = ArgConfigLoader(["-Da.b[0]=1", "-Da.b[1]=2"])
        let manager = ConfigManager()
        manager.addLoader(loader)
        let res = manager.bind<Array<Int>>("a.b").getOrThrow()
        @Assert(res, [1, 2])
    }

    @TestCase
    public func testBindChainInt(): Unit {
        let loader = ArgConfigLoader(["-Da.b.c=1"])
        let manager = ConfigManager()
        manager.addLoader(loader)
        let res = manager.bind<TestData1>("a").getOrThrow()
        @Assert(res.b.c, 1)
    }
}

@Bind
class TestData1 {
    let b: TestData2
}

@Bind
class TestData2 {
    var c: Int = 0
}
