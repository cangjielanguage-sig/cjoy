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

import std.io.*
import stdx.net.http.*
import stdx.encoding.base64.toBase64String
import cjoy.*
import cjoy.json.*
import cjoy.middleware.BasicAuth

@Test
public class BasicAuthTestCaseSuit {
    var _instance: ?Joy = None
    let _client = ClientBuilder().build()

    @BeforeAll
    func setup() {
        let basicAuth = BasicAuth("test", HashMap<String, String>([("xiao", "xiao"), ("lanling", "lanling")]))
        let basicAuthWithValFunc = BasicAuth("test", HashMap<String, String>(), validateFunc: {
            ctx: JoyContext, username: String, password: String => username == "xiao" && password == "xiao"
        })

        spawn {
            let joy = Joy.default()
            let router = joy.router
            router.use(basicAuth)
            router.get(
                "/basic_auth",
                {
                    ctx: JoyContext => ctx.string("/basic_auth")
                }
            )

            let group = router.group("/auth2")
            group.use(basicAuthWithValFunc)
            group.get(
                "/a",
                {
                    ctx: JoyContext => ctx.string("/basic_auth")
                }
            )
            _instance = joy
            joy.run("127.0.0.1", 18881)
        }
        sleep(Duration.second * 2)
    }

    @AfterAll
    func tearDown() {
        _client.close()
        _instance?.shutdown()
    }

    private func createAuthHeader(pwd!: String = "xiao"): String {
        let user = "xiao"
        "Basic " + toBase64String((user + ":" + pwd).toArray())
    }

    @TestCase
    public func testAuthOk() {
        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18881/basic_auth")
            .method("GET")
            .header(JoyHttpConsts.HEADER_AUTHORIZATION, createAuthHeader())
            .build()
        let rsp = _client.send(req)
        let reader = StringReader(rsp.body)
        @Assert(reader.readToEnd(), "/basic_auth")
    }

    @TestCase
    public func testAuthOkWithValidateFun() {
        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18881/auth2/a")
            .method("GET")
            .header(JoyHttpConsts.HEADER_AUTHORIZATION, createAuthHeader())
            .build()
        let rsp = _client.send(req)
        let reader = StringReader(rsp.body)
        @Assert(reader.readToEnd(), "/basic_auth")
    }

    @TestCase
    public func testAuthFailed() {
        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18881/basic_auth")
            .method("GET")
            .header(JoyHttpConsts.HEADER_AUTHORIZATION, createAuthHeader(pwd: "abc"))
            .build()
        let rsp = _client.send(req)
        @Assert(rsp.status, 401)
        @Assert(rsp.headers.getFirst(JoyHttpConsts.HEADER_WWW_AUTHENTICATE), "Basic realm=test")
    }
}
