/*
 * Copyright (c) lanlingx 2024-2024. All rights resvered.
 */

package cjoy.test

import cjoy.json.*
import cjoy.json.utils.*
import std.collection.*
import std.time.DateTime
import std.io.ByteBuffer
import std.unittest.*
import std.unittest.testmacro.*
import encoding.json.stream.*

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
}
