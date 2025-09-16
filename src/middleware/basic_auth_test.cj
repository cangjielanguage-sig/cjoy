/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.middleware

import std.collection.HashMap
import std.unittest.mock.*
import std.unittest.mock.mockmacro.*
import stdx.encoding.url.URL
import stdx.encoding.base64.toBase64String
import cjoy.framework.{JoyContext, JoyRequestHandlerChain, JoyHttpConsts}

@Test
public class BasicAuthTestCaseSuit {
    private func createAuthHeader(): String {
        let user = "xiao"
        let pwd = "xiao"
        "Basic " + toBase64String((user + ":" + pwd).toArray())
    }

    @TestCase
    public func testAuthOk() {
        let ctx = mock<JoyContext>()
        @On(ctx.getHeader(eq(JoyHttpConsts.HEADER_AUTHORIZATION))).returns(Some(createAuthHeader()))

        let chain = mock<JoyRequestHandlerChain>()
        @On(chain.next(ctx)).returns()

        let basicAuth = BasicAuth("test", HashMap<String, String>([("xiao", "xiao")]))
        basicAuth.handle(ctx, chain)
        Verify.that(@Called(ctx.getHeader(_)))
        Verify.that(@Called(chain.next(_)))
    }

    @TestCase
    public func testAuthFailed() {
        let ctx = mock<JoyContext>()
        @On(ctx.getHeader(eq(JoyHttpConsts.HEADER_AUTHORIZATION))).returns(Some(createAuthHeader()))
        @On(ctx.getClientIP()).returns("127.0.0.1")
        @On(ctx.method).returns("GET")
        @On(ctx.url).returns(URL.parse("http://127.0.0.1/abc"))
        @On(ctx.header(_, _)).returns(ctx)
        @On(ctx.status(_)).returns(ctx)

        let chain = mock<JoyRequestHandlerChain>()

        let basicAuth = BasicAuth("test", HashMap<String, String>([("x", "y")]))
        basicAuth.handle(ctx, chain)
        Verify.that(@Called(ctx.getHeader(_)))
        Verify.that(@Called(ctx.header(_, _)))
        Verify.that(@Called(ctx.status(_)))
        Verify.that(@Called(chain.next(_)).never())
    }
}
