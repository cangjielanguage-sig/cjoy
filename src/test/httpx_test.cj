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

import std.unittest.mock.*
import stdx.net.http.*
import cjoy.*
import cjoy.macros.*
import cjoy.context.Context
import cjoy.httpx.*

@Get[path = "/get_path"]
func get1(ctx: JoyContext): Unit {
    ctx.string("path1")
}

@Test
public class JoyHttpClientServiceTestCaseSuit {
    var _instance: ?Joy = None

    @BeforeAll
    func setup() {
        spawn {
            let joy = Joy.default()
            let router = joy.router
            _instance = joy
            JoyHandlers.registerTo(joy)
            joy.run("127.0.0.1", 18881)
        }
        sleep(Duration.second)
    }

    @AfterAll
    func tearDown() {
        _instance?.shutdown()
    }

    @TestCase
    public func testGetOk() {
        let ctx = mock<Context>()
        let client = JoyHttpClientService("http://127.0.0.1:18881/")
        let rsp = client.get(ctx, "/get_path")
        @Assert(rsp.status, 200)
        @Assert(rsp.text, "path1")
        client.destroy()
    }
}
