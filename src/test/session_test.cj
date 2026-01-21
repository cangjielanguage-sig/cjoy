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
import cjoy.*
import cjoy.json.*
import cjoy.session.*
import cjoy.middleware.{SessionManager, getSession}

@Test
public class SessionTestCaseSuit {
    var _instance: ?Joy = None
    let _client = ClientBuilder().build()

    @BeforeAll
    func setup() {
        let sessionManager = SessionManager(MemorySessionStorage())
        spawn {
            let joy = Joy.default()
            let router = joy.router
            router.use(sessionManager)
            router.get(
                "/sesson",
                {
                    ctx: JoyContext =>
                    let session = getSession(ctx).getOrThrow()
                    session.set("session-data-key1", "session-data-value1")
                }
            )
            router.get(
                "/sesson-data",
                {
                    ctx: JoyContext =>
                    let session = getSession(ctx).getOrThrow()
                    let data = session.get<String>("session-data-key1").getOrDefault({=> ""})
                    ctx.string(data)
                }
            )
            router.get(
                "/session-delete",
                {
                    ctx: JoyContext =>
                    let session = getSession(ctx).getOrThrow()
                    session.invalidate()
                }
            )
            _instance = joy
            joy.run("127.0.0.1", 18881)
        }
        sleep(Duration.second)
    }

    @AfterAll
    func tearDown() {
        _client.close()
        _instance?.shutdown()
    }

    private func getSessionId(cookie: String) {
        var cname = ""
        let keyvals = cookie.split(",")
        for (it in keyvals) {
            let nvs = it.split("=")
            if (nvs[0].trimAscii() == "sid") {
                cname = nvs[1]
                break
            }
        }
        cname
    }

    @TestCase
    public func testGetOk() {
        var rsp = _client.get("http://127.0.0.1:18881/sesson")
        let cookie: String = rsp.headers.getFirst(JoyHttpConsts.HEADER_SET_COOKIE).getOrThrow()
        @Assert(cookie != "")
        var cname = getSessionId(cookie)
        @Assert(cname != "")

        rsp = _client.get("http://127.0.0.1:18881/sesson-data")
        let reader = StringReader(rsp.body)
        @Assert(reader.readToEnd(), "session-data-value1")

        _client.get("http://127.0.0.1:18881/session-delete")
    }

    @TestCase
    public func testDelOk() {
        var rsp = _client.get("http://127.0.0.1:18881/sesson")
        var cookie: String = rsp.headers.getFirst(JoyHttpConsts.HEADER_SET_COOKIE).getOrThrow()
        @Assert(cookie != "")
        var cname1 = getSessionId(cookie)
        @Assert(cname1 != "")

        // delete session
        _client.get("http://127.0.0.1:18881/session-delete")

        // create new session
        rsp = _client.get("http://127.0.0.1:18881/sesson")
        cookie = rsp.headers.getFirst(JoyHttpConsts.HEADER_SET_COOKIE).getOrThrow()
        @Assert(cookie != "")
        var cname2 = getSessionId(cookie)
        @Assert(cname1 != cname2)

        _client.get("http://127.0.0.1:18881/session-delete")
    }
}
