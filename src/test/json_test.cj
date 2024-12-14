package cjoy.test

import cjoy.json.*
import cjoy.json.generate.*
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
    @JsonField[ignore=true]
    var ignore: String = "ignore"
}

@Json
public struct SRename {
    var str: String = "str1"
    @JsonField[name=newName]
    var str2: String = "str2"
}

@Test
public class TestCaseSuit {
    @TestCase
    public func testBase() {
        let s0 = S0()
        let str = s0.toJson()
        println(str)

        let d = S0.fromJson(str)
        @Assert(d.rune, r'x')
        @Assert(d.str, "str")
    }

    @TestCase
    public func testIgnore() {
        let s = SIngore()
        let str = s.toJson()
        let expect = #"{"str":"str"}"#
        @Assert(str, expect)
        let s1 = SIngore.fromJson(str)
        @Assert(s1.str, s.str)
        @Assert(s1.ignore, s.ignore)
    }

    @TestCase
    public func testRename() {
        let s = SRename()
        let str = s.toJson()
        let expect = #"{"str":"str1","newName":"str2"}"#
        @Assert(str, expect)
        let s1 = SRename.fromJson(str)
        @Assert(s1.str, s.str)
        @Assert(s1.str2, s.str2)
    }
}