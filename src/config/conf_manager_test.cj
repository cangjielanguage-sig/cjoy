/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.config

import std.collection.{HashMap, ArrayList}
import std.env.*
import cjoy.bind.*
import cjoy.macros.*

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

    @TestCase
    public func testResolve1(): Unit {
        let loader = ArgConfigLoader(["-Da=1"])
        let manager = ConfigManager()
        manager.addLoader(loader)
        let res = manager.resolve(#"${a}"#)
        @Assert(res, "1")
    }

    @TestCase
    public func testResolve2(): Unit {
        let loader = ArgConfigLoader(["-Da[0]=1"])
        let manager = ConfigManager()
        manager.addLoader(loader)
        let res = manager.resolve(#"${a[0]}"#)
        @Assert(res, "1")
    }

    @TestCase
    public func testResolve3(): Unit {
        let loader = ArgConfigLoader(["-Da.b.c=1"])
        let manager = ConfigManager()
        manager.addLoader(loader)
        let res = manager.resolve(#"${a.b.c}"#)
        @Assert(res, "1")
    }

    @TestCase
    public func testResolve4(): Unit {
        let loader = ArgConfigLoader(["-Da.b[0].c=1"])
        let manager = ConfigManager()
        manager.addLoader(loader)
        let res = manager.resolve(#"${a.b[0].c}"#)
        @Assert(res, "1")
    }

    @TestCase
    public func testResolveDefault1(): Unit {
        let loader = ArgConfigLoader(["-Db=1"])
        let manager = ConfigManager()
        manager.addLoader(loader)
        let res = manager.resolve(#"${a:2}"#)
        @Assert(res, "2")
    }

    @TestCase
    public func testResolveDefault2(): Unit {
        let loader = ArgConfigLoader(["-Da[0]=1"])
        let manager = ConfigManager()
        manager.addLoader(loader)
        let res = manager.resolve(#"${b[0]:2}"#)
        @Assert(res, "2")
    }

    @TestCase
    public func testResolveTwo1(): Unit {
        let loader = ArgConfigLoader(["-Da=1", "-Db=2"])
        let manager = ConfigManager()
        manager.addLoader(loader)
        let res = manager.resolve(#"${a}-${b}"#)
        @Assert(res, "1-2")
    }

    @TestCase
    public func testResolveTwo2(): Unit {
        let loader = ArgConfigLoader(["-Da=1", "-Db=2"])
        let manager = ConfigManager()
        manager.addLoader(loader)
        let res = manager.resolve(#"${a}:${b}"#)
        @Assert(res, "1:2")
    }

    @TestCase
    public func testResolveReferOther1(): Unit {
        let loader = ArgConfigLoader(["-Da=1", #"-Db=${a}"#])
        let manager = ConfigManager()
        manager.addLoader(loader)
        let res = manager.resolve(#"${b:2}"#)
        @Assert(res, "1")
    }

    @TestCase
    public func testResolveReferEnv(): Unit {
        let loader = ArgConfigLoader([#"-Da=${HOME}"#])
        let manager = ConfigManager()
        manager.addLoader(loader)
        let res = manager.resolve(#"${a}"#)
        @Assert(res, "${getVariable("HOME") ?? ""}")
    }

    @TestCase
    public func testEqualSign(): Unit {
        let loader = ArgConfigLoader(["-Da==1", #"-Db=2="#])
        let manager = ConfigManager()
        manager.addLoader(loader)
        let res = manager.resolve(#"${a}-${b}"#)
        @Assert(res, "=1-2=")
    }

    @TestCase
    public func testPriority(): Unit {
        let loader1 = PropertiesConfigLoader("./testdata/joy.properties")
        let loader2 = JsonConfigLoader("./testdata/joy.json")
        let manager = ConfigManager()
        manager.addLoader(loader1)
        manager.addLoader(loader2)
        @Assert(manager.getValue("joy.server.address", ""), "0.0.0.0")
        @Assert(manager.getValue("joy.server.port", ""), "18882")
        @Assert(manager.getValue("joy.server.http.remote-ip-header", ""), "X-FORWARDED-FOR")
    }

    @TestCase
    public func testEnvVariableConfig(): Unit {
        let key = "TEST_CONFIG_VAR"
        let value = "test_value"
        let manager = ConfigManager()
        @Assert(manager.hashKey("PATH"), true) // 检查是否能访问到 PATH 环境变量
    }

    @TestCase
    public func testConfigNotFound(): Unit {
        let manager = ConfigManager()
        @Assert(manager.hashKey("nonexistent.config"), false)
        @Assert(manager.getValue("nonexistent.config") ?? "", "")
        @Assert(manager.getValue("nonexistent.config", "default"), "default")
        match (manager.bind<Int>("nonexistent.config")) {
            case None => @Assert(true)
            case Some(_) => @Fail("should return None for nonexistent config")
        }
    }

    @TestCase
    public func testBindMoreTypes(): Unit {
        let loader = ArgConfigLoader(["-Db=true", "-Df=3.14", "-Ds=test_string"])
        let manager = ConfigManager()
        manager.addLoader(loader)

        @Assert(manager.bind<Bool>("b") ?? false, true)
        @Assert(manager.bind<Float64>("f") ?? 0.0, 3.14)
        @Assert(manager.bind<String>("s") ?? "", "test_string")
    }

    @TestCase
    public func testResolveComplexExpressions(): Unit {
        let loader = ArgConfigLoader(["-Da=10", "-Db=20", #"-Dc=${a}+${b}"#, #"-Dd=${c}*2"#])
        let manager = ConfigManager()
        manager.addLoader(loader)

        @Assert(manager.resolve(#"${a}+${b}"#), "10+20")
        @Assert(manager.resolve(#"${c}"#), "10+20")
        @Assert(manager.resolve(#"${d}"#), "10+20*2")
    }

    @TestCase
    public func testResolveWithDefaultValue(): Unit {
        let manager = ConfigManager()
        @Assert(manager.resolve(#"${nonexistent:default_value}"#), "default_value")
        @Assert(manager.resolve(#"${missing.config:123}"#), "123")
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
