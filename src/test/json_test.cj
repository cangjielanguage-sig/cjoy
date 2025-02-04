/*
 * Copyright (c) lanlingx 2024-present. All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.test

import cjoy.json.*
import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

@Json
public struct S0 {
    var rune: Rune = r'x'
    var str: String = "str"
    var ui8: UInt8 = b'x'
    var u32: UInt32 = 12345678
    var i64: Int64 = 1000i64
    var f64: Float64 = .123e2
    var bool: Bool = true
    var arr: Array<Int32> = [1, 2, 3, 4]
    var list: ArrayList<String> = ArrayList<String>(["str1", "str2", "str3"])
    var map: HashMap<String, Int64> = HashMap<String, Int64>([("k1", 1i64), ("k2", 2i64)])
}

@Json
public struct SIngore {
    var str: String = "str"
    @JsonField[ignore = true]
    var ignore: String = "ignore"
}

@Json
public struct SRename {
    var str: String = "str1"
    @JsonField[name = newName]
    var str2: String = "str2"
}

@Json
public struct SOmitempty {
    @JsonField[omitempty = true]
    var strOption: ?String = None
    @JsonField[omitempty = true]
    var strEmtpy: String = ""
    var str1: String = "str1"
    var strNull: ?String = None
}

@Json
public struct SDataNull {
    var a: Option<String> = None
}

@Json
public struct SDataTimeFormat {
    var t1: DateTime = DateTime.parse("2023-01-20T11:25:26+08:00")

    @JsonField[timeformat = "HH:mm:ss MM/dd/yyyy OO"]
    var t2: DateTime = DateTime.parse("2023-01-20T11:25:26+08:00")

    @JsonField[name = "time", timeformat = "HH:mm:ss MM/dd/yyyy OO"]
    var t3: DateTime = DateTime.parse("2023-01-20T11:25:26+08:00")
}

@Json
public class DataClass {
    var width: Int64 = 10
    var height: Int64 = 20
}

@Json
public class DataNestedTop {
    @JsonField[name = "d2_a"]
    var a: Int32 = 10

    @JsonField[name = "d2_b"]
    var b: String = "str"

    @JsonField[name = "nested1_c", omitempty = true]
    var c: Option<DataNested1> = None

    @JsonField[omitempty = true]
    var d: String = ""

    @JsonField[omitempty = true]
    var e: Option<String> = None
}

@Json
public class DataNested1 {
    @JsonField[name = "nested_a"]
    var a: Option<DataNested2> = None

    var t1: DateTime = DateTime.now()

    @JsonField[timeformat = "yyyy/MM/dd HH:mm:ss OO"]
    var t2: DateTime = DateTime.now()
}

@Json
public class DataNested2 {
    var mstr: String = "a_str"

    @JsonField[ignore = true]
    var strIgnore: String = "b_str"

    var mi64: Int64 = 1000i64

    var mu32: UInt32 = 123456

    var mbool: Bool = true

    var arr: Array<Int32> = [1, 2, 3, 4]

    var list: ArrayList<DataClass> = ArrayList<DataClass>()

    var map: HashMap<String, DataClass> = HashMap<String, DataClass>()
}

@Test
public class JsonTestCaseSuit {
    @TestCase
    public func testBase() {
        let s0 = S0()
        let str = JsonTool.toJson(s0)
        println(str)

        let d = JsonTool.fromJson<S0>(str)
        @Assert(d.rune, r'x')
        @Assert(d.str, "str")
    }

    @TestCase
    public func testIgnore() {
        let s = SIngore()
        let str = JsonTool.toJson(s)
        let expect = #"{"str":"str"}"#
        @Assert(str, expect)
        let s1 = JsonTool.fromJson<SIngore>(str)
        @Assert(s1.str, s.str)
        @Assert(s1.ignore, s.ignore)
    }

    @TestCase
    public func testRename() {
        let s = SRename()
        let str = JsonTool.toJson(s)
        let expect = #"{"str":"str1","newName":"str2"}"#
        @Assert(str, expect)
        let s1 = JsonTool.fromJson<SRename>(str)
        @Assert(s1.str, s.str)
        @Assert(s1.str2, s.str2)
    }

    @TestCase
    public func testOmitempty() {
        let s = SOmitempty()
        let str = JsonTool.toJson(s)
        let expect = #"{"str1":"str1","strNull":null}"#
        @Assert(str, expect)
        let s1 = JsonTool.fromJson<SOmitempty>(str)
        @Assert(s1.str1, s.str1)
        @Assert(s1.strNull, s.strNull)
    }

    @TestCase
    public func testNull(): Unit {
        let s = SDataNull()
        let str = JsonTool.toJson(s)
        println(str)
        let json = ###"{"a":null}"###
        @Assert(str, json)
    }

    @TestCase
    public func testTimeFormat(): Unit {
        let s = SDataTimeFormat()
        let str = JsonTool.toJson(s)
        println(str)
        let json = ###"{"t1":"2023-01-20T11:25:26+08:00","t2":"11:25:26 01/20/2023 +08:00","time":"11:25:26 01/20/2023 +08:00"}"###
        @Assert(str, json)

        let data2 = JsonTool.fromJson<SDataTimeFormat>(str)
        @Assert(data2.t1, DateTime.parse("2023-01-20T11:25:26+08:00"))
        @Assert(data2.t2, DateTime.parse("2023-01-20T11:25:26+08:00"))
    }

    @TestCase
    public func testClass(): Unit {
        var data = DataClass()
        data.width = 100
        data.height = 200
        let str = JsonTool.toJson(data)
        println(str)
        let json = ###"{"width":100,"height":200}"###
        @Assert(str, json)

        let data2 = JsonTool.fromJson<DataClass>(str)
        @Assert(data2.width, data.width)
        @Assert(data2.height, data.height)
    }

    @TestCase
    public func testNested(): Unit {
        var top = DataNestedTop()
        top.a = 20
        top.b = "lanlingx"

        var dn1 = DataNested1()
        top.c = Some(dn1)

        var dn2 = DataNested2()
        dn1.a = Some(dn2)

        dn2.mstr = "new_str"
        dn2.list.add(DataClass())
        dn2.list.add(DataClass())
        dn2.map.add("k1", DataClass())
        dn2.map.add("k2", DataClass())

        let str = JsonTool.toJson(top)
        println(str)

        let ts = JsonTool.fromJson<DataNestedTop>(str)
        @Assert(ts.a, 20)
        @Assert(ts.b, "lanlingx")

        @Assert(ts.c?.a?.mstr, "new_str")
        @Assert(ts.c?.a?.mi64, 1000)
        @Assert(ts.c?.a?.mbool, true)
        @Assert(ts.c?.a?.list.size, 2)
        @Assert(ts.c?.a?.map.size, 2)
    }
}
