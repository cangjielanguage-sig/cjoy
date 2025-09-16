/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.test

import cjoy.bind.*
import std.collection.*
import std.time.*
import stdx.net.http.*
import stdx.encoding.url.URL
import std.unittest.testmacro.*

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
}
