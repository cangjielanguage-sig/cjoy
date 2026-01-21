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

@Test
public class ArgConfigTestCaseSuit {
    @TestCase
    public func testSimple1(): Unit {
        let loader = ArgConfigLoader(["-Da=1", "-Db=2"])
        let data = loader.load()
        @Assert(cs(data["a"]), "1")
        @Assert(cs(data["b"]), "2")
    }

    @TestCase
    public func testSimpleArray1(): Unit {
        let loader = ArgConfigLoader(["-Da[0]=1", "-Da[1]=2"])
        let data = loader.load()
        let x = ca(data["a"])
        @Assert(cs(x[0]), "1")
        @Assert(cs(x[1]), "2")
    }

    @TestCase
    public func testSimpleArray2(): Unit {
        let loader = ArgConfigLoader(["-Da[1]=2", "-Da[0]=1"])
        let data = loader.load()
        let x = ca(data["a"])
        @Assert(cs(x[0]), "1")
        @Assert(cs(x[1]), "2")
    }

    @TestCase
    public func testChain1(): Unit {
        let loader = ArgConfigLoader(["-Da.b.c=1", "-Da.b.d=2"])
        let data = loader.load()
        let x = cm(cm(data["a"])["b"])
        @Assert(cs(x["c"]), "1")
        @Assert(cs(x["d"]), "2")
    }

    @TestCase
    public func testChainArray1(): Unit {
        let loader = ArgConfigLoader(["-Da.b[0].c=1", "-Da.b[1].c=2"])
        let data = loader.load()
        let x = ca(cm(data["a"])["b"])
        @Assert(cs(cm(x[0])["c"]), "1")
        @Assert(cs(cm(x[1])["c"]), "2")
    }

    @TestCase
    public func testChainArray2(): Unit {
        let loader = ArgConfigLoader(["-Da.b[0]=1", "-Da.b[1]=2"])
        let data = loader.load()
        let x = ca(cm(data["a"])["b"])
        @Assert(cs(x[0]), "1")
        @Assert(cs(x[1]), "2")
    }

    @TestCase
    public func testTansferKeys1(): Unit {
        let loader = ArgConfigLoader(["-Djoy.abCd[0]=1", "-Djoy.abCd[1]=2"])
        let data = loader.load()
        let x = ca(cm(data["joy"])["ab-cd"])
        @Assert(cs(x[0]), "1")
        @Assert(cs(x[1]), "2")
    }

    @TestCase
    public func testTansferKeys2(): Unit {
        let loader = ArgConfigLoader(["-Djoy.AbCd[0]=1", "-Djoy.AbCd[1]=2"])
        let data = loader.load()
        let x = ca(cm(data["joy"])["ab-cd"])
        @Assert(cs(x[0]), "1")
        @Assert(cs(x[1]), "2")
    }

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
