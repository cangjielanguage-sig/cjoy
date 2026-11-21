/*
 * Copyright (c) 2026 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.test

import stdx.net.http.{ClientBuilder, HttpRequestBuilder}
import cjoy.*
import cjoy.middleware.Security

@Test
public class SecurityTestCaseSuit {
    var _instance: ?Joy = None
    let _client = ClientBuilder().build()

    @BeforeAll
    func setup() {
        spawn {
            let joy = Joy.create(name: "security-test")
            let router = joy.router
            router.group("/security").use(Security(allowedHosts: ["127.0.0.1"])).get("/ok", {
                ctx: JoyContext => ctx.string("ok")
            })
            _instance = joy
            joy.run("127.0.0.1", 18884)
        }
        sleep(Duration.second * 2)
    }

    @AfterAll
    func tearDown() {
        _client.close()
        _instance?.shutdown()
    }

    /**
     * 测试允许的 Host - 验证普通 HTTP 请求的 Host 头能正确匹配白名单
     */
    @TestCase
    public func testAllowedHost(): Unit {
        let rsp = _client.get("http://127.0.0.1:18884/security/ok")
        @Assert(rsp.status, 200)
    }

    /**
     * 测试不在白名单的 Host - 验证请求被拒绝
     */
    @TestCase
    public func testDeniedHost(): Unit {
        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18884/security/ok")
            .header("Host", "evil.example.com")
            .build()
        let rsp = _client.send(req)
        @Assert(rsp.status, 403)
    }
}
