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

import std.io.*
import std.unittest.*
import std.unittest.testmacro.*
import net.http.*
import encoding.url.*
import cjoy.*
import cjoy.json.*

@Test
public class FileServerTestCaseSuit {
    var _instance: ?Joy = None
    let _client = ClientBuilder().build()

    @BeforeAll
    func setup() {
        spawn {
            let joy = Joy.default()
            let router = joy.router
            router.staticFile("/static/logo.png", "./doc/imgs/logo.png")
            router.staticFs("/static", "./doc")
            _instance = joy
            joy.run("127.0.0.1", 18882)
        }
        sleep(Duration.second)
    }

    @AfterAll
    func tearDown() {
        _client.close()
        _instance?.shutdown()
    }

    @TestCase
    public func testStaticFile() {
        let rsp = _client.get("http://127.0.0.1:18882/static/logo.png")
        @Assert(rsp.status, 200)
        @Assert(rsp.headers.getFirst("content-type"), "image/png")
    }

    @TestCase
    public func testStaticFsGetImgFile() {
        let rsp = _client.get("http://127.0.0.1:18882/static/imgs/logo.png")
        @Assert(rsp.status, 200)
        @Assert(rsp.headers.getFirst("content-type"), "image/png")
    }

    @TestCase
    public func testStaticFsGetTextFile() {
        let rsp = _client.get("http://127.0.0.1:18882/static/dev_guide.md")
        @Assert(rsp.status, 200)
    }
}
