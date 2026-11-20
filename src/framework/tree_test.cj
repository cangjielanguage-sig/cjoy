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

    /**
     * 测试树形路由基本功能 - 验证各种类型的路由可以正确添加和匹配
     */
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

    /**
     * 测试树形路由高级功能 - 验证更复杂的路由模式和HTTP方法匹配
     */
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

    /**
     * 测试树形路由正则表达式 - 验证带正则表达式约束的路由参数匹配
     */
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

    /**
     * 测试树形路由递归正则表达式 - 验证递归正则表达式路由参数匹配
     */
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

    /**
     * 测试树形路由正则表达式匹配完整参数 - 验证正则表达式对完整参数的匹配
     */
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

    /**
     * 测试树形路由模式查找 - 验证是否可以正确查找已添加的路由模式
     */
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

    /**
     * 测试空树 - 验证空树不匹配任何路径
     */
    @TestCase
    public func testEmptyTree() {
        let node = TreeNode<Int64>(NT_STATIC, b'\0', "")

        let ri: RouteInfo<Int64> = RouteInfo()
        let result = node.findRouteHandler(ri, "GET", "/")

        @Assert(result.isNone(), true)
    }

    /**
     * 测试根节点路由 - 验证根路径路由正确
     */
    @TestCase
    public func testRootNodeRoute() {
        let node = TreeNode<Int64>(NT_STATIC, b'\0', "")
        addPath(node, "/", 1)

        let ri: RouteInfo<Int64> = RouteInfo()
        let result = node.findRouteHandler(ri, "GET", "/")

        @Assert(result.isSome(), true)
        @Assert(ri.handler.getOrThrow(), 1)
    }

    /**
     * 测试静态节点类型 - 验证静态节点正确处理
     */
    @TestCase
    public func testStaticNodeType() {
        let node = TreeNode<Int64>(NT_STATIC, b'\0', "")
        addPath(node, "/static/path", 1)

        let ri: RouteInfo<Int64> = RouteInfo()
        let result = node.findRouteHandler(ri, "GET", "/static/path")

        @Assert(result.isSome(), true)
        @Assert(ri.pattern, "/static/path")
    }

    /**
     * 测试参数节点类型 - 验证参数节点正确处理
     */
    @TestCase
    public func testParamNodeType() {
        let node = TreeNode<Int64>(NT_STATIC, b'\0', "")
        addPath(node, "/users/{id}", 1)

        let ri: RouteInfo<Int64> = RouteInfo()
        let result = node.findRouteHandler(ri, "GET", "/users/123")

        @Assert(result.isSome(), true)
        @Assert(ri.pattern, "/users/{id}")
        @Assert(ri.routeParamKeys.size, 1)
        @Assert(ri.routeParamKeys[0], "id")
        @Assert(ri.routeParamValues[0], "123")
    }

    /**
     * 测试通配符节点类型 - 验证通配符节点正确处理
     */
    @TestCase
    public func testCatchAllNodeType() {
        let node = TreeNode<Int64>(NT_STATIC, b'\0', "")
        addPath(node, "/files/*", 1)

        let ri: RouteInfo<Int64> = RouteInfo()
        let result = node.findRouteHandler(ri, "GET", "/files/docs/readme.txt")

        @Assert(result.isSome(), true)
        @Assert(ri.pattern, "/files/*")
        @Assert(ri.routeParamKeys[0], "*")
        @Assert(ri.routeParamValues[0], "docs/readme.txt")
    }

    /**
     * 测试多 HTTP 方法 - 验证不同 HTTP 方法存储不同处理器
     */
    @TestCase
    public func testMultipleHttpMethods() {
        let node = TreeNode<Int64>(NT_STATIC, b'\0', "")
        addPath(node, "GET", "/api", 1)
        addPath(node, "POST", "/api", 2)
        addPath(node, "PUT", "/api", 3)

        let ri1: RouteInfo<Int64> = RouteInfo()
        let result1 = node.findRouteHandler(ri1, "GET", "/api")
        @Assert(result1.isSome(), true)
        @Assert(ri1.handler.getOrThrow(), 1)

        let ri2: RouteInfo<Int64> = RouteInfo()
        let result2 = node.findRouteHandler(ri2, "POST", "/api")
        @Assert(result2.isSome(), true)
        @Assert(ri2.handler.getOrThrow(), 2)

        let ri3: RouteInfo<Int64> = RouteInfo()
        let result3 = node.findRouteHandler(ri3, "PUT", "/api")
        @Assert(result3.isSome(), true)
        @Assert(ri3.handler.getOrThrow(), 3)
    }

    /**
     * 测试路径不匹配 - 验证不匹配的路径返回 None
     */
    @TestCase
    public func testPathNotMatch() {
        let node = TreeNode<Int64>(NT_STATIC, b'\0', "")
        addPath(node, "/users", 1)

        let ri: RouteInfo<Int64> = RouteInfo()
        let result = node.findRouteHandler(ri, "GET", "/products")

        @Assert(result.isNone(), true)
    }

    /**
     * 测试部分路径匹配 - 验证部分匹配不返回处理器
     */
    @TestCase
    public func testPartialPathMatch() {
        let node = TreeNode<Int64>(NT_STATIC, b'\0', "")
        addPath(node, "/users/profile", 1)

        let ri: RouteInfo<Int64> = RouteInfo()
        let result = node.findRouteHandler(ri, "GET", "/users")

        @Assert(result.isNone(), true)
    }

    /**
     * 测试参数值包含斜杠 - 验证参数值不包含斜杠
     */
    @TestCase
    public func testParamValueWithSlash() {
        let node = TreeNode<Int64>(NT_STATIC, b'\0', "")
        addPath(node, "/files/{filename}", 1)

        let ri: RouteInfo<Int64> = RouteInfo()
        let result = node.findRouteHandler(ri, "GET", "/files/path/to/file.txt")

        // 普通参数不应匹配包含斜杠的值
        @Assert(result.isNone(), true)
    }

    /**
     * 测试参数值特殊字符 - 验证参数值可以包含特殊字符
     */
    @TestCase
    public func testParamValueWithSpecialChars() {
        let node = TreeNode<Int64>(NT_STATIC, b'\0', "")
        addPath(node, "/search/{query}", 1)

        let ri: RouteInfo<Int64> = RouteInfo()
        let result = node.findRouteHandler(ri, "GET", "/search/hello%20world")

        @Assert(result.isSome(), true)
        @Assert(ri.routeParamValues[0], "hello%20world")
    }

    /**
     * 测试树节点转储 - 验证 dumpTree 方法正常工作
     */
    @TestCase
    public func testTreeDump() {
        let node = TreeNode<Int64>(NT_STATIC, b'\0', "")
        addPath(node, "/", 1)
        addPath(node, "/users", 2)
        addPath(node, "/users/{id}", 3)
        addPath(node, "/products", 4)

        let dump = node.dumpTree()
        @Assert(dump.size > 0, true)
    }

    /**
     * 测试大小写不敏感路由匹配 - 验证静态路径和参数名/参数值不会被改写
     */
    @TestCase
    public func testCaseInsensitiveRouteMatching() {
        let node = TreeNode<Int64>(NT_STATIC, b'\0', "", caseInsensitive: true)
        addPath(node, "/Users/{UserID}", 1)
        addPath(node, "/Users/Profile", 2)

        let ri = RouteInfo<Int64>()
        let result = node.findRouteHandler(ri, "GET", "/users/AbCdEf")
        @Assert(result.isSome(), true)
        @Assert(ri.pattern, "/Users/{UserID}")
        @Assert(ri.getParams().get("UserID").getOrThrow(), "AbCdEf")

        let ri2 = RouteInfo<Int64>()
        let result2 = node.findRouteHandler(ri2, "GET", "/USERS/PROFILE")
        @Assert(result2.isSome(), true)
        @Assert(ri2.handler.getOrThrow(), 2)
    }

    /**
     * 测试大小写不敏感正则匹配 - 验证正则语义（如 \D）不会被小写化破坏
     */
    @TestCase
    public func testCaseInsensitiveRegexMatching() {
        let node = TreeNode<Int64>(NT_STATIC, b'\0', "", caseInsensitive: true)
        addPath(node, "/value/{v:\\D+}", 1)

        let ri = RouteInfo<Int64>()
        let result = node.findRouteHandler(ri, "GET", "/VALUE/AbC")
        @Assert(result.isSome(), true)
        @Assert(ri.getParams().get("v").getOrThrow(), "AbC")

        let ri2 = RouteInfo<Int64>()
        let result2 = node.findRouteHandler(ri2, "GET", "/value/123")
        @Assert(result2.isNone(), true)
    }
}
