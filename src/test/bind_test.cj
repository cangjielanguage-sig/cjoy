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

import cjoy.bind.*
import cjoy.macros.*
import std.collection.*
import std.time.*
import stdx.net.http.*
import stdx.encoding.url.URL

@Bind
public struct SQueryBind {
    let str: String // 虽IDE飘红，但let变量会在生成的构造方法进行初始化而无问题
    let str2: ?String
    let i64: Int64

    @BindField[name = int]
    let i2_64: Int

    let i3_64: ?Int
    let arr: Array<String>
    let list: ArrayList<String>
}

@Bind
public struct SQueryBind2 {
    let str: String
    let str2: ?String
    let i64: Int64

    @BindField[name = int]
    let i2_64: Int

    let i3_64: ?Int
    let arr: Array<Int>
    let list: ArrayList<Int>
}

@Bind
public struct SPostBind {
    var str: String = ""
    var str2: ?String = None
    var i64: Int64 = 0

    @BindField[name = int]
    var i2_64: Int = 0

    var i3_64: ?Int = None
    var arr: Array<String> = []
    var list: ArrayList<String> = ArrayList<String>()
}

@Bind
public struct SHeaderBind {
    @BindField[name = hstr1]
    var str: String = ""

    @BindField[name = hstr2]
    var str2: ?String = None

    @BindField[name = hint1]
    var i64: Int64 = 0

    @BindField[name = hint2]
    var i2_64: Int = 0

    @BindField[name = hint3]
    var i3_64: ?Int = None

    @BindField[name = harr]
    var arr: Array<String> = []

    @BindField[name = hlist]
    var list: ArrayList<String> = ArrayList<String>()

    @BindField[name = "htime1", timeformat = "HH:mm:ss MM/dd/yyyy OO"]
    let t1: DateTime

    @BindField[name = "htime2", timeformat = "HH:mm:ss MM/dd/yyyy OO"]
    let t2: ?DateTime
}

@Bind
public class Bind1 {
    var str: String = ""
    let bind2: Bind2
}

@Bind
public class Bind2 {
    var str: String = ""
    let bind3: ?Bind3
}

@Bind
public class Bind3 {
    var str: String = ""
}

@Bind
public struct SDefaultValueBind {
    @BindField[name = "required_field"]
    var requiredField: String = ""

    @BindField[name = "optional_field"]
    var optionalField: ?String = None

    @BindField[name = "int_field"]
    var intField: Int = 0

    @BindField[name = "default_str"]
    var defaultStr: String = "default_value"

    @BindField[name = "default_int"]
    var defaultInt: Int = 100
}

@Bind
public struct SNumericTypesBind {
    var int8: Int8 = 0
    var int16: Int16 = 0
    var int32: Int32 = 0
    var int64: Int64 = 0
    var uint8: UInt8 = 0
    var uint16: UInt16 = 0
    var uint32: UInt32 = 0
    var uint64: UInt64 = 0
    var float16: Float16 = 0.0
    var float32: Float32 = 0.0
    var float64: Float64 = 0.0
}

@Bind
public struct SBooleanBind {
    var boolValue: Bool = false
    var optionalBool: ?Bool = None
}

@Bind
public struct SDateTimeBind {
    var date: ?DateTime = None
    var optionalDate: ?DateTime = None

    @BindField[name = "custom_date", timeformat = "yyyy-MM-dd HH:mm:ss"]
    var customFormatDate: ?DateTime = None
}

@Bind
public class ComplexNestedBind {
    var name: String = ""
    var value: Float64 = 0.0
    var details: ?ComplexDetailsBind = None
}

@Bind
public class ComplexDetailsBind {
    var description: String = ""
    var tags: Array<String> = []
}

@Test
public class BindTestCaseSuit {
    @TestCase
    public func testQueryBind() {
        let u = "http://127.0.0.1:18881/test?str=1&str2=2&i64=1&int=2&i3_64=3&arr=1&arr=2&list=1&list=2"
        let r = HttpRequestBuilder().get().url(URL.parse(u)).build()
        let obj = SQueryBind.bind(r.url.queryForm, "", None, None).getOrThrow()
        @Assert(obj.str, "1")
        @Assert(obj.str2, "2")
        @Assert(obj.i64, 1)
        @Assert(obj.i2_64, 2)
        @Assert(obj.i3_64, 3)
        @Assert(obj.arr, ["1", "2"])
        @Assert(obj.list, ArrayList(["1", "2"]))
    }

    @TestCase
    public func testQueryBind2() {
        let u = "http://127.0.0.1:18881/test?str=1&str2=2&i64=1&int=2&i3_64=3&arr=1&arr=2&list=1&list=2"
        let r = HttpRequestBuilder().get().url(URL.parse(u)).build()
        let obj = SQueryBind2.bind(r.url.queryForm, "", None, None).getOrThrow()
        @Assert(obj.str, "1")
        @Assert(obj.str2, "2")
        @Assert(obj.i64, 1)
        @Assert(obj.i2_64, 2)
        @Assert(obj.i3_64, 3)
        @Assert(obj.arr, [1, 2])
        @Assert(obj.list, ArrayList([1, 2]))
    }

    @TestCase
    public func testPostFormBind() {
        let r = HttpRequestBuilder()
            .post()
            .url("http://127.0.0.1:18881/test")
            .body("str=1&str2=2&i64=1&int=2&i3_64=3&arr=1&arr=2&list=1&list=2")
            .header("Content-Type", "application/x-www-form-urlencoded")
            .build()
        let obj = SPostBind.bind(r.form, "", None, None).getOrThrow()
        @Assert(obj.str, "1")
        @Assert(obj.str2, "2")
        @Assert(obj.i64, 1)
        @Assert(obj.i2_64, 2)
        @Assert(obj.i3_64, 3)
        @Assert(obj.arr, ["1", "2"])
        @Assert(obj.list, ArrayList(["1", "2"]))
    }

    @TestCase
    public func testHeaderBind() {
        let ts = DateTime.now().format("HH:mm:ss MM/dd/yyyy OO")
        let u = "http://127.0.0.1:18881/test"
        let r = HttpRequestBuilder()
            .get()
            .url(URL.parse(u))
            .header("hstr1", "1")
            .header("hstr2", "2")
            .header("hint1", "1")
            .header("hint2", "2")
            .header("hint3", "3")
            .header("harr", "1")
            .header("harr", "2")
            .header("hlist", "1")
            .header("hlist", "2")
            .header("htime1", ts)
            .header("htime2", ts)
            .build()
        let obj = SHeaderBind.bind(r.headers, "", None, None).getOrThrow()
        @Assert(obj.str, "1")
        @Assert(obj.str2, "2")
        @Assert(obj.i64, 1)
        @Assert(obj.i2_64, 2)
        @Assert(obj.i3_64, 3)
        @Assert(obj.arr, ["1", "2"])
        @Assert(obj.list, ArrayList(["1", "2"]))
        @Assert(obj.t1, DateTime.parse(ts, "HH:mm:ss MM/dd/yyyy OO"))
        @Assert(obj.t2, DateTime.parse(ts, "HH:mm:ss MM/dd/yyyy OO"))
    }

    @TestCase
    public func testNestedBind() {
        let map1 = HashMap<String, Any>()
        let map2 = HashMap<String, Any>()
        let map3 = HashMap<String, Any>()
        map1.add("str", "1")
        map1.add("bind2", map2)
        map2.add("str", "2")
        map2.add("bind3", map3)
        map3.add("str", "3")
        let container = MapContainer(map1)
        let obj = Bind1.bind(container, "").getOrThrow()
        @Assert(obj.str, "1")
        @Assert(obj.bind2.str, "2")
        @Assert(obj.bind2.bind3?.str ?? "", "3")
    }

    @TestCase
    public func testIntBind() {
        let map1 = HashMap<String, Any>()
        map1.add("A", 1)
        let container = MapContainer(map1)
        let arr = Int.bind(container, "A").getOrThrow()
        @Assert(arr, 1)
    }

    @TestCase
    public func testArrayBind() {
        let map1 = HashMap<String, Any>()
        map1.add("A", [1, 2])
        let container = MapContainer(map1)
        // 调用4个参数的bind方法
        let arr = Array<Int>.bind(container, "A", None, None).getOrThrow()
        @Assert(arr, [1, 2])
    }

    @TestCase
    public func testArrayBind2Param() {
        let map1 = HashMap<String, Any>()
        map1.add("A", [1, 2])
        let container = MapContainer(map1)
        // 调用两个参数的bind方法
        let arr = Array<Int>.bind(container, "A").getOrThrow()
        @Assert(arr, [1, 2])
    }

    @TestCase
    public func testArrayBind2() {
        let map1 = HashMap<String, Any>()
        map1.add("A", ArrayList<Any>([1, 2]))
        let container = MapContainer(map1)
        let arr = Array<Int>.bind(container, "A", None, None).getOrThrow()
        @Assert(arr, [1, 2])
    }

    @TestCase
    public func testArrayBind3() {
        let map1 = HashMap<String, Any>()
        map1.add("", [1, 2])
        let container = MapContainer(map1)
        let arr = Array<Int>.bind(container, "", None, None).getOrThrow()
        @Assert(arr, [1, 2])
    }

    @TestCase
    public func testArrayListBind() {
        let map1 = HashMap<String, Any>()
        map1.add("A", [1, 2])
        let container = MapContainer(map1)
        let arr = ArrayList<Int>.bind(container, "A", None, None).getOrThrow()
        @Assert(arr.toArray(), [1, 2])
    }

    @TestCase
    public func testArrayListBind2() {
        let map1 = HashMap<String, Any>()
        map1.add("A", ArrayList<Any>([1, 2]))
        let container = MapContainer(map1)
        let arr = ArrayList<Int>.bind(container, "A", None, None).getOrThrow()
        @Assert(arr.toArray(), [1, 2])
    }

    @TestCase
    public func testDefaultValueBind() {
        let map1 = HashMap<String, Any>()
        map1.add("required_field", "test_value")
        map1.add("int_field", 42)
        let container = MapContainer(map1)
        let obj = SDefaultValueBind.bind(container, "").getOrThrow()

        @Assert(obj.requiredField, "test_value")
        @Assert(obj.intField, 42)
        @Assert(obj.defaultStr, "default_value")
        @Assert(obj.defaultInt, 100)
        @Assert(obj.optionalField, None)
    }

    @TestCase
    public func testNumericTypesBind() {
        let map1 = HashMap<String, Any>()
        map1.add("int8", 10)
        map1.add("int16", 1000)
        map1.add("int32", 100000)
        map1.add("int64", 1000000000)
        map1.add("uint8", 200)
        map1.add("uint16", 50000)
        map1.add("uint32", 4000000000)
        map1.add("uint64", 18446744073709551615u64)
        map1.add("float16", 1.5)
        map1.add("float32", 3.14)
        map1.add("float64", 2.71828)
        let container = MapContainer(map1)
        let obj = SNumericTypesBind.bind(container, "").getOrThrow()

        @Assert(obj.int8, 10)
        @Assert(obj.int16, 1000)
        @Assert(obj.int32, 100000)
        @Assert(obj.int64, 1000000000)
        @Assert(obj.uint8, 200)
        @Assert(obj.uint16, 50000)
        @Assert(obj.uint32, 4000000000)
        @Assert(obj.uint64, 18446744073709551615)
        @Assert(obj.float16, 1.5)
        @Assert(obj.float32, 3.14)
        @Assert(obj.float64, 2.71828)
    }

    @TestCase
    public func testBooleanBind() {
        let map1 = HashMap<String, Any>()
        map1.add("boolValue", true)
        map1.add("optionalBool", "true")
        let container = MapContainer(map1)
        let obj = SBooleanBind.bind(container, "").getOrThrow()

        @Assert(obj.boolValue, true)
        @Assert(obj.optionalBool, true)
    }

    @TestCase
    public func testDateTimeBind() {
        let now = DateTime.now()
        let customDateStr = "2023-12-25 18:30:45"
        let customDate = DateTime.parse(customDateStr, "yyyy-MM-dd HH:mm:ss")

        let map1 = HashMap<String, Any>()
        map1.add("custom_date", customDateStr)
        let container = MapContainer(map1)
        let obj = SDateTimeBind.bind(container, "").getOrThrow()

        @Assert(obj.customFormatDate, customDate)
        @Assert(obj.optionalDate, None)
    }

    @TestCase
    public func testComplexNestedBind() {
        let map1 = HashMap<String, Any>()
        let detailsMap = HashMap<String, Any>()

        detailsMap.add("description", "test description")
        detailsMap.add("tags", ["tag1", "tag2"])

        map1.add("name", "test name")
        map1.add("value", 1.23)
        map1.add("details", detailsMap)

        let container = MapContainer(map1)
        let obj = ComplexNestedBind.bind(container, "").getOrThrow()

        @Assert(obj.name, "test name")
        @Assert(obj.value, 1.23)
        @Assert(obj.details?.description, "test description")
        @Assert(obj.details?.tags, ["tag1", "tag2"])
    }

    @TestCase
    public func testBindFailure() {
        let map1 = HashMap<String, Any>()
        let container = MapContainer(map1)

        // 测试必填字段缺失
        let result1 = SQueryBind.bind(container, "").isSome()
        @Assert(result1, true)

        // 测试类型不匹配
        let map2 = HashMap<String, Any>()
        map2.add("str", "test")
        map2.add("str2", "test2")
        map2.add("i64", "not_number")
        map2.add("int", 2)
        map2.add("i3_64", 3)
        map2.add("arr", ["1", "2"])
        map2.add("list", ["1", "2"])
        let container2 = MapContainer(map2)

        let result2 = SQueryBind.bind(container2, "").isSome()
        @Assert(result2, true)
    }

    @TestCase
    public func testBindFieldMethod() {
        let map1 = HashMap<String, Any>()
        let nestedMap = HashMap<String, Any>()
        nestedMap.add("str", "nested_str")
        nestedMap.add("int", 42)
        nestedMap.add("arr", ["a", "b"])
        map1.add("nested_field", nestedMap)
        let container = MapContainer(map1)

        let result = SQueryBind.bindField(container, "nested_field").getOrThrow()
        @Assert(result.str, "nested_str")
        @Assert(result.i2_64, 42)
        @Assert(result.arr, ["a", "b"])
    }

    @TestCase
    public func testBoolStringBinding() {
        let map1 = HashMap<String, Any>()
        map1.add("boolValue", "true")
        map1.add("optionalBool", "false")
        let container = MapContainer(map1)
        let obj = SBooleanBind.bind(container, "").getOrThrow()

        @Assert(obj.boolValue, true)
        @Assert(obj.optionalBool, false)
    }
}
