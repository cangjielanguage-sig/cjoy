/*
 * Copyright (c) lanlingx 2025-present. All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.test

import cjoy.*
import cjoy.json.*
import cjoy.macros.*
import std.deriving.*
import std.collection.*

// test not param
@Get[path = "/test1"]
func testGet1(): String {
    "helloword"
}

// test one param JoyContext
@Get[path = "/test2"]
func testGet2(c: JoyContext): String {
    c.setCtxParam("Test", 1)
    "helloword"
}

// test one param return tuple
@Get[path = "/test3"]
func testGet3(c: JoyContext): (UInt16, String) {
    c.setCtxParam("Test", 1)
    (200, "helloword")
}

// test one param return Unit
@Get[path = "/test4"]
func testGet4(ctx: JoyContext): Unit {
    ctx.setCtxParam("Test", 1)
    ctx.ok()
}

// test one param return NA
@Get[path = "/test5"]
func testGet5(ctx: JoyContext) {
    ctx.ok()
}

// test path param with no new name
@Get[path = "/path1/{name}"]
func pathGet1(@PathParam name: String): String {
    println(name)
    name
}

// test path param with a new name
@Get[path = "/path2/{p}"]
func pathGet2(@PathParam[name = p] a: String): String {
    println(a)
    a
}

// test path param with a new name type is ? 
@Get[path = "/path3/{p}"]
func pathGet3(@PathParam[name = p] a: ?String): String {
    println(a)
    a.getOrDefault({=> "p"})
}

// test path param with a new name type is Option 
@Get[path = "/path4/{p}"]
func pathGet4(@PathParam[name = p] a: Option<String>): String {
    println(a)
    a.getOrDefault({=> "p"})
}

// test path param with a new name type is convert to Int 
@Get[path = "/path5/{p}"]
func pathGet5(@PathParam[name = p] a: Int): String {
    println(a)
    a.toString()
}

// test path param with a new name type is convert to Int32 
@Get[path = "/path6/{p}"]
func pathGet6(@PathParam[name = p] a: Int32): String {
    println(a)
    a.toString()
}

// test path param return status code
@Get[path = "/path7/{p}"]
func pathGet7(@PathParam[name = p] a: Int32): UInt16 {
    println(a)
    200
}

// test path param return status code
@Get[path = "/path8/*"]
func pathGet8(@PathParam[name = *] remainPath: String): UInt16 {
    println(remainPath)
    200
}

// test path param with no new name
@Get[path = "/query1"]
func queryGet1(@QueryParam name: String): String {
    println(name)
    name
}

// test path param with a new name
@Get[path = "/query2"]
func queryGet2(@QueryParam[name = q1] name: String): String {
    println(name)
    name
}

// test path param with list type
@Get[path = "/query3"]
func queryGet3(@QueryParam[name = q1] name: ArrayList<String>): String {
    println(name)
    "list"
}

// test path param with array type
@Get[path = "/query4"]
func queryGet4(@QueryParam[name = q1] name: Array<String>): String {
    println(name)
    "array"
}

// test path param with defalut
@Get[path = "/query5"]
func queryGet5(@QueryParam[name = q1, default = "x"] name: String): String {
    println(name)
    name
}

// test path param with String type
@Post[path = "/postform1"]
func postfrom1(@PostFormParam[name = f1] name: String): String {
    println(name)
    name
}

// test path param with String type
@Post[path = "/context1"]
func ctxPost1(@ContextParam[name = c1] name: String): String {
    println(name)
    name
}

// test path param with Int type
@Post[path = "/context2"]
func ctxPost2(@ContextParam[name = c1] id: Int): String {
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
func ctxPost3(@ContextParam[name = c1] ctxParm: TestCtxParam): String {
    ctxParm.toString()
}

// test body param with string type
@Post[path = "/body1"]
func bodyPost1(@BodyParam body: String): String {
    body
}

@Json
@Derive[ToString]
class TestBody {
    var a: String = ""
    var b: Int = 0
}

// test body param with string type
@Post[path = "/body2"]
func bodyPost2(@BodyParam body: ?TestBody): String {
    body.getOrThrow().toString()
}

// test body param with json type
@Post[path = "/body3"]
func bodyPost3(@BodyParam body: Option<TestBody>): String {
    body.getOrThrow().toString()
}

// test body param with json type
@Post[path = "/body4"]
func bodyPost4(@BodyParam body: TestBody): String {
    body.toString()
}

// test body param with json type and return json
@Post[path = "/body5", produce = json]
func bodyPost5(@BodyParam body: TestBody): TestBody {
    body
}

// test body param with json type and return json
@Post[path = "/body6", produce = json]
func bodyPost6(@BodyParam body: TestBody): Array<TestBody> {
    [body]
}

// test body param with json type and return json
@Post[path = "/body7", produce = json]
func bodyPost7(@BodyParam body: TestBody): (UInt16, Array<TestBody>) {
    (200, [body])
}

// test header param
@Post[path = "/header1"]
func headerPost1(@HeaderParam[name = "X-Tokens", default = "xxx"] token: String): String {
    token
}

// test header param
@Post[path = "/header2"]
func headerPost2(@HeaderParam[name = "X-IDS"] ids: Array<String>): String {
    ids.toString()
}

// test header param
@Post[path = "/header3"]
func headerPost3(@HeaderParam[name = "X-Tokens"] token: ?String): String {
    token.getOrThrow().toString()
}

// test header param
@Post[path = "/cookie1", produce = json]
func cookiePost1(@CookieParam[name = "csrf-token"] token: ?String): String {
    token.getOrThrow().toString()
}

@Handler[path = "/cookie1", methods = "GET,POST"]
func testMethods(): String {
    "helloword"
}

@Middleware[groups = "/a/b/c,/a/c"]
func testMiddleware1(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
    chain.next(ctx)
}

@Middleware
func testMiddleware2(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
    chain.next(ctx)
}

@Test
public class MacroTestCaseSuit {
    @TestCase
    public func testAll() {
        let joy = Joy.default()
        JoyMiddlewares.registerTo(joy)
        JoyHandlers.registerTo(joy)
        let fut = spawn {
            joy.run("127.0.0.1", 18882)
        }
        sleep(Duration.second)
        fut.cancel()
    }
}
