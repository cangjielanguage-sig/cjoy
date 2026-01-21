/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.framework

import std.collection.*
import std.unittest.testmacro.*

@Test
public class TreeNodeTestCaseSuit {
    private func addPath(tree: TreeNode<Int64>, pattern: String, hander: Int64) {
        tree.addRoute("GET", pattern, hander)
    }

    private func addPath(tree: TreeNode<Int64>, method: String, pattern: String, hander: Int64) {
        tree.addRoute(method, pattern, hander)
    }

    private func testPath(tree: TreeNode<Int64>, path: String, expectPath: String,
        expectedParams: HashMap<String, String>, handler!: Int64 = 1) {
        let ri: RouteInfo<Int64> = RouteInfo()
        let node = tree.findRouteHandler(ri, "GET", path)
        if ((expectPath != "" && node.isNone()) || (expectPath != "" && ri.pattern != expectPath)) {
            @Fail("not match for ${path}, expected ${expectPath}, acutual=${ri.pattern}")
            return
        } else if (expectPath == "" && node.isSome()) {
            @Fail("expected no match for ${path} but got with params ${expectedParams}")
            return
        }

        if (node.isNone()) {
            return
        }

        if (ri.handler.isNone()) {
            @Fail("path ${path} returned node without handler")
            return
        } else {
            if (handler != ri.handler.getOrThrow()) {
                @Fail("not math handler for path ${path}, expected ${handler}, actual=${ri.handler.getOrThrow()}")
            }
        }

        if (expectedParams.isEmpty()) {
            if (!ri.routeParamKeys.isEmpty()) {
                @Fail("Path ${path} expected no parameters, saw ${ri.routeParamKeys}")
            }
        } else {
            if (expectedParams.size != ri.routeParamKeys.size) {
                @Fail("Got ${ri.routeParamKeys.size} params back but node specifies ${expectedParams.size}")
            }

            if (ri.routeParamKeys.size != ri.routeParamValues.size) {
                @Fail("Got ${ri.routeParamKeys.size} params back but value specifies ${ri.routeParamValues.size}")
            }

            let xparams = HashMap<String, String>()
            for (i in 0..ri.routeParamKeys.size) {
                xparams.add(ri.routeParamKeys[i], ri.routeParamValues[i])
            }

            for ((k, v) in expectedParams) {
                let e = xparams.get(k)
                if (e.isNone()) {
                    @Fail("Path ${path} matched without key ${k}")
                } else if (e.getOrThrow() != v) {
                    @Fail("Path ${path} expected param ${k} to be ${v}, saw ${e.getOrThrow()}")
                }
                xparams.remove(k)
            }
            for ((k, v) in xparams) {
                @Fail("Path ${path} returned unexpected param ${k}=${v}")
            }
        }
    }

    @TestCase
    public func testTree() {
        let node = TreeNode<Int64>(NT_STATIC, b'\0', "")
        addPath(node, "/", 1)
        addPath(node, "/favicon.ico", 1)
        addPath(node, "/pages/*", 1)

        addPath(node, "/article", 1)
        addPath(node, "/article2", 1)
        addPath(node, "/article/", 1)

        addPath(node, "/article/near", 1)
        addPath(node, "/article/{id}", 1)
        addPath(node, "/article/{id}", 2)
        addPath(node, "/article/{id}", 3)
        addPath(node, "/article/@{user}", 1)

        addPath(node, "/article/{sup}/{opts}", 1)
        addPath(node, "/article/{id}/{opts}", 1)

        addPath(node, "/article/{iffd}/edit", 1)
        addPath(node, "/article/{id}//related", 1)
        addPath(node, "/article/slug/{month}/-/{day}/{year}", 1)

        addPath(node, "/admin/user", 1)
        addPath(node, "/admin/user/", 2)
        addPath(node, "/admin/user/", 3)

        addPath(node, "/admin/user//{id}", 1)
        addPath(node, "/admin/user/{id}", 1)

        addPath(node, "/admin/apps/{id}", 1)
        addPath(node, "/admin/apps/{id}/*", 1)

        addPath(node, "/admin/*", 1)
        addPath(node, "/admin/*", 2)

        addPath(node, "/users/{userID}/profile", 1)
        addPath(node, "/users/super/*", 1)
        addPath(node, "/users/*", 1)

        addPath(node, "/hubs/{hubID}/view", 1)
        addPath(node, "/hubs/{hubID}/view/*", 1)

        addPath(node, "/hubs/{hubID}/*", 1)
        addPath(node, "/hubs/{hubID}/users", 1)

        println(node.dumpTree())

        testPath(node, "/", "/", HashMap(), handler: 1)
        testPath(node, "/favicon.ico", "/favicon.ico", HashMap(), handler: 1)

        testPath(node, "/pages", "", HashMap(), handler: 1)
        testPath(node, "/pages/", "/pages/*", HashMap([("*", "")]), handler: 1)
        testPath(node, "/pages/yes", "/pages/*", HashMap([("*", "yes")]), handler: 1)

        testPath(node, "/article", "/article", HashMap(), handler: 1)
        testPath(node, "/article/", "/article/", HashMap(), handler: 1)
        testPath(node, "/article/near", "/article/near", HashMap(), handler: 1)
        testPath(node, "/article/neard", "/article/{id}", HashMap([("id", "neard")]), handler: 3)
        testPath(node, "/article/123", "/article/{id}", HashMap([("id", "123")]), handler: 3)
        testPath(node, "/article/123/456", "/article/{id}/{opts}", HashMap([("id", "123"), ("opts", "456")]), handler: 1
        )
        testPath(node, "/article/@peter", "/article/@{user}", HashMap([("user", "peter")]), handler: 1)
        testPath(node, "/article/22//related", "/article/{id}//related", HashMap([("id", "22")]), handler: 1)
        testPath(node, "/article/111/edit", "/article/{iffd}/edit", HashMap([("iffd", "111")]), handler: 1)
        testPath(node, "/article/slug/sept/-/4/2015", "/article/slug/{month}/-/{day}/{year}",
            HashMap([("month", "sept"), ("day", "4"), ("year", "2015")]), handler: 1)
        testPath(node, "/article/:id", "/article/{id}", HashMap([("id", ":id")]), handler: 3)

        testPath(node, "/admin/user", "/admin/user", HashMap(), handler: 1)
        testPath(node, "/admin/user/", "/admin/user/", HashMap(), handler: 3)
        testPath(node, "/admin/user/1", "/admin/user/{id}", HashMap([("id", "1")]), handler: 1)
        testPath(node, "/admin/user//1", "/admin/user//{id}", HashMap([("id", "1")]), handler: 1)
        testPath(node, "/admin/hi", "/admin/*", HashMap([("*", "hi")]), handler: 2)
        testPath(node, "/admin/lots/of/:fun", "/admin/*", HashMap([("*", "lots/of/:fun")]), handler: 2)
        testPath(node, "/admin/apps/333", "/admin/apps/{id}", HashMap([("id", "333")]), handler: 1)
        testPath(node, "/admin/apps/333/woot", "/admin/apps/{id}/*", HashMap([("id", "333"), ("*", "woot")]), handler: 1
        )

        testPath(node, "/hubs/123/view", "/hubs/{hubID}/view", HashMap([("hubID", "123")]), handler: 1)
        testPath(node, "/hubs/123/view/index.html", "/hubs/{hubID}/view/*",
            HashMap([("hubID", "123"), ("*", "index.html")]), handler: 1)
        testPath(node, "/hubs/123/users", "/hubs/{hubID}/users", HashMap([("hubID", "123")]), handler: 1)

        testPath(node, "/users/123/profile", "/users/{userID}/profile", HashMap([("userID", "123")]), handler: 1)
        testPath(node, "/users/super/123/okay/yes", "/users/super/*", HashMap([("*", "123/okay/yes")]), handler: 1)
        testPath(node, "/users/123/okay/yes", "/users/*", HashMap([("*", "123/okay/yes")]), handler: 1)
    }

    @TestCase
    public func testTreeMoar() {
        let node = TreeNode<Int64>(NT_STATIC, b'\0', "")

        addPath(node, "/articlefun", 5)
        addPath(node, "/articles/{id}", 1)
        addPath(node, "DELETE", "/articles/{slug}", 8)
        addPath(node, "/articles/search", 1)
        addPath(node, "/articles/{id}:delete", 8)
        addPath(node, "/articles/{id}!sup", 4)
        addPath(node, "/articles/{id}:{op}", 3)
        addPath(node, "/articles/{id}:{op}", 2)
        addPath(node, "/articles/{slug:^[a-z]+}/posts", 1)
        addPath(node, "/articles/{id}/posts/{pid}", 6)
        addPath(node, "/articles/{id}/posts/{month}/{day}/{year}/{slug}", 7)
        addPath(node, "/articles/{id}.json", 10)
        addPath(node, "/articles/{id}/data.json", 11)
        addPath(node, "/articles/files/{file}.{ext}", 12)
        addPath(node, "PUT", "/articles/me", 13)

        addPath(node, "/pages/*", 1)
        addPath(node, "/pages/*", 2)

        addPath(node, "/users/{id}", 1)
        addPath(node, "/users/{id}/settings/{key}", 1)
        addPath(node, "/users/{id}/settings/*", 1)

        println(node.dumpTree())

        testPath(node, "/articles/search", "/articles/search", HashMap(), handler: 1)
        testPath(node, "/articlefun", "/articlefun", HashMap(), handler: 5)
        testPath(node, "/articles/123", "/articles/{id}", HashMap([("id", "123")]), handler: 1)

        testPath(node, "/articles/789:delete", "/articles/{id}:delete", HashMap([("id", "789")]), handler: 8)
        testPath(node, "/articles/789!sup", "/articles/{id}!sup", HashMap([("id", "789")]), handler: 4)
        testPath(node, "/articles/123:sync", "/articles/{id}:{op}", HashMap([("id", "123"), ("op", "sync")]), handler: 2
        )
        testPath(node, "/articles/456/posts/1", "/articles/{id}/posts/{pid}", HashMap([("id", "456"), ("pid", "1")]),
            handler: 6)
        testPath(node, "/articles/456/posts/09/04/1984/juice", "/articles/{id}/posts/{month}/{day}/{year}/{slug}",
            HashMap([("id", "456"), ("month", "09"), ("day", "04"), ("year", "1984"), ("slug", "juice")]), handler: 7)
        testPath(node, "/articles/456.json", "/articles/{id}.json", HashMap([("id", "456")]), handler: 10)
        testPath(node, "/articles/456/data.json", "/articles/{id}/data.json", HashMap([("id", "456")]), handler: 11)

        testPath(node, "/articles/files/file.zip", "/articles/files/{file}.{ext}",
            HashMap([("file", "file"), ("ext", "zip")]), handler: 12)
        testPath(node, "/articles/files/photos.tar.gz", "/articles/files/{file}.{ext}",
            HashMap([("file", "photos"), ("ext", "tar.gz")]), handler: 12)

        testPath(node, "/articles/me", "/articles/{id}", HashMap([("id", "me")]), handler: 1)

        testPath(node, "/pages", "", HashMap(), handler: 1)
        testPath(node, "/pages/", "/pages/*", HashMap([("*", "")]), handler: 2)
        testPath(node, "/pages/yes", "/pages/*", HashMap([("*", "yes")]), handler: 2)

        testPath(node, "/users/1", "/users/{id}", HashMap([("id", "1")]), handler: 1)
        testPath(node, "/users", "", HashMap(), handler: 1)
        testPath(node, "/users/2/settings/password", "/users/{id}/settings/{key}",
            HashMap([("id", "2"), ("key", "password")]), handler: 1)
        testPath(node, "/users/2/settings/", "/users/{id}/settings/*", HashMap([("id", "2"), ("*", "")]), handler: 1)
    }

    @TestCase
    public func testTreeRegexp() {
        let node = TreeNode<Int64>(NT_STATIC, b'\0', "")

        addPath(node, "/articles/{rid:^[0-9]{5,6}}", 1)
        addPath(node, "/articles/{zid:^0[0-9]+}", 2)
        addPath(node, "/articles/{name:^@[a-z]+}/posts", 3)
        addPath(node, "/articles/{op:^[0-9]+}/run", 4)
        addPath(node, "/articles/{id:^[0-9]+}", 5)
        addPath(node, "/articles/{id:^[1-9]+}-{aux}", 6)
        addPath(node, "/articles/{slug}", 7)

        println(node.dumpTree())

        testPath(node, "/articles", "", HashMap(), handler: 1)
        testPath(node, "/articles/12345", "/articles/{rid:^[0-9]{5,6}}", HashMap([("rid", "12345")]), handler: 1)
        testPath(node, "/articles/123", "/articles/{id:^[0-9]+}", HashMap([("id", "123")]), handler: 5)
        testPath(node, "/articles/how-to-build-a-router", "/articles/{slug}",
            HashMap([("slug", "how-to-build-a-router")]), handler: 7)
        testPath(node, "/articles/0456", "/articles/{zid:^0[0-9]+}", HashMap([("zid", "0456")]), handler: 2)
        testPath(node, "/articles/@pk/posts", "/articles/{name:^@[a-z]+}/posts", HashMap([("name", "@pk")]), handler: 3)
        testPath(node, "/articles/1/run", "/articles/{op:^[0-9]+}/run", HashMap([("op", "1")]), handler: 4)
        testPath(node, "/articles/1122", "/articles/{id:^[0-9]+}", HashMap([("id", "1122")]), handler: 5)
        testPath(node, "/articles/1122-yes", "/articles/{id:^[1-9]+}-{aux}", HashMap([("id", "1122"), ("aux", "yes")]),
            handler: 6)
    }

    @TestCase
    public func testTreeRegexpRecursive() {
        let node = TreeNode<Int64>(NT_STATIC, b'\0', "")

        addPath(node, "/one/{firstId:[a-z0-9-]+}/{secondId:[a-z0-9-]+}/first", 1)
        addPath(node, "/one/{firstId:[a-z0-9-_]+}/{secondId:[a-z0-9-_]+}/second", 2)

        println(node.dumpTree())

        testPath(node, "/one/hello/world/first", "/one/{firstId:[a-z0-9-]+}/{secondId:[a-z0-9-]+}/first",
            HashMap([("firstId", "hello"), ("secondId", "world")]), handler: 1)
        testPath(node, "/one/hi_there/ok/second", "/one/{firstId:[a-z0-9-_]+}/{secondId:[a-z0-9-_]+}/second",
            HashMap([("firstId", "hi_there"), ("secondId", "ok")]), handler: 2)
        testPath(node, "/one///first", "", HashMap(), handler: 1)
        testPath(node, "/one/hi/123/second", "/one/{firstId:[a-z0-9-_]+}/{secondId:[a-z0-9-_]+}/second",
            HashMap([("firstId", "hi"), ("secondId", "123")]), handler: 2)
    }

    @TestCase
    public func testTreeRegexpMatchWholeParam() {
        let node = TreeNode<Int64>(NT_STATIC, b'\0', "")

        addPath(node, "/{id:[0-9]+}", 1)
        addPath(node, "/{x:.+}/foo", 1)
        addPath(node, "/{param:[0-9]*}/test", 1)

        println(node.dumpTree())

        testPath(node, "/123", "/{id:[0-9]+}", HashMap([("id", "123")]), handler: 1)
        testPath(node, "/a123", "", HashMap(), handler: 1)
        testPath(node, "/13.jpg", "", HashMap(), handler: 1)
        testPath(node, "/a/foo", "/{x:.+}/foo", HashMap([("x", "a")]), handler: 1)
        testPath(node, "//foo", "", HashMap(), handler: 1)
        testPath(node, "//test", "/{param:[0-9]*}/test", HashMap([("param", "")]), handler: 1)
    }

    @TestCase
    public func testTreeFindPattern() {
        let node = TreeNode<Int64>(NT_STATIC, b'\0', "")

        addPath(node, "/pages/*", 1)
        addPath(node, "/articles/{id}/*", 1)
        addPath(node, "/articles/{slug}/{uid}/*", 1)

        if (node.findPattern("/pages")) {
            @Fail("find /pages failed")
        }
        if (node.findPattern("/pages*")) {
            @Fail("find /pages* failed - should be nil")
        }
        if (!node.findPattern("/pages/*")) {
            @Fail("find /pages/* failed")
        }
        if (!node.findPattern("/articles/{id}/*")) {
            @Fail("find /articles/{id}/* failed")
        }
        if (!node.findPattern("/articles/{something}/*")) {
            @Fail("find /articles/{something}/* failed")
        }
        if (!node.findPattern("/articles/{slug}/{uid}/*")) {
            @Fail("find /articles/{slug}/{uid}/* failed")
        }
    }
}
