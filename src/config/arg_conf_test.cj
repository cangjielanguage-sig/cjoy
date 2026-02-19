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
import cjoy.macros.*

@Test
public class ArgConfigTestCaseSuit {
    /**
     * 测试简单参数解析 - 解析基本的键值对参数
     */
    @TestCase
    public func testSimple1(): Unit {
        let loader = ArgConfigLoader(["-Da=1", "-Db=2"])
        let data = loader.load()
        @Assert(cs(data["a"]), "1")
        @Assert(cs(data["b"]), "2")
    }

    /**
     * 测试含等号的值解析 - 解析包含等号的参数值
     */
    @TestCase
    public func testValueWithEqualSign(): Unit {
        let loader = ArgConfigLoader(["-Da=1=2", "-Db=value=with=equals"])
        let data = loader.load()
        @Assert(cs(data["a"]), "1=2")
        @Assert(cs(data["b"]), "value=with=equals")
    }

    /**
     * 测试加载器优先级 - 验证加载器优先级设置功能
     */
    @TestCase
    public func testPriority(): Unit {
        let loader1 = ArgConfigLoader(["-Da=1"], priorityNum: 10)
        let loader2 = ArgConfigLoader(["-Da=2"], priorityNum: 20)
        @Assert(loader1.priority, 10)
        @Assert(loader2.priority, 20)
    }

    /**
     * 测试空参数 - 解析空参数列表
     */
    @TestCase
    public func testEmptyArgs(): Unit {
        let loader = ArgConfigLoader([])
        let data = loader.load()
        @Assert(data.size, 0)
    }

    /**
     * 测试含特殊字符的参数 - 解析包含特殊字符和中文字符的参数
     */
    @TestCase
    public func testArgWithSpecialChars(): Unit {
        let loader = ArgConfigLoader(["-Da=!@#$%^&*()", "-Db=你好世界"])
        let data = loader.load()
        @Assert(cs(data["a"]), "!@#$%^&*()")
        @Assert(cs(data["b"]), "你好世界")
    }

    /**
     * 测试简单数组参数1 - 解析数组形式的参数
     */
    @TestCase
    public func testSimpleArray1(): Unit {
        let loader = ArgConfigLoader(["-Da[0]=1", "-Da[1]=2"])
        let data = loader.load()
        let x = ca(data["a"])
        @Assert(cs(x[0]), "1")
        @Assert(cs(x[1]), "2")
    }

    /**
     * 测试简单数组参数2 - 解析无序的数组参数，验证是否按索引排序
     */
    @TestCase
    public func testSimpleArray2(): Unit {
        let loader = ArgConfigLoader(["-Da[1]=2", "-Da[0]=1"])
        let data = loader.load()
        let x = ca(data["a"])
        @Assert(cs(x[0]), "1")
        @Assert(cs(x[1]), "2")
    }

    /**
     * 测试链式参数1 - 解析嵌套的链式参数（如 a.b.c）
     */
    @TestCase
    public func testChain1(): Unit {
        let loader = ArgConfigLoader(["-Da.b.c=1", "-Da.b.d=2"])
        let data = loader.load()
        let x = cm(cm(data["a"])["b"])
        @Assert(cs(x["c"]), "1")
        @Assert(cs(x["d"]), "2")
    }

    /**
     * 测试链式数组参数1 - 解析包含数组的复杂链式参数（如 a.b[0].c）
     */
    @TestCase
    public func testChainArray1(): Unit {
        let loader = ArgConfigLoader(["-Da.b[0].c=1", "-Da.b[1].c=2"])
        let data = loader.load()
        let x = ca(cm(data["a"])["b"])
        @Assert(cs(cm(x[0])["c"]), "1")
        @Assert(cs(cm(x[1])["c"]), "2")
    }

    /**
     * 测试链式数组参数2 - 解析数组作为值的链式参数（如 a.b[0]）
     */
    @TestCase
    public func testChainArray2(): Unit {
        let loader = ArgConfigLoader(["-Da.b[0]=1", "-Da.b[1]=2"])
        let data = loader.load()
        let x = ca(cm(data["a"])["b"])
        @Assert(cs(x[0]), "1")
        @Assert(cs(x[1]), "2")
    }

    /**
     * 测试键名转换1 - 验证驼峰命名到连字符命名的转换（如 abCd 转 ab-cd）
     */
    @TestCase
    public func testTansferKeys1(): Unit {
        let loader = ArgConfigLoader(["-Djoy.abCd[0]=1", "-Djoy.abCd[1]=2"])
        let data = loader.load()
        let x = ca(cm(data["joy"])["ab-cd"])
        @Assert(cs(x[0]), "1")
        @Assert(cs(x[1]), "2")
    }

    /**
     * 测试键名转换2 - 验证首字母大写的驼峰命名到连字符命名的转换（如 AbCd 转 ab-cd）
     */
    @TestCase
    public func testTansferKeys2(): Unit {
        let loader = ArgConfigLoader(["-Djoy.AbCd[0]=1", "-Djoy.AbCd[1]=2"])
        let data = loader.load()
        let x = ca(cm(data["joy"])["ab-cd"])
        @Assert(cs(x[0]), "1")
        @Assert(cs(x[1]), "2")
    }

    /**
     * 测试覆盖错误1 - 验证配置项覆盖时的错误处理
     */
    @TestCase
    public func testErrOverwrite1(): Unit {
        let args = [
            ["-Da.b=1", "-Da=2"],
            ["-Da=1", "-Da.b=2"],
            ["-Da=1", "-Da=2"],
            ["-Da.b=1", "-Da.b=2"],
            ["-Da.b[0].1=1", "-Da.b[0].1=2"],
            ["-Da.b[0].1=1", "-Da.b.1=2"],
            ["-Da.b.1=1", "-Da.b[0].1=2"]
        ]
        for (x in args) {
            try {
                let loader = ArgConfigLoader(x)
                loader.load()
                @Fail("should throw exception")
            } catch (ex: ConfigException) {
                @Assert(ex.message.contains("invalid config"))
            }
        }
    }

    /**
     * 测试自引用错误 - 验证配置项自引用时的错误处理
     */
    @TestCase
    public func testErrSelfRef(): Unit {
        let args = [["-Da=1", #"-Db=${b}"#]]
        for (x in args) {
            try {
                let loader = ArgConfigLoader(x)
                loader.load()
                @Fail("should throw exception")
            } catch (ex: ConfigException) {
                @Assert(ex.message.contains("the config express is invalid"))
            }
        }
    }

    /**
     * 测试中文字符参数 - 验证包含中文字符的配置项解析
     */
    @TestCase
    public func testCh1(): Unit {
        let loader = ArgConfigLoader(["-Da=中国", "-Db=仓颉"])
        let data = loader.load()
        @Assert(cs(data["a"]), "中国")
        @Assert(cs(data["b"]), "仓颉")
    }
}

func cm(a: Any) {
    (a as HashMap<String, Any>).getOrThrow()
}

func cs(a: Any) {
    (a as String).getOrThrow()
}

func ca(a: Any) {
    (a as ArrayList<Any>).getOrThrow()
}
