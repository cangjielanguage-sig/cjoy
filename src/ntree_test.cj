/*
 * Copyright (c) lanlingx 2024-2024. All rights resvered.
 */

package cjoy

import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

@Test
public class TreeNodeTestCaseSuit {
    private func addPath(tree: TreeNode<Int64>, pattern: String, hander: Int64) {
        let node = tree.addRoute("GET", pattern, hander)
    }

    private func addPath(tree: TreeNode<Int64>, method: String, pattern: String, hander: Int64) {
        let node = tree.addRoute(method, pattern, hander)
    }

    private func testPath(tree: TreeNode<Int64>, path: String, expectPath: String, expectedParams: HashMap<String, String>, handler!: Int64=1) {
        let ri: RouteInfo = RouteInfo()
        let (node, h) = tree.findRouteHandler(ri, "GET", path)
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

        if (h.isNone()) {
            @Fail("path ${path} returned node without handler")
            return
        } else {
            if (handler != h.getOrThrow()) {
                @Fail("not math handler for path ${path}, expected ${handler}, actual=${h.getOrThrow()}")
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
                xparams.put(ri.routeParamKeys[i], ri.routeParamValues[i])
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
        let node = TreeNode<Int64>(NT_STATIC, b'/', "")
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

        eprintln(node.dumpTree())
        //@Fail("xxxx")

        //testPath(node, "/", "/", HashMap(), handler:1)
        //testPath(node, "/favicon.ico", "/favicon.ico", HashMap(), handler:1)
    }

    @TestCase
    public func testTreeMoar() {
        let node = TreeNode<Int64>(NT_STATIC, b'\0', "")

        addPath(node, "/articlefun", 5)
        addPath(node, "/articles/{id}", 1)
        addPath(node, "DELETE", "/articles/{slug}", 8)
        addPath(node, "/articles/search", 1)
        addPath(node, "/articles/{id}:delete", 8)
        addPath(node, "/articles/{iidd}!sup", 4)
        addPath(node, "/articles/{id}:{op}", 3)
        addPath(node, "/articles/{id}:{op}", 2)
        addPath(node, "/articles/{slug:^[a-z]+}/posts", 1)
        addPath(node, "/articles/{id}/posts/{pid}", 6)
        addPath(node, "/articles/{id}/posts/{month}/{day}/{year}/{slug}", 7)
        addPath(node, "/articles/{id}.json", 10)
        addPath(node, "/articles/{id}/data.json", 11)
        addPath(node, "/articles/files/{file}.{ext}", 12)
        addPath(node, "/articles/me", 13)
    }

    @TestCase
    public func testTreeRegexp() {
        let node = TreeNode<Int64>(NT_STATIC, b'\0', "")

        addPath(node, "/articles/{rid:^[0-9]{5,6}}", 7)
        addPath(node, "/articles/{zid:^0[0-9]+}", 3)
        addPath(node, "/articles/{name:^@[a-z]+}/posts", 4)
        addPath(node, "/articles/{op:^[0-9]+}/run", 5)
        addPath(node, "/articles/{id:^[0-9]+}", 1)
        addPath(node, "/articles/{id:^[1-9]+}-{aux}", 6)
        addPath(node, "/articles/{slug}", 2)
    }

    @TestCase
    public func testTreeRegexpRecursive() {
        let node = TreeNode<Int64>(NT_STATIC, b'\0', "")

        addPath(node, "/one/{firstId:[a-z0-9-]+}/{secondId:[a-z0-9-]+}/first", 1)
        addPath(node, "/one/{firstId:[a-z0-9-_]+}/{secondId:[a-z0-9-_]+}/second", 2)
    }

    @TestCase
    public func testTreeRegexpMatchWholeParam() {
        let node = TreeNode<Int64>(NT_STATIC, b'\0', "")

        addPath(node, "/{id:[0-9]+}", 1)
        addPath(node, "/{x:.+}/foo", 1)
        addPath(node, "/{param:[0-9]*}/test", 1)
    }
}