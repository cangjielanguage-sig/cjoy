/*
 * Copyright (c) lanlingx 2025-present. All rights resvered.
 */

package cjoy.test

import cjoy.*
import cjoy.macros.*
import std.collection.*

// test not param
@Get[path = "/test1"]
func TestHandler1(): String {
    "helloword"
}

// test one param JoyContext
@Get[path = "/test2"]
func TestHandler2(c: JoyContext): String {
    c.setCtxParam("Test", 1)
    "helloword"
}

// test one param return tuple
@Get[path = "/test3"]
func TestHandler3(c: JoyContext): (UInt16, String) {
    c.setCtxParam("Test", 1)
    (200, "helloword")
}

// test one param return Unit
@Get[path = "/test4"]
func TestHandler4(ctx: JoyContext): Unit {
    ctx.setCtxParam("Test", 1)
    ctx.ok()
}

// test one param return NA
@Get[path = "/test5"]
func TestHandler5(ctx: JoyContext) {
    ctx.ok()
}

// test path param with no new name
@Get[path = "/path1/{name}"]
func pathGetHandler1(@PathParam name: String): String {
    println(name)
    name
}

// test path param with a new name
@Get[path = "/path2/{p}"]
func pathGetHandler2(@PathParam[name = p] a: String): String {
    println(a)
    a
}

// test path param with a new name type is ? 
@Get[path = "/path3/{p}"]
func pathGetHandler3(@PathParam[name = p] a: ?String): String {
    println(a)
    a.getOrDefault({=> "p"})
}

// test path param with a new name type is Option 
@Get[path = "/path4/{p}"]
func pathGetHandler4(@PathParam[name = p] a: Option<String>): String {
    println(a)
    a.getOrDefault({=> "p"})
}

// test path param with a new name type is convert to Int 
@Get[path = "/path5/{p}"]
func pathGetHandler5(@PathParam[name = p] a: Int): String {
    println(a)
    a.toString()
}

// test path param with a new name type is convert to Int32 
@Get[path = "/path6/{p}"]
func pathGetHandler6(@PathParam[name = p] a: Int32): String {
    println(a)
    a.toString()
}

// test path param with no new name
@Get[path = "/query1"]
func queryGetHandler1(@QueryParam name: String): String {
    println(name)
    name
}

// test path param with a new name
@Get[path = "/query2"]
func queryGetHandler2(@QueryParam[name = q1] name: String): String {
    println(name)
    name
}

// test path param with list type
@Get[path = "/query3"]
func queryGetHandler3(@QueryParam[name = q1] name: ArrayList<String>): String {
    println(name)
    "list"
}

// test path param with array type
@Get[path = "/query4"]
func queryGetHandler4(@QueryParam[name = q1] name: Array<String>): String {
    println(name)
    "array"
}

// test path param with defalut
@Get[path = "/query5"]
func queryGetHandler5(@QueryParam[name = q1, default = "x"] name: String): String {
    println(name)
    name
}

// test path param with String type
@Post[path = "/postform1"]
func postfromHandler1(@PostFormParam[name = f1] name: String): String {
    println(name)
    name
}

// test path param with String type
@Post[path = "/context1"]
func ctxPostHandler1(@ContextParam[name = c1] name: String): String {
    println(name)
    name
}

// test path param with Int type
@Post[path = "/context2"]
func ctxPostHandler2(@ContextParam[name = c1] id: Int): String {
    println(id)
    id.toString()
}

class TestCtxParam <: ToString {
    public func toString() {
        "TestCtxParam"
    }
}

// test path param with Int type
@Post[path = "/context3"]
func ctxPostHandler3(@ContextParam[name = c1] ctxParm: TestCtxParam): String {
    ctxParm.toString()
}

@Test
public class MacroTestCaseSuit {
    @TestCase
    public func testAll() {
    }
}
