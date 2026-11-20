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

import cjoy.*
import cjoy.json.*
import cjoy.macros.*
import cjoy.bind.*
import cjoy.httpx.*
import cjoy.context.*
import std.deriving.*
import std.collection.*
import std.time.*

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

// test path param with no new name (named parameter)
@Get[path = "/path1_named/{name}"]
func pathGet1Named(@PathParam name!: String = "defstr"): String {
    println(name)
    name
}

// test path param with a new name
@Get[path = "/path2/{p}"]
func pathGet2(@PathParam[name = p] a: String): String {
    println(a)
    a
}

// test path param with a new name (named parameter)
@Get[path = "/path2_named/{p}"]
func pathGet2Named(@PathParam[name = p] a!: String = "defstr"): String {
    println(a)
    a
}

// test path param with a new name type is ?
@Get[path = "/path3/{p}"]
func pathGet3(@PathParam[name = p] a: ?String): String {
    println(a)
    a ?? "p"
}

// test path param with a new name type is ? (named parameter)
@Get[path = "/path3_named/{p}"]
func pathGet3Named(@PathParam[name = p] a!: ?String = "defstr"): String {
    println(a)
    a ?? "p"
}

// test path param with a new name type is Option
@Get[path = "/path4/{p}"]
func pathGet4(@PathParam[name = p] a: Option<String>): String {
    println(a)
    a ?? "p"
}

// test path param with a new name type is Option (named parameter)
@Get[path = "/path4_named/{p}"]
func pathGet4Named(@PathParam[name = p] a!: Option<String> = Some("defstr")): String {
    println(a)
    a ?? "p"
}

// test path param with a new name type is convert to Int
@Get[path = "/path5/{p}"]
func pathGet5(@PathParam[name = p] a: Int): String {
    println(a)
    a.toString()
}

// test path param with a new name type is convert to Int (named parameter)
@Get[path = "/path5_named/{p}"]
func pathGet5Named(@PathParam[name = p] a!: Int = 100): String {
    println(a)
    a.toString()
}

// test path param with a new name type is convert to Int32
@Get[path = "/path6/{p}"]
func pathGet6(@PathParam[name = p] a: Int32): String {
    println(a)
    a.toString()
}

// test path param with a new name type is convert to Int32 (named parameter)
@Get[path = "/path6_named/{p}"]
func pathGet6Named(@PathParam[name = p] a!: Int32 = 200): String {
    println(a)
    a.toString()
}

// test path param return status code
@Get[path = "/path7/{p}"]
func pathGet7(@PathParam[name = p] a: Int32): UInt16 {
    println(a)
    200
}

// test path param return status code (named parameter)
@Get[path = "/path7_named/{p}"]
func pathGet7Named(@PathParam[name = p] a!: Int32 = 300): UInt16 {
    println(a)
    200
}

// test path param return status code
@Get[path = "/path8/*"]
func pathGet8(@PathParam[name = *] remainPath: String): UInt16 {
    println(remainPath)
    200
}

// test path param return status code (named parameter)
@Get[path = "/path8_named/*"]
func pathGet8Named(@PathParam[name = *] remainPath!: String = "/default"): UInt16 {
    println(remainPath)
    200
}

// test path param datetime return status code
@Get[path = "/path9/{p}"]
func pathGet9(@PathParam[name = p] date: DateTime): UInt16 {
    println(date)
    200
}

// test path param datetime return status code (named parameter)
@Get[path = "/path9_named/{p}"]
func pathGet9Named(@PathParam[name = p] date!: DateTime = DateTime.now()): UInt16 {
    println(date)
    200
}

// test path param datetime return status code
@Get[path = "/path10/{p}"]
func pathGet10(@PathParam[name = p] date: ?DateTime): UInt16 {
    println(date)
    200
}

// test path param datetime return status code (named parameter)
@Get[path = "/path10_named/{p}"]
func pathGet10Named(@PathParam[name = p] date!: ?DateTime = DateTime.now()): UInt16 {
    println(date)
    200
}

// test path param datetime return status code
@Get[path = "/path11/{p}"]
func pathGet11(@PathParam[name = p] date: Option<DateTime>): UInt16 {
    println(date)
    200
}

// test path param datetime return status code (named parameter)
@Get[path = "/path11_named/{p}"]
func pathGet11Named(@PathParam[name = p] date!: Option<DateTime> = Some(DateTime.now())): UInt16 {
    println(date)
    200
}

// test query param with no new name
@Get[path = "/query1"]
func queryGet1(@QueryParam name: String): String {
    println(name)
    name
}

// test query param with no new name (named parameter)
@Get[path = "/query1_named"]
func queryGet1Named(@QueryParam name!: String = "defstr"): String {
    println(name)
    name
}

// test query param with a new name
@Get[path = "/query2"]
func queryGet2(@QueryParam[name = q1] name: String): String {
    println(name)
    name
}

// test query param with a new name (named parameter)
@Get[path = "/query2_named"]
func queryGet2Named(@QueryParam[name = q1] name!: String = "defstr"): String {
    println(name)
    name
}

// test query param with list type
@Get[path = "/query3"]
func queryGet3(@QueryParam[name = q1] name: ArrayList<String>): String {
    println(name)
    "list"
}

// test query param with list type (named parameter)
@Get[path = "/query3_named"]
func queryGet3Named(@QueryParam[name = q1] name!: ArrayList<String> = ArrayList<String>()) : String {
    println(name)
    "list"
}

// test query param with array type
@Get[path = "/query4"]
func queryGet4(@QueryParam[name = q1] name: Array<String>): String {
    println(name)
    "array"
}

// test query param with array type (named parameter)
@Get[path = "/query4_named"]
func queryGet4Named(@QueryParam[name = q1] name!: Array<String> = []): String {
    println(name)
    "array"
}

// test query param with default
@Get[path = "/query5"]
func queryGet5(@QueryParam[name = q1, default = "x"] name: String): String {
    println(name)
    name
}

// test query param with default (named parameter)
@Get[path = "/query5_named"]
func queryGet5Named(@QueryParam[name = q1, default = "x"] name!: String = "defstr"): String {
    println(name)
    name
}

// test post form param with String type
@Post[path = "/postform1"]
func postfrom1(@PostFormParam[name = f1] name: String): String {
    println(name)
    name
}

// test post form param with String type (named parameter)
@Post[path = "/postform1_named"]
func postfrom1Named(@PostFormParam[name = f1] name!: String = "defstr"): String {
    println(name)
    name
}

// test context param with String type
@Post[path = "/context1"]
func ctxPost1(@ContextParam[name = c1] name: String): String {
    println(name)
    name
}

// test context param with String type (named parameter)
@Post[path = "/context1_named"]
func ctxPost1Named(@ContextParam[name = c1] name!: String = "defstr"): String {
    println(name)
    name
}

// test context param with Int type
@Post[path = "/context2"]
func ctxPost2(@ContextParam[name = c1] id: Int): String {
    println(id)
    id.toString()
}

// test context param with Int type (named parameter)
@Post[path = "/context2_named"]
func ctxPost2Named(@ContextParam[name = c1] id!: Int = 100): String {
    println(id)
    id.toString()
}

class TestCtxParam <: ToString {
    public func toString() {
        "TestCtxParam"
    }
}

// test context param with custom type
@Post[path = "/context3"]
func ctxPost3(@ContextParam[name = c1] ctxParm: TestCtxParam): String {
    ctxParm.toString()
}

// test context param with custom type (named parameter)
@Post[path = "/context3_named"]
func ctxPost3Named(@ContextParam[name = c1] ctxParm!: TestCtxParam = TestCtxParam()): String {
    ctxParm.toString()
}

// test body param with string type
@Post[path = "/body1"]
func bodyPost1(@BodyParam body: String): String {
    body
}

// test body param with string type (named parameter)
@Post[path = "/body1_named"]
func bodyPost1Named(@BodyParam body!: String = "defstr"): String {
    body
}

@Json
@Derive[ToString]
class TestBody {
    var a: String = ""
    var b: Int = 0
}

// test body param with optional TestBody type
@Post[path = "/body2"]
func bodyPost2(@BodyParam body: ?TestBody): String {
    body.getOrThrow().toString()
}

// test body param with optional TestBody type (named parameter)
@Post[path = "/body2_named"]
func bodyPost2Named(@BodyParam body!: ?TestBody = TestBody()): String {
    body.getOrThrow().toString()
}

// test body param with Option<TestBody> type
@Post[path = "/body3"]
func bodyPost3(@BodyParam body: Option<TestBody>): String {
    body.getOrThrow().toString()
}

// test body param with Option<TestBody> type (named parameter)
@Post[path = "/body3_named"]
func bodyPost3Named(@BodyParam body!: Option<TestBody> = Some(TestBody())): String {
    body.getOrThrow().toString()
}

// test body param with TestBody type
@Post[path = "/body4"]
func bodyPost4(@BodyParam body: TestBody): String {
    body.toString()
}

// test body param with TestBody type (named parameter)
@Post[path = "/body4_named"]
func bodyPost4Named(@BodyParam body!: TestBody = TestBody()): String {
    body.toString()
}

// test body param with TestBody type and return json
@Post[path = "/body5", produce = json]
func bodyPost5(@BodyParam body: TestBody): TestBody {
    body
}

// test body param with TestBody type and return json (named parameter)
@Post[path = "/body5_named", produce = json]
func bodyPost5Named(@BodyParam body!: TestBody = TestBody()): TestBody {
    body
}

// test body param with TestBody type and return json array
@Post[path = "/body6", produce = json]
func bodyPost6(@BodyParam body: TestBody): Array<TestBody> {
    [body]
}

// test body param with TestBody type and return json array (named parameter)
@Post[path = "/body6_named", produce = json]
func bodyPost6Named(@BodyParam body!: TestBody = TestBody()): Array<TestBody> {
    [body]
}

// test body param with TestBody type and return (status, json array)
@Post[path = "/body7", produce = json]
func bodyPost7(@BodyParam body: TestBody): (UInt16, Array<TestBody>) {
    (200, [body])
}

// test body param with TestBody type and return (status, json array) (named parameter)
@Post[path = "/body7_named", produce = json]
func bodyPost7Named(@BodyParam body!: TestBody = TestBody()): (UInt16, Array<TestBody>) {
    (200, [body])
}

// test header param
@Post[path = "/header1"]
func headerPost1(@HeaderParam[name = "X-Tokens", default = "xxx"] token: String): String {
    token
}

// test header param (named parameter)
@Post[path = "/header1_named"]
func headerPost1Named(@HeaderParam[name = "X-Tokens", default = "xxx"] token!: String = "defstr"): String {
    token
}

// test header param
@Post[path = "/header2"]
func headerPost2(@HeaderParam[name = "X-IDS"] ids: Array<String>): String {
    ids.toString()
}

// test header param (named parameter)
@Post[path = "/header2_named"]
func headerPost2Named(@HeaderParam[name = "X-IDS"] ids!: Array<String> = []): String {
    ids.toString()
}

// test header param
@Post[path = "/header3"]
func headerPost3(@HeaderParam[name = "X-Tokens"] token: ?String): String {
    token.getOrThrow().toString()
}

// test header param (named parameter)
@Post[path = "/header3_named"]
func headerPost3Named(@HeaderParam[name = "X-Tokens"] token!: ?String = "defstr"): String {
    token.getOrThrow().toString()
}

// test cookie param
@Post[path = "/cookie1", produce = json]
func cookiePost1(@CookieParam[name = "csrf-token"] token: ?String): String {
    token.getOrThrow().toString()
}

// test cookie param (named parameter)
@Post[path = "/cookie1_named", produce = json]
func cookiePost1Named(@CookieParam[name = "csrf-token"] token!: ?String = "defstr"): String {
    token.getOrThrow().toString()
}

@Bind
@Derive[ToString]
class QueryBindParams {
    var a: String = ""
}

@Get[path = "/bind_query"]
func bind1(@QueryBindParam param: QueryBindParams): String {
    param.toString()
}

// test query bind param (named parameter)
@Get[path = "/bind_query_named"]
func bind1Named(@QueryBindParam param!: QueryBindParams = QueryBindParams()): String {
    param.toString()
}

@Bind
@Derive[ToString]
class FormBindParams {
    var a: String = ""
}

@Post[path = "/bind_postform"]
func bind2(@PostFormBindParam param: FormBindParams): String {
    param.toString()
}

// test post form bind param (named parameter)
@Post[path = "/bind_postform_named"]
func bind2Named(@PostFormBindParam param!: FormBindParams = FormBindParams()): String {
    param.toString()
}

@Bind
@Derive[ToString]
class HeaderParams {
    @BindField[name = "content-type"]
    var a: String = ""
}

@Get[path = "/bind_"]
func bind3(@HeaderBindParam param: HeaderParams): String {
    param.toString()
}

// test header bind param (named parameter)
@Get[path = "/bind__named"]
func bind3Named(@HeaderBindParam param!: HeaderParams = HeaderParams()): String {
    param.toString()
}

@Bind
@Derive[ToString]
class HeaderParamsOpt {
    @BindField[name = "x-test"]
    var a: String = ""
}

// test header bind param (optional named parameter)
@Get[path = "/bind_header_opt_named"]
func bindHeaderOptNamed(@HeaderBindParam param!: ?HeaderParamsOpt = None): String {
    match (param) {
        case Some(p) => p.toString()
        case None => "none"
    }
}

// test tuple with primitive body type and UInt16 status: (body, status)
@Get[path = "/tuple_body_status"]
func tupleBodyStatus(): (Int64, UInt16) {
    (201, 202)
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
    /**
     * 测试所有宏功能 - 验证所有路由和中间件宏是否正常工作
     */
    @TestCase
    public func testAll() {
        let joy = Joy.default()
        JoyMiddlewares.registerTo(joy)
        JoyHandlers.registerTo(joy)
        let fut = spawn {
            joy.run("127.0.0.1", 18882)
        }
        sleep(Duration.second)

        let client = JoyHttpClientService("http://127.0.0.1:18882/")
        let ctx = MapContext()
        try (rsp = client.get(ctx, "/tuple_body_status")) {
            // (Int64, UInt16) 应被识别为 (body, status)，而不是 (status, body)
            @Assert(rsp.status, 202)
            @Assert(rsp.text, "201")
        }
        try (rsp = client.get(ctx, "/bind_header_opt_named")) {
            @Assert(rsp.status, 200)
        }
        client.destroy()

        fut.cancel()
    }
}
