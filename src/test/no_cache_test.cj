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
import cjoy.middleware.NoCache

@Test
public class NoCacheTestCaseSuit {
    var _instance: ?Joy = None
    let _client = ClientBuilder().build()

    @BeforeAll
    func setup() {
        spawn {
            let joy = Joy.default()
            let router = joy.router
            router.use(NoCache())
            router.get(
                "/no_cache",
                {
                    ctx: JoyContext => ctx.string("/no_cache")
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
    public func testNoCacheOk() {
        let rsp = _client.get("http://127.0.0.1:18881/no_cache")
        let reader = StringReader(rsp.body)
        @Assert(reader.readToEnd(), "/no_cache")
        @Assert(rsp.headers.getFirst(JoyHttpConsts.HEADER_EXPIRES), "Thu, 01 Jan 1970 00:00:00 GMT")
        @Assert(rsp.headers.getFirst(JoyHttpConsts.HEADER_CACHE_CONTROL), "no-cache, no-store, no-transform, must-revalidate, private, max-age=0")
        @Assert(rsp.headers.getFirst("X-Accel-Expires"), "0")
        @Assert(rsp.headers.getFirst(JoyHttpConsts.HEADER_PRAGMA), "no-cache")
    }
}
