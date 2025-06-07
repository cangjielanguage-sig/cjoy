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
import stdx.net.http.*
import cjoy.*
import cjoy.json.*

@Json
class UserInfo {
    var name: String = ""
    var address: String = ""
    var gender: Int = 0
}

public class JoyTestMiddleware <: JoyMiddlewareHandler {
    public func handle(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
        let numOpt = ctx.getCtxParm<Int>("num")
        match (numOpt) {
            case Some(num) => ctx.setCtxParam("num", num + 1)
            case _ => ctx.setCtxParam("num", 1)
        }
        chain.next(ctx)
    }
}

@Test
public class RouteTestCaseSuit {
    var _instance: ?Joy = None
    let _client = ClientBuilder().build()

    @BeforeAll
    func setup() {
        spawn {
            let joy = Joy.default()
            let router = joy.router
            router.use(JoyTestMiddleware()).use(JoyTestMiddleware())

            // string
            router.get(
                "/users/{name}",
                {
                    ctx: JoyContext =>
                    let name = ctx.getParam("name") ?? "no name"
                    ctx.string("/users/${name}")
                }
            )
            router.get(
                "/users/{name}/posts/{postid}",
                {
                    ctx: JoyContext =>
                    let name = ctx.getParam("name") ?? "no name"
                    let postid = ctx.getParam("postid") ?? "no post id"
                    ctx.string("/users/${name}/posts/${postid}")
                }
            )
            router.get(
                "/users",
                {
                    ctx: JoyContext =>
                    let name = ctx.getQuery("name", "no name")
                    ctx.string("/users?name=${name}")
                }
            )
            router.get(
                "/posts",
                {
                    ctx: JoyContext =>
                    let ids = ctx.getQueryList("id")
                    let str = String.join(ids.toArray(), delimiter: "&id=")
                    ctx.string("/posts?id=${str}")
                }
            )
            router.post(
                "/form",
                {
                    ctx: JoyContext =>
                    let id = ctx.getPostForm("id", "no id")
                    ctx.string("id=${id}")
                }
            )

            // json
            router.post(
                "/json",
                {
                    ctx: JoyContext =>
                    let userInfo = ctx.readJson<UserInfo>().getOrThrow()
                    ctx.json(userInfo)
                }
            )

            // Middleware
            router
                .apply(JoyTestMiddleware())
                .get(
                    "/mw-num-inline",
                    {
                        ctx: JoyContext =>
                        let num = ctx.getCtxParm<Int>("num").getOrThrow()
                        ctx.string("${num}")
                    }
                )
            router.get(
                "/mw-num",
                {
                    ctx: JoyContext =>
                    let num = ctx.getCtxParm<Int>("num").getOrThrow()
                    ctx.string("${num}")
                }
            )

            // group
            let group = router.group("/group")
            group.use(JoyTestMiddleware())
            group.get(
                "/",
                {
                    ctx: JoyContext =>
                    let num = ctx.getCtxParm<Int>("num").getOrThrow()
                    ctx.string("/group/,${num}")
                }
            )

            group
                .apply(JoyTestMiddleware())
                .get(
                    "/path",
                    {
                        ctx: JoyContext =>
                        let num = ctx.getCtxParm<Int>("num").getOrThrow()
                        ctx.string("/group/path,${num}")
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
    public func testRoutePathParam() {
        let rsp = _client.get("http://127.0.0.1:18881/users/xiao")
        let reader = StringReader(rsp.body)
        @Assert(reader.readToEnd(), "/users/xiao")
    }

    @TestCase
    public func testRoutePathParamTwo() {
        let rsp = _client.get("http://127.0.0.1:18881/users/xiao/posts/1")
        let reader = StringReader(rsp.body)
        @Assert(reader.readToEnd(), "/users/xiao/posts/1")
    }

    @TestCase
    public func testRoutePathQuery() {
        let rsp = _client.get("http://127.0.0.1:18881/users?name=xiao")
        let reader = StringReader(rsp.body)
        @Assert(reader.readToEnd(), "/users?name=xiao")
    }

    @TestCase
    public func testRoutePathQueryList() {
        let rsp = _client.get("http://127.0.0.1:18881/posts?id=1&id=2&id=3")
        let reader = StringReader(rsp.body)
        @Assert(reader.readToEnd(), "/posts?id=1&id=2&id=3")
    }

    @TestCase
    public func testRouteFormUrlEncode() {
        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18881/form")
            .post()
            .header("content-type", "application/x-www-form-urlencoded")
            .body("id=1")
            .build()
        let rsp = _client.send(req)
        let reader = StringReader(rsp.body)
        @Assert(reader.readToEnd(), "id=1")
    }

    @TestCase
    public func testRouteJson() {
        let userInfo = UserInfo()
        userInfo.name = "xiao"
        userInfo.address = "shenzhen"

        let req = HttpRequestBuilder()
            .url("http://127.0.0.1:18881/json")
            .post()
            .header("content-type", "application/json;charset=UTF-8")
            .body(JsonTool.toJson(userInfo))
            .build()
        let rsp = _client.send(req)
        let reader = StringReader(rsp.body)
        @Assert(reader.readToEnd(), JsonTool.toJson(userInfo))
    }

    @TestCase
    public func testRouteMiddleware() {
        let rsp = _client.get("http://127.0.0.1:18881/mw-num")
        let reader = StringReader(rsp.body)
        @Assert(reader.readToEnd(), "2")
    }

    @TestCase
    public func testRouteMiddlewareInline() {
        let rsp = _client.get("http://127.0.0.1:18881/mw-num-inline")
        let reader = StringReader(rsp.body)
        @Assert(reader.readToEnd(), "3")
    }

    @TestCase
    public func testRouteGroup() {
        let rsp = _client.get("http://127.0.0.1:18881/group")
        @Assert(rsp.status, 404)
    }

    @TestCase
    public func testRouteGroupRootUseMw() {
        let rsp = _client.get("http://127.0.0.1:18881/group/")
        let reader = StringReader(rsp.body)
        @Assert(reader.readToEnd(), "/group/,3")
    }

    @TestCase
    public func testRouteGroupPathUseNw() {
        let rsp = _client.get("http://127.0.0.1:18881/group/path")
        let reader = StringReader(rsp.body)
        @Assert(reader.readToEnd(), "/group/path,4")
    }
}
