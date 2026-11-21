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
    /**
     * 测试简单配置管理 - 验证基本的配置加载和访问功能
     */
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

    /**
     * 测试简单数组配置 - 验证数组类型配置的加载和访问
     */
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

    /**
     * 测试链式配置 - 验证嵌套配置（如 a.b.c）的加载和访问
     */
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

    /**
     * 测试链式数组配置1 - 验证包含数组的复杂嵌套配置（如 a.b[0].c）的加载和访问
     */
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

    /**
     * 测试链式数组配置2 - 验证数组作为值的链式配置（如 a.b[0]）的加载和访问
     */
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

    /**
     * 测试链式数组绑定 - 验证将数组配置绑定到 Array<Int> 类型
     */
    @TestCase
    public func testBindChainArray(): Unit {
        let loader = ArgConfigLoader(["-Da.b[0]=1", "-Da.b[1]=2"])
        let manager = ConfigManager()
        manager.addLoader(loader)
        let res = manager.bind<Array<Int>>("a.b").getOrThrow()
        @Assert(res, [1, 2])
    }

    /**
     * 测试链式对象绑定 - 验证将嵌套配置绑定到自定义类型对象
     */
    @TestCase
    public func testBindChainInt(): Unit {
        let loader = ArgConfigLoader(["-Da.b.c=1"])
        let manager = ConfigManager()
        manager.addLoader(loader)
        let res = manager.bind<TestData1>("a").getOrThrow()
        @Assert(res.b.c, 1)
    }

    /**
     * 测试配置解析1 - 验证基本配置表达式的解析（如 ${a}）
     */
    @TestCase
    public func testResolve1(): Unit {
        let loader = ArgConfigLoader(["-Da=1"])
        let manager = ConfigManager()
        manager.addLoader(loader)
        let res = manager.resolve(#"${a}"#)
        @Assert(res, "1")
    }

    /**
     * 测试配置解析2 - 验证数组配置表达式的解析（如 ${a[0]}）
     */
    @TestCase
    public func testResolve2(): Unit {
        let loader = ArgConfigLoader(["-Da[0]=1"])
        let manager = ConfigManager()
        manager.addLoader(loader)
        let res = manager.resolve(#"${a[0]}"#)
        @Assert(res, "1")
    }

    /**
     * 测试配置解析3 - 验证嵌套配置表达式的解析（如 ${a.b.c}）
     */
    @TestCase
    public func testResolve3(): Unit {
        let loader = ArgConfigLoader(["-Da.b.c=1"])
        let manager = ConfigManager()
        manager.addLoader(loader)
        let res = manager.resolve(#"${a.b.c}"#)
        @Assert(res, "1")
    }

    /**
     * 测试配置解析4 - 验证复杂嵌套数组配置表达式的解析（如 ${a.b[0].c}）
     */
    @TestCase
    public func testResolve4(): Unit {
        let loader = ArgConfigLoader(["-Da.b[0].c=1"])
        let manager = ConfigManager()
        manager.addLoader(loader)
        let res = manager.resolve(#"${a.b[0].c}"#)
        @Assert(res, "1")
    }

    /**
     * 测试默认值解析1 - 验证配置不存在时返回默认值（如 ${a:2}）
     */
    @TestCase
    public func testResolveDefault1(): Unit {
        let loader = ArgConfigLoader(["-Db=1"])
        let manager = ConfigManager()
        manager.addLoader(loader)
        let res = manager.resolve(#"${a:2}"#)
        @Assert(res, "2")
    }

    /**
     * 测试默认值解析2 - 验证数组配置不存在时返回默认值（如 ${b[0]:2}）
     */
    @TestCase
    public func testResolveDefault2(): Unit {
        let loader = ArgConfigLoader(["-Da[0]=1"])
        let manager = ConfigManager()
        manager.addLoader(loader)
        let res = manager.resolve(#"${b[0]:2}"#)
        @Assert(res, "2")
    }

    /**
     * 测试多表达式解析1 - 验证包含多个配置表达式的字符串解析（如 ${a}-${b}）
     */
    @TestCase
    public func testResolveTwo1(): Unit {
        let loader = ArgConfigLoader(["-Da=1", "-Db=2"])
        let manager = ConfigManager()
        manager.addLoader(loader)
        let res = manager.resolve(#"${a}-${b}"#)
        @Assert(res, "1-2")
    }

    /**
     * 测试多表达式解析2 - 验证包含多个配置表达式的字符串解析（如 ${a}:${b}）
     */
    @TestCase
    public func testResolveTwo2(): Unit {
        let loader = ArgConfigLoader(["-Da=1", "-Db=2"])
        let manager = ConfigManager()
        manager.addLoader(loader)
        let res = manager.resolve(#"${a}:${b}"#)
        @Assert(res, "1:2")
    }

    /**
     * 测试配置引用解析 - 验证配置项引用其他配置项的解析（如 ${b} 引用 ${a}）
     */
    @TestCase
    public func testResolveReferOther1(): Unit {
        let loader = ArgConfigLoader(["-Da=1", #"-Db=${a}"#])
        let manager = ConfigManager()
        manager.addLoader(loader)
        let res = manager.resolve(#"${b:2}"#)
        @Assert(res, "1")
    }

    /**
     * 测试环境变量引用解析 - 验证配置项引用环境变量的解析（如 ${HOME}）
     */
    @TestCase
    public func testResolveReferEnv(): Unit {
        let loader = ArgConfigLoader([#"-Da=${HOME}"#])
        let manager = ConfigManager()
        manager.addLoader(loader)
        let res = manager.resolve(#"${a}"#)
        @Assert(res, "${getVariable("HOME") ?? ""}")
    }

    /**
     * 测试等号处理 - 验证配置值包含等号的解析和处理
     */
    @TestCase
    public func testEqualSign(): Unit {
        let loader = ArgConfigLoader(["-Da==1", #"-Db=2="#])
        let manager = ConfigManager()
        manager.addLoader(loader)
        let res = manager.resolve(#"${a}-${b}"#)
        @Assert(res, "=1-2=")
    }

    /**
     * 测试加载器优先级 - 验证不同配置加载器的优先级处理
     */
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

    /**
     * 测试环境变量配置 - 验证对系统环境变量的访问
     */
    @TestCase
    public func testEnvVariableConfig(): Unit {
        let key = "TEST_CONFIG_VAR"
        let value = "test_value"
        let manager = ConfigManager()
        @Assert(manager.hashKey("PATH"), true) // 检查是否能访问到 PATH 环境变量
    }

    /**
     * 测试配置未找到 - 验证配置项不存在时的处理方式
     */
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

    /**
     * 测试多种类型绑定 - 验证对不同数据类型配置的绑定（布尔值、浮点数、字符串）
     */
    @TestCase
    public func testBindMoreTypes(): Unit {
        let loader = ArgConfigLoader(["-Db=true", "-Df=3.14", "-Ds=test_string"])
        let manager = ConfigManager()
        manager.addLoader(loader)

        @Assert(manager.bind<Bool>("b") ?? false, true)
        @Assert(manager.bind<Float64>("f") ?? 0.0, 3.14)
        @Assert(manager.bind<String>("s") ?? "", "test_string")
    }

    /**
     * 测试复杂表达式解析 - 验证包含多个配置引用的复杂表达式解析
     */
    @TestCase
    public func testResolveComplexExpressions(): Unit {
        let loader = ArgConfigLoader(["-Da=10", "-Db=20", #"-Dc=${a}+${b}"#, #"-Dd=${c}*2"#])
        let manager = ConfigManager()
        manager.addLoader(loader)

        @Assert(manager.resolve(#"${a}+${b}"#), "10+20")
        @Assert(manager.resolve(#"${c}"#), "10+20")
        @Assert(manager.resolve(#"${d}"#), "10+20*2")
    }

    /**
     * 测试带默认值的解析 - 验证配置不存在时返回指定默认值的功能
     */
    @TestCase
    public func testResolveWithDefaultValue(): Unit {
        let manager = ConfigManager()
        @Assert(manager.resolve(#"${nonexistent:default_value}"#), "default_value")
        @Assert(manager.resolve(#"${missing.config:123}"#), "123")
    }

    /**
     * 测试数组空洞回填 - 验证先设置高索引再设置低索引的子键不会报错
     */
    @TestCase
    public func testArrayGapNestedKey(): Unit {
        let loader = ArgConfigLoader(["-Da.b[1].x=1", "-Da.b[0].y=2"])
        let manager = ConfigManager()
        manager.addLoader(loader)
        @Assert(manager.getValue("a.b[0].y", ""), "2")
        @Assert(manager.getValue("a.b[1].x", ""), "1")
    }

    /**
     * 测试数组空洞不存在 - 验证未设置的索引不会报告为已存在
     */
    @TestCase
    public func testArrayGapIsAbsent(): Unit {
        let loader = ArgConfigLoader(["-Da[1]=2"])
        let manager = ConfigManager()
        manager.addLoader(loader)
        @Assert(manager.hashKey("a[0]"), false)
        @Assert(manager.getValue("a[0]").isNone(), true)
    }

    /**
     * 测试值中嵌入的占位符 - 验证 getValue 与 resolve 行为一致
     */
    @TestCase
    public func testEmbeddedPlaceholder(): Unit {
        let loader = ArgConfigLoader([#"-Da=prefix-${HOME}"#])
        let manager = ConfigManager()
        manager.addLoader(loader)
        let val = manager.getValue("a", "")
        @Assert(val.startsWith("prefix-"), true)
        @Assert(val.contains(#"${"#), false)
    }

    /**
     * 测试数组按优先级合并 - 验证高优先级只覆盖对应元素而不是整个数组
     */
    @TestCase
    public func testArrayMergeByElement(): Unit {
        let low = ArgConfigLoader(["-Da[0]=1", "-Da[1]=2"], priorityNum: 1)
        let high = ArgConfigLoader(["-Da[1]=20"], priorityNum: 2)
        let manager = ConfigManager()
        manager.addLoader([low, high])
        @Assert(manager.getValue("a[0]", ""), "1")
        @Assert(manager.getValue("a[1]", ""), "20")
    }

    /**
     * 测试数组中对象的键名转换 - 验证嵌套对象的 camelCase 键可被查询
     */
    @TestCase
    public func testConvertKeysInsideArray(): Unit {
        let loader = ArgConfigLoader(["-Ditems[0].userName=bob"])
        let manager = ConfigManager()
        manager.addLoader(loader)
        @Assert(manager.getValue("items[0].userName", ""), "bob")
    }

    /**
     * 测试转换键名不覆盖已有键 - 保证相同语义的两种写法结果确定
     */
    @TestCase
    public func testConvertedKeyDoesNotOverwrite(): Unit {
        let loader = ArgConfigLoader(["-DmaxConnections=100", "-Dmax-connections=200"])
        let manager = ConfigManager()
        manager.addLoader(loader)
        @Assert(manager.getValue("max-connections", ""), "200")
    }

    /**
     * 测试多个占位符 - 验证无循环引用时不受总数量限制
     */
    @TestCase
    public func testManyPlaceholders(): Unit {
        let manager = ConfigManager()
        let keys = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k"]
        let args = keys.map {k => "-D" + k + "=" + k}
        manager.addLoader(ArgConfigLoader(args))
        let parts = keys.map {k => #"${KEY}"#.replace("KEY", k)}
        let exp = String.join(parts, delimiter: "")
        @Assert(manager.resolve(exp), "abcdefghijk")
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
