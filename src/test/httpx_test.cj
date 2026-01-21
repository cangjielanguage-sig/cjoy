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

import std.collection.*
import stdx.net.http.*
import stdx.encoding.url.*
import cjoy.*
import cjoy.macros.*
import cjoy.json.*
import cjoy.middleware.{BasicAuth, TokenAuth}
import cjoy.context.*
import cjoy.httpx.*
import cjoy.multipart.*

@Json
class TestJsonData {
    public var a: String = ""
    public var b: String = ""
}

@Handler[path = "/httpx_handler", methods = "GET,POST,PUT,DELETE,PATCH"]
private func handler(ctx: JoyContext): Unit {
    var content = "httpx_handler"
    content += ctx.getQuery("q1", "")
    content += ctx.getHeader("h1") ?? ""
    content += ctx.getPostForm("p1", "")
    if (let Some(u) <- ctx.readJson<TestJsonData>()) {
        content += u.a
        content += u.b
    }
    ctx.string(content)
}

@Get[path = "/sse"]
private func sseHandler(ctx: JoyContext): Unit {
    let emitter = ctx.eventEmitter()
    for (num in 1..=10) {
        emitter.sendEvent(JoyServerEventBuilder().data("${num}"))
    }
}

@Get[path = "/basic_auth"]
private func basicAuth(ctx: JoyContext): Unit {
    ctx.string("basic_auth")
}

@Get[path = "/token_auth"]
private func tokenAuth(ctx: JoyContext): Unit {
    ctx.string("token_auth")
}

@Post[path = "/multpart"]
private func multpart(ctx: JoyContext): Unit {
    var content = ""
    try (form = JoyMultiPartForm.create(ctx, JoyMultiPartConfig())) {
        form.parse()
        let a: ?String = form.getPart("f1")?.text ?? ""
        content += (a ?? "")
        let b: ?String = form.getPart("f2")?.fileName ?? ""
        content += (b ?? "")
    }
    ctx.string(content)
}

@Test
public class JoyHttpClientServiceTestCaseSuit {
    var _instance: ?Joy = None
    let _ctx = MapContext()
    let _client = JoyHttpClientService("http://127.0.0.1:18881/")

    @BeforeAll
    func setup() {
        let basicAuth = BasicAuth("test", HashMap<String, String>([("xiao", "xiao")]))
        let tokenAuth = TokenAuth("abcd")
        spawn {
            let joy = Joy.default()
            let router = joy.router
            router.group("/basic_auth").use(basicAuth)
            router.group("/token_auth").use(tokenAuth)
            _instance = joy
            JoyHandlers.registerTo(joy)
            joy.run("127.0.0.1", 18881)
        }
        sleep(Duration.second)
    }

    @AfterAll
    func tearDown() {
        _client.destroy()
        _instance?.shutdown()
    }

    @TestCase
    public func testGetOk() {
        let rsp = _client.get(_ctx, "/httpx_handler")
        assertReponse(rsp)
    }

    private func assertReponse(rsp: JoyHttpResponse): Unit {
        @Assert(rsp.status, 200)
        @Assert(rsp.text, "httpx_handler")
    }

    private func assertReponse(rsp: JoyHttpResponse, exp: String): Unit {
        @Assert(rsp.status, 200)
        @Assert(rsp.text, exp)
    }

    @TestCase
    public func testPostOk() {
        let rsp = _client.post(_ctx, "/httpx_handler", Option<Any>.None)
        assertReponse(rsp)
    }

    @TestCase
    public func testPutOk() {
        let rsp = _client.put(_ctx, "/httpx_handler", Option<Any>.None)
        assertReponse(rsp)
    }

    @TestCase
    public func testPatchOk() {
        let rsp = _client.patch(_ctx, "/httpx_handler", Option<Any>.None)
        assertReponse(rsp)
    }

    @TestCase
    public func testDeleteOk() {
        let rsp = _client.delete(_ctx, "/httpx_handler")
        assertReponse(rsp)
    }

    @TestCase
    public func testPostWithJson() {
        let rsp = _client.send(_ctx, JoyHttpRequest.of("/httpx_handler").post().json(TestJsonData(a: "a", b: "b")))
        assertReponse(rsp, "httpx_handlerab")
    }

    @TestCase
    public func testPostWithJson2() {
        let rsp = _client.send(_ctx, JoyHttpRequest.of("/httpx_handler").post().body(TestJsonData(a: "a", b: "b")))
        assertReponse(rsp, "httpx_handlerab")
    }

    @TestCase
    public func testPostWithJson3() {
        let rsp = _client.send(_ctx,
            JoyHttpRequest.of("/httpx_handler").post().body(JsonRequest(TestJsonData(a: "a", b: "b"))))
        assertReponse(rsp, "httpx_handlerab")
    }

    @TestCase
    public func testPostWithJson4() {
        let rsp = _client.send(_ctx,
            JoyHttpRequest.of("/httpx_handler").post().body(JsonRequest(JsonTool.toJson(TestJsonData(a: "a", b: "b")))))
        assertReponse(rsp, "httpx_handlerab")
    }

    @TestCase
    public func testPostMultiPart() {
        let rsp = _client.send(
            _ctx,
            JoyHttpRequest.of("/multpart").multiPart(
                {
                    writer: JoyMultiPartWriter =>
                        writer.writeField("f1", "text")
                        writer.writeFile("f2", 'file.txt', "file contents".toArray())
                }
            )
        )
        assertReponse(rsp, "textfile.txt")
    }

    @TestCase
    public func testGetWithQuery() {
        let rsp = _client.get(_ctx, "/httpx_handler", HashMap<String, ToString>([("q1", "v1")]))
        assertReponse(rsp, "httpx_handlerv1")
    }

    @TestCase
    public func testGetWithHeader() {
        let h = HttpHeaders()
        h.add("h1", "v1")
        let rsp = _client.get(_ctx, "/httpx_handler", h)
        assertReponse(rsp, "httpx_handlerv1")
    }

    @TestCase
    public func testPostForm() {
        let f = Form()
        f.add("p1", "v1")
        let rsp = _client.postform(_ctx, "/httpx_handler", f)
        assertReponse(rsp, "httpx_handlerv1")
    }

    @TestCase
    public func testPostForm2() {
        let rsp = _client.send(_ctx, JoyHttpRequest.of("/httpx_handler").postform("p1", "v1"))
        assertReponse(rsp, "httpx_handlerv1")
    }

    @TestCase
    public func testGetStream() {
        let rsp = _client.get(_ctx, "/sse")
        var num = 0
        for (evt in rsp.eventStream) {
            println(evt.data)
            num++
        }
        @Assert(num, 10)
    }

    @TestCase
    public func testBasicAuth() {
        let c = BasicAuthClient(_client, username: "xiao", password: "xiao")
        let tc = RetryClient(c)
        let rsp = tc.get(_ctx, "/basic_auth")
        assertReponse(rsp, "basic_auth")
    }

    @TestCase
    public func testTokenAuth() {
        let c = TokenAuthClient(_client, token: "abcd")
        let rsp = c.get(_ctx, "/token_auth")
        assertReponse(rsp, "token_auth")
    }
}
