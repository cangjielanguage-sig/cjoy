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
import cjoy.middleware.RequestId

@Test
public class RequestIdTestCaseSuit {
    var _instance: ?Joy = None
    let _client = ClientBuilder().build()

    @BeforeAll
    func setup() {
        spawn {
            let joy = Joy.default()
            let router = joy.router
            router.use(RequestId(prefix: "test"))
            router.get(
                "/request_id",
                {
                    ctx: JoyContext => ctx.string("/request_id")
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

    @TestCase
    public func testGetOk() {
        let rsp = _client.get("http://127.0.0.1:18881/request_id")
        let reader = StringReader(rsp.body)
        @Assert(reader.readToEnd(), "/request_id")
        @Assert(rsp.headers.getFirst("X-Request-Id"), "test-0000000000")
    }
}
