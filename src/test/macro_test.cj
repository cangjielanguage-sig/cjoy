/*
 * Copyright (c) lanlingx 2025-present. All rights resvered.
 */

package cjoy.test

import cjoy.*
import cjoy.macros.*
import std.collection.*

@Get[path="/test1"]
func TestHandler1(): String {
    "helloword"
}

@Get[path="/test2"]
func TestHandler2(c: JoyContext): String {
    c.setCtxParam("Test", 1)
    "helloword"
}

@Get[path="/test3"]
func TestHandler3(c: JoyContext): (UInt16, String) {
    c.setCtxParam("Test", 1)
    (200, "helloword")
}

@Get[path="/test4"]
func TestHandler4(ctx: JoyContext): Unit {
    ctx.setCtxParam("Test", 1)
    ctx.ok()
}

@Get[path="/test5"]
func TestHandler5(ctx: JoyContext) {
    ctx.ok()
}

@Get[path="/path1/{name}"]
func pathGetHandler1(@PathParam name: String): String {
    println(name)
    name
}

@Get[path="/path2/{p}"]
func pathGetHandler2(@PathParam[name=p] a: String): String {
    println(a)
    a
}

@Get[path="/path3/{p}"]
func pathGetHandler3(@PathParam[name=p] a: ?String): String {
    println(a)
    a.getOrDefault({=>"p"})
}

@Get[path="/path4/{p}"]
func pathGetHandler4(@PathParam[name=p] a: Int): String {
    println(a)
    a.toString()
}


