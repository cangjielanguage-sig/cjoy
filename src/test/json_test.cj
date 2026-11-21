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
import std.math.numeric.{BigInt, Decimal}
import stdx.encoding.json.stream.JsonSerializable

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
public struct IsoTimeData {
    @JsonField[timeformat = "ISO8601"]
    var t: DateTime = DateTime.parse("2023-01-20T11:25:26+08:00")
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

@Json
public struct EmptyData {
    var arr: Array<Int32> = []
    var list: ArrayList<String> = ArrayList()
    var map: HashMap<String, Int64> = HashMap()
}

@Json
public struct NumericData {
    var bigInt: BigInt = BigInt.parse("12345678901234567890")
    var decimal: Decimal = Decimal.parse("12345.6789")
}

@Json
public struct RequiredData {
    var name: String = "test"
    @JsonField[required: false]
    var age: Option<Int32> = None
}

@Json
public struct CustomSchemaData {
    @JsonField[schema: {"type":"string","format":"email","description":"user email address"}]
    var email: String = "test@example.com"
}

@Test
public class JsonTestCaseSuit {
    /**
     * 测试基本 JSON 序列化和反序列化 - 验证基本数据类型和集合类型的 JSON 转换
     */
    @TestCase
    public func testBase() {
        let s0 = S0()
        let str = JsonTool.toJson(s0)
        println(str)

        let d = JsonTool.fromJson<S0>(str)
        @Assert(d.rune, r'x')
        @Assert(d.str, "str")
    }

    /**
     * 测试 JSON 字段忽略 - 验证 @JsonField[ignore = true] 注解的功能
     */
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

    /**
     * 测试 JSON 字段重命名 - 验证 @JsonField[name = ...] 注解的功能
     */
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

    /**
     * 测试 JSON 字段忽略空值 - 验证 @JsonField[omitempty = true] 注解的功能
     */
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

    /**
     * 测试 JSON 空值处理 - 验证 null 值的序列化和反序列化
     */
    @TestCase
    public func testNull(): Unit {
        let s = SDataNull()
        let str = JsonTool.toJson(s)
        println(str)
        let json = ###"{"a":null}"###
        @Assert(str, json)
    }

    /**
     * 测试日期时间格式化 - 验证 @JsonField[timeformat = ...] 注解的功能
     */
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

    /**
     * 测试类 JSON 序列化 - 验证类类型的 JSON 序列化和反序列化
     */
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

    /**
     * 测试嵌套对象 JSON 序列化 - 验证包含嵌套对象的复杂结构的 JSON 转换
     */
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

    /**
     * 测试多余字段处理1 - 验证 JSON 中包含多余字段时的反序列化
     */
    @TestCase
    public func testExcessField1(): Unit {
        let json = ###"{"width": 1, "height": 2, "others": "xxx"}"###
        let dc = JsonTool.fromJson<DataClass>(json)
        @Assert(dc.width, 1)
        @Assert(dc.height, 2)
    }

    /**
     * 测试多余字段处理2 - 验证 JSON 中包含嵌套多余字段时的反序列化
     */
    @TestCase
    public func testExcessField2(): Unit {
        let json = ###"{"width": 1, "height": 2, "others": {"k1": 1, "k2": "v2"}}"###
        let dc = JsonTool.fromJson<DataClass>(json)
        @Assert(dc.width, 1)
        @Assert(dc.height, 2)
    }

    /**
     * 测试多余字段处理3 - 验证 JSON 中包含 null 值多余字段时的反序列化
     */
    @TestCase
    public func testExcessField3(): Unit {
        let json = ###"{"width": 1, "height": 2, "others": null}"###
        let dc = JsonTool.fromJson<DataClass>(json)
        @Assert(dc.width, 1)
        @Assert(dc.height, 2)
    }

    /**
     * 测试 JSON 到 Any 类型转换1 - 验证将 JSON 字符串反序列化为 Any 类型的功能
     */
    @TestCase
    public func testToAny1(): Unit {
        let str = ###"{"a": 1, "b": 2, "c": {"c1": "c1v", "c2": 1.1}, "d":[{"d1": true, "d2": null},{"d1": false, "d2": "d2v"}]}"###
        let ts = JsonTool.fromJsonToSerializable(str)
        match (ts) {
            case m: HashMap<String, JsonSerializable> => @Assert(4, m.size )
            case _ => @Fail("deserialize failed")
        }
    }

    /**
     * 测试 JSON 到 Any 类型转换2 - 验证将 JSON 字符串反序列化为包含 Any 类型字段的结构体
     */
    @TestCase
    public func testToAny2(): Unit {
        let str = ###"{"a": 1, "b": 2, "c": {"c1": "c1v", "c2": 1.1}, "d":[{"d1": true, "d2": null},{"d1": false, "d2": "d2v"}]}"###
        let dc = JsonTool.fromJson<DataAny>(str)
        @Assert((dc.a as Int64).getOrThrow(), 1)
        @Assert((dc.b as Int64).getOrThrow(), 2)
    }

    /**
     * 测试 JSON 到 Any 类型转换3 - 验证将 JSON 字符串反序列化为包含原始 JSON 数据的字段
     */
    @TestCase
    public func testToAny3(): Unit {
        let str = ###"{"a": 1, "b": 2, "c": {"c1": "c1v", "c2": 1.1}, "d":[{"d1": true, "d2": null},{"d1": false, "d2": "d2v"}]}"###
        let dc = JsonTool.fromJson<DataAny2>(str)
        let c = String.fromUtf8((dc.c as Array<Byte>).getOrThrow())
        @Assert(c, ###"{"c1": "c1v", "c2": 1.1}"###)
    }

    /**
     * 测试 Any 类型到 JSON 转换 - 验证包含 Any 类型字段的对象的 JSON 序列化
     */
    @TestCase
    public func testAnyToJson(): Unit {
        var dc = DataAny()
        dc.c = HashMap<String, String>([("c1", "v1"), ("c2", "v2")])
        let str = JsonTool.toJson(dc)
        let expect = ###"{"a":1,"b":2,"c":{"c1":"v1","c2":"v2"}}"###
        @Assert(str, expect)
    }

    /**
     * 测试简单对象到 JSON 转换 - 验证使用 @ToJson 宏创建简单对象的 JSON 序列化
     */
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

    /**
     * 测试带变量的简单对象到 JSON 转换1 - 验证使用字符串插值的 @ToJson 宏
     */
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

    /**
     * 测试带变量的简单对象到 JSON 转换2 - 验证使用直接变量引用的 @ToJson 宏
     */
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

    /**
     * 测试简单数组到 JSON 转换 - 验证使用 @ToJson 宏创建简单数组的 JSON 序列化
     */
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

    /**
     * 测试复杂结构到 JSON 转换 - 验证使用 @ToJson 宏创建包含嵌套对象和数组的复杂结构的 JSON 序列化
     */
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

    /**
     * 测试 JSON 模式生成 - 验证类和结构体到 JSON 模式的转换功能
     */
    @TestCase
    public func testToJsonSchema(): Unit {
        let schema = UserSchema.toJsonSchema()
        let json = JsonTool.toJson(schema)
        println(json)
        let expect = ###"{"type":"object","description":"user info","properties":{"name":{"type":"string","description":"the user name"},"address":{"type":"string","description":"the address of user"},"gender":{"type":"integer","description":"the user gender"},"addOnInfo":{"type":"object","description":"the user addon info","properties":{"info1":{"type":"string","description":"xxxx"}},"required":["info1"]},"f1":{"type":"string","description":"option desc"},"arr":{"type":"array","description":"arr desc","items":{"type":"string"}}},"required":["name","gender","addOnInfo","arr"]}"###
        @Assert(json, expect)
    }

    /**
     * 测试继承类 JSON 序列化 - 验证继承类的 JSON 序列化和反序列化功能
     */
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

    /**
     * 测试子类型 JSON 序列化 - 验证基于子类型字段的 JSON 序列化和反序列化功能
     */
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

    /**
     * 测试子类型 JSON 序列化2 - 验证包含多个子类型对象的集合的 JSON 序列化和反序列化功能
     */
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

    /**
     * 测试格式化输出 - 验证带有缩进的 JSON 格式化输出功能
     */
    @TestCase
    public func testIndentOutput(): Unit {
        let s0 = S0()
        let str = JsonTool.toJson(s0, indent: true)
        println(str)
        @Assert(str.contains("\t"), true)
        @Assert(str.contains("\n"), true)
    }

    /**
     * 测试空集合 JSON 序列化 - 验证空数组和空对象的 JSON 序列化功能
     */
    @TestCase
    public func testEmptyCollections(): Unit {
        let data = EmptyData()
        let str = JsonTool.toJson(data)
        println(str)
        let expect = #"{"arr":[],"list":[],"map":{}}"#
        @Assert(str, expect)

        let d = JsonTool.fromJson<EmptyData>(str)
        @Assert(d.arr.size, 0)
        @Assert(d.list.size, 0)
        @Assert(d.map.size, 0)
    }

    /**
     * 测试 BigInt 和 Decimal 类型 JSON 序列化 - 验证大整数和高精度小数的 JSON 转换功能
     */
    @TestCase
    public func testBigIntDecimal(): Unit {
        let data = NumericData()
        let str = JsonTool.toJson(data)
        println(str)

        let d = JsonTool.fromJson<NumericData>(str)
        @Assert(d.bigInt.toString(), "12345678901234567890")
        @Assert(d.decimal.toString(), "12345.6789")
    }

    /**
     * 测试从字节数组反序列化 - 验证从字节数组中读取 JSON 数据的反序列化功能
     */
    @TestCase
    public func testFromJsonBytes(): Unit {
        let s0 = S0()
        let bytes = JsonTool.toJsonBytes(s0)
        let d = JsonTool.fromJson<S0>(bytes)
        @Assert(d.rune, r'x')
        @Assert(d.str, "str")
    }

    /**
     * 测试 JSON 到 Any 类型转换 - 验证将 JSON 直接反序列化为 Any 类型的功能
     */
    @TestCase
    public func testFromJsonToAny(): Unit {
        let str = ###"{"a": 1, "b": "test", "c": true, "d": 1.5, "e": null, "f": [1, 2, "3"], "g": {"k1": "v1", "k2": 42}}"###
        let buffer = ByteBuffer()
        unsafe { buffer.write(str.rawData())}
        let obj = JsonTool.fromJsonToAny(JsonReader(buffer))

        match (obj) {
            case map: HashMap<String, Any> =>
                @Assert(map.size, 7)
                @Assert((map["a"] as Int64).getOrThrow(), 1)
                @Assert((map["b"] as String).getOrThrow(), "test")
                @Assert((map["c"] as Bool).getOrThrow(), true)
                @Assert((map["d"] as Float64).getOrThrow(), 1.5)
                @Assert((map["e"] as Option<String>).getOrThrow(), None)

                match (map["f"]) {
                    case list: ArrayList<Any> =>
                        @Assert(list.size, 3)
                        @Assert((list[0] as Int64).getOrThrow(), 1)
                        @Assert((list[1] as Int64).getOrThrow(), 2)
                        @Assert((list[2] as String).getOrThrow(), "3")
                    case _ => @Fail("f should be array")
                }

                match (map["g"]) {
                    case subMap: HashMap<String, Any> =>
                        @Assert(subMap.size, 2)
                        @Assert((subMap["k1"] as String).getOrThrow(), "v1")
                        @Assert((subMap["k2"] as Int64).getOrThrow(), 42)
                    case _ => @Fail("g should be object")
                }
            case _ => @Fail("should be object")
        }
    }

    /**
     * 测试 Rune 类型读取 - 验证从 JSON 中读取 Rune 类型的功能
     */
    @TestCase
    public func testReadRune(): Unit {
        let json = ###"{"rune":"x"}"###
        var stream = ByteBuffer()
        unsafe { stream.write(json.rawData())}
        let reader = JsonReader(stream)
        reader.startObject()
        let name = reader.readName()
        @Assert(name, "rune")
        let rune = JsonTool.readRune(reader)
        @Assert(rune, r'x')
        reader.endObject()
    }

    /**
     * 测试必填字段验证 - 验证 JSON 模式生成中必填字段的处理
     */
    @TestCase
    public func testRequiredField(): Unit {
        let schema = RequiredData.toJsonSchema()
        let schemaStr = JsonTool.toJson(schema)
        println(schemaStr)

        @Assert(schemaStr.contains("\"required\":[\"name\"]"), true)
    }

    /**
     * 测试自定义模式 - 验证自定义 JSON 模式生成功能
     */
    @TestCase
    public func testCustomSchema(): Unit {
        let schema = CustomSchemaData.toJsonSchema()
        let schemaStr = JsonTool.toJson(schema)
        println(schemaStr)

        @Assert(schemaStr.contains("\"format\":\"email\""), true)
        @Assert(schemaStr.contains("\"description\":\"user email address\""), true)
    }

    /**
     * 测试指数形式数字 - 验证 1e3 等 JSON 数字被解析为 Float64
     */
    @TestCase
    public func testExponentNumbers(): Unit {
        let str = ###"{"a":1e3,"b":1E-2,"c":-2.5e2}"###
        let buffer = ByteBuffer()
        unsafe { buffer.write(str.rawData()) }
        let any = JsonTool.fromJsonToAny(JsonReader(buffer))
        match (any) {
            case map: HashMap<String, Any> =>
                @Assert((map.get("a").getOrThrow() as Float64).getOrThrow(), 1000.0)
                @Assert((map.get("b").getOrThrow() as Float64).getOrThrow(), 0.01)
                @Assert((map.get("c").getOrThrow() as Float64).getOrThrow(), -250.0)
            case _ => @Fail("should be object")
        }

        let serializable = JsonTool.fromJsonToSerializable(str)
        match (serializable) {
            case smap: HashMap<String, JsonSerializable> =>
                @Assert((smap.get("a").getOrThrow() as Float64).getOrThrow(), 1000.0)
            case _ => @Fail("should be object")
        }
    }

    /**
     * 测试多字节 Rune 读取 - 验证非 ASCII 字符不会被按 UTF-8 首字节截断
     */
    @TestCase
    public func testReadMultibyteRune(): Unit {
        let json = ###"{"rune":"你"}"###
        let stream = ByteBuffer()
        unsafe { stream.write(json.rawData()) }
        let reader = JsonReader(stream)
        reader.startObject()
        reader.readName()
        @Assert(JsonTool.readRune(reader), r'你')
        reader.endObject()
    }

    /**
     * 测试超大整数 - 验证超出 Int64 的 JSON 整数用 BigInt 表示
     */
    @TestCase
    public func testBigIntegerFallback(): Unit {
        let str = ###"{"n":99999999999999999999999999}"###
        let buffer = ByteBuffer()
        unsafe { buffer.write(str.rawData()) }
        let any = JsonTool.fromJsonToAny(JsonReader(buffer))
        match (any) {
            case map: HashMap<String, Any> =>
                let value = map.get("n").getOrThrow() as BigInt
                @Assert(value.getOrThrow().toString(), "99999999999999999999999999")
            case _ => @Fail("should be object")
        }
    }

    /**
     * 测试 ISO8601 时间格式 - 验证该别名不会被当作仓颉格式串处理
     */
    @TestCase
    public func testIso8601TimeFormat(): Unit {
        let data = IsoTimeData()
        let json = JsonTool.toJson(data)
        @Assert(json.contains("2023-01-20T11:25:26"), true)
        let parsed = JsonTool.fromJson<IsoTimeData>(json)
        @Assert(parsed.t.toUnixTimeStamp().toSeconds(), data.t.toUnixTimeStamp().toSeconds())
    }

    /**
     * 测试 BigInt/Decimal 的 schema 类型 - 验证它们作为 JSON number 描述
     */
    @TestCase
    public func testNumericSchemaTypes(): Unit {
        @Assert(JsonTool.toJson(JsonTool.getSchema<BigInt>().toJson()).contains("number"), true)
        @Assert(JsonTool.toJson(JsonTool.getSchema<Decimal>().toJson()).contains("number"), true)
    }
}
