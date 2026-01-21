/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.test

import cjoy.json.*
import cjoy.json.macros.*
import std.collection.*
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

@Json
public class DataAny {
    var a: Any = 1
    var b: Any = 2
    var c: Any = HashMap<String, Any>()
}

@Json
public class DataAny2 {
    var a: Any = 1
    var b: Any = 2
    @JsonField[raw = true]
    var c: Any = HashMap<String, Any>()
}

@Json[description: "user info"]
class UserSchema {
    @JsonField[description: "the user name"]
    var name: String = ""
    @JsonField[description: "the address of user", required: false]
    var address: String = ""
    @JsonField[description: "the user gender"]
    var gender: Int = 0

    @JsonField[schema: { 
 "type": "object", 
 "description": "the user addon info", 
 "properties": { 
 "info1": { 
 "type": "string", 
 "description": "xxxx", 
 } 
 }, 
 "required": [ info1 ] 
 }]
    var addOnInfo: HashMap<String, String> = HashMap()

    @JsonField[description: "option desc"]
    var f1: Option<String> = None
    @JsonField[description: "arr desc"]
    var arr: Array<String> = Array()
}

@Json[subTypeField = "mimeType", subTypes = { "text": "TextResourceContents", "blob": "BlobResourceContents" }]
private open class ResourceContents {
    public var mimeType: String = ""
}

@Json[superClass = ResourceContents]
private class TextResourceContents <: ResourceContents {
    public var text: String = ""
    public var text2: String = ""
}

@Json[superClass = ResourceContents]
private class BlobResourceContents <: ResourceContents {
    public var blob: String = ""
    public var blob2: String = ""
}

@Json
private class ReadResourceResult {
    // 类型为基类，实际根据mimeType的值反序列化为TextResourceContents或BlobResourceContents
    public var contents: ArrayList<ResourceContents> = ArrayList()
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

    @TestCase
    public func testExcessField1(): Unit {
        let json = ###"{"width": 1, "height": 2, "others": "xxx"}"###
        let dc = JsonTool.fromJson<DataClass>(json)
        @Assert(dc.width, 1)
        @Assert(dc.height, 2)
    }

    @TestCase
    public func testExcessField2(): Unit {
        let json = ###"{"width": 1, "height": 2, "others": {"k1": 1, "k2": "v2"}}"###
        let dc = JsonTool.fromJson<DataClass>(json)
        @Assert(dc.width, 1)
        @Assert(dc.height, 2)
    }

    @TestCase
    public func testExcessField3(): Unit {
        let json = ###"{"width": 1, "height": 2, "others": null}"###
        let dc = JsonTool.fromJson<DataClass>(json)
        @Assert(dc.width, 1)
        @Assert(dc.height, 2)
    }

    @TestCase
    public func testToAny1(): Unit {
        let str = ###"{"a": 1, "b": 2, "c": {"c1": "c1v", "c2": 1.1}, "d":[{"d1": true, "d2": null},{"d1": false, "d2": "d2v"}]}"###
        let ts = JsonTool.fromJsonToSerializable(str)
        match (ts) {
            case m: HashMap<String, JsonSerializable> => @Assert(4, m.size )
            case _ => @Fail("deserialize failed")
        }
    }

    @TestCase
    public func testToAny2(): Unit {
        let str = ###"{"a": 1, "b": 2, "c": {"c1": "c1v", "c2": 1.1}, "d":[{"d1": true, "d2": null},{"d1": false, "d2": "d2v"}]}"###
        let dc = JsonTool.fromJson<DataAny>(str)
        @Assert((dc.a as Int64).getOrThrow(), 1)
        @Assert((dc.b as Int64).getOrThrow(), 2)
    }

    @TestCase
    public func testToAny3(): Unit {
        let str = ###"{"a": 1, "b": 2, "c": {"c1": "c1v", "c2": 1.1}, "d":[{"d1": true, "d2": null},{"d1": false, "d2": "d2v"}]}"###
        let dc = JsonTool.fromJson<DataAny2>(str)
        let c = String.fromUtf8((dc.c as Array<Byte>).getOrThrow())
        @Assert(c, ###"{"c1": "c1v", "c2": 1.1}"###)
    }

    @TestCase
    public func testAnyToJson(): Unit {
        var dc = DataAny()
        dc.c = HashMap<String, String>([("c1", "v1"), ("c2", "v2")])
        let str = JsonTool.toJson(dc)
        let expect = ###"{"a":1,"b":2,"c":{"c1":"v1","c2":"v2"}}"###
        @Assert(str, expect)
    }

    @TestCase
    public func testToJsonSimpleObj(): Unit {
        let d = @ToJson(
            {
                "a": 1,
                "b": "xyz",
                "c": 1.1,
                "d": true
            }
        )
        let str = JsonTool.toJson(d)
        println(str)
        let expect = ###"{"a":1,"b":"xyz","c":1.1,"d":true}"###
        @Assert(str, expect)
    }

    @TestCase
    public func testToJsonSimpleObjWithVar1(): Unit {
        let b = "xyz"
        let d = @ToJson(
            {
                "a": 1,
                "b": "${b}",
                "c": 1.1,
                "d": true
            }
        )
        let str = JsonTool.toJson(d)
        println(str)
        let expect = ###"{"a":1,"b":"xyz","c":1.1,"d":true}"###
        @Assert(str, expect)
    }

    @TestCase
    public func testToJsonSimpleObjWithVar2(): Unit {
        let b = "xyz"
        let d = @ToJson(
            {
                "a": 1,
                "b": b,
                "c": 1.1,
                "d": true
            }
        )
        let str = JsonTool.toJson(d)
        println(str)
        let expect = ###"{"a":1,"b":"xyz","c":1.1,"d":true}"###
        @Assert(str, expect)
    }

    @TestCase
    public func testToJsonSimpleArr(): Unit {
        let d = @ToJson(
            [
                1,
                "xyz",
                1.1,
                true
            ]
        )
        let str = JsonTool.toJson(d)
        println(str)
        let expect = ###"[1,"xyz",1.1,true]"###
        @Assert(str, expect)
    }

    @TestCase
    public func testToJsonComplex1(): Unit {
        let x = "xyz"
        let d = @ToJson(
            {
                "a":{
                    "a1":1,
                    "a2":x,
                    "a3":{
                        "a3a":1,
                        "a3b":x,
                        "a3c":true
                    },
                    "a4":[1,2]
                },
                "b":[1,2],
                "c":true
            }
        )
        let str = JsonTool.toJson(d)
        println(str)
        let expect = ###"{"a":{"a1":1,"a2":"xyz","a3":{"a3a":1,"a3b":"xyz","a3c":true},"a4":[1,2]},"b":[1,2],"c":true}"###
        @Assert(str, expect)
    }

    @TestCase
    public func testToJsonSchema(): Unit {
        let schema = UserSchema.toJsonSchema()
        let json = JsonTool.toJson(schema)
        println(json)
        let expect = ###"{"type":"object","description":"user info","properties":{"name":{"type":"string","description":"the user name"},"address":{"type":"string","description":"the address of user"},"gender":{"type":"integer","description":"the user gender"},"addOnInfo":{"type":"object","description":"the user addon info","properties":{"info1":{"type":"string","description":"xxxx"}},"required":["info1"]},"f1":{"type":"string","description":"option desc"},"arr":{"type":"array","description":"arr desc","items":{"type":"string"}}},"required":["name","gender","addOnInfo","arr"]}"###
        @Assert(json, expect)
    }

    @TestCase
    public func testSuperClass(): Unit {
        let t = TextResourceContents(text: "1", text2: "2")
        t.mimeType = "text"
        
        let json = JsonTool.toJson(t)
        println(json)
        
        let r = JsonTool.fromJson<TextResourceContents>(json)
        @Assert(r.mimeType, t.mimeType)
        @Assert(r.text, t.text)
        @Assert(r.text2, t.text2)
    }

    @TestCase
    public func testSubTypes(): Unit {
        let t = TextResourceContents(text: "1", text2: "2")
        t.mimeType = "text"
        
        let json = JsonTool.toJson(t)
        println(json)
        
        let r = JsonTool.fromJson<ResourceContents>(json)
        @Assert(r.mimeType, t.mimeType)
        let r2 = (r as TextResourceContents).getOrThrow()
        @Assert(r2.text, t.text)
        @Assert(r2.text2, t.text2)
    }

    @TestCase
    public func testSubTypes2(): Unit {
        let t1 = TextResourceContents(text: "t1", text2: "t2")
        t1.mimeType = "text"
        let t2 = BlobResourceContents(blob: "b1", blob2: "b2")
        t2.mimeType = "blob"
        
        let s = ReadResourceResult(contents: ArrayList<ResourceContents>([t1, t2]))
        let json = JsonTool.toJson(s)
        println(json)
        
        let r = JsonTool.fromJson<ReadResourceResult>(json)
        @Assert(r.contents.size, 2)

        let r1 = (r.contents[0] as TextResourceContents).getOrThrow()
        @Assert(r1.mimeType, t1.mimeType)
        @Assert(r1.text, t1.text)
        @Assert(r1.text2, t1.text2)

        let r2 = (r.contents[1] as BlobResourceContents).getOrThrow()
        @Assert(r2.mimeType, t2.mimeType)
        @Assert(r2.blob, t2.blob)
        @Assert(r2.blob2, t2.blob2)
    }
}
