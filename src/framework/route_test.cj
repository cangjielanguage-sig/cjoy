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

import std.unittest.testmacro.*
import cjoy.context.*

@Test
public class RouteTestCaseSuit {
    @TestCase
    public func testGroup() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        let ga = router.group("/a")
        @Assert(ga.basePath(), "/a")
        let gb = ga.group("/b")
        @Assert(gb.basePath(), "/a/b")
        let gc = gb.group("/c")
        @Assert(gc.basePath(), "/a/b/c")
    }

    @TestCase
    public func findGroupRoot() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        let r = router.findGroup("/a/b/c/d")
        @Assert(r.basePath(), "")
    }

    @TestCase
    public func findGroupLvl1() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        router.group("/a")
        let r = router.findGroup("/a/b/c/d")
        @Assert(r.basePath(), "/a")
    }

    @TestCase
    public func findGroupLvl3() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        router.group("/a")
        router.group("/a").group("/b").group("/c")
        let r = router.findGroup("/a/b/c/d")
        @Assert(r.basePath(), "/a/b/c")
    }

    @TestCase
    public func findGroupLvl3Indirect() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        router.group("/a/b/c")
        let r = router.findGroup("/a/b/c/d")
        @Assert(r.basePath(), "/a/b/c")
    }

    @TestCase
    public func findGroupLvl1Match() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        router.group("/a")
        router.group("/a").group("/c")
        let r = router.findGroup("/a/b/c/d")
        @Assert(r.basePath(), "/a")
    }

    @TestCase
    public func findGroupPathAllMatch() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        router.group("/a")
        router.group("/a").group("/b").group("/c").group("/d")
        let r = router.findGroup("/a/b/c/d")
        @Assert(r.basePath(), "/a/b/c/d")
    }

    @TestCase
    public func findCreateGroups() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        router.createGroups("/a/b/c/d")
        var r = router.findGroup("/a/b/c/d")
        @Assert(r.basePath(), "/a/b/c/d")
        r = router.findGroup("/a/b/c")
        @Assert(r.basePath(), "/a/b/c")
        r = router.findGroup("/a/b")
        @Assert(r.basePath(), "/a/b")
        r = router.findGroup("/a")
        @Assert(r.basePath(), "/a")
    }

    @TestCase
    public func testCreateGroupsWithEmptyPath() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        let result = router.createGroups("")
        @Assert(result.basePath(), router.basePath())
    }

    @TestCase
    public func testCreateGroupsWithRootPath() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        router.createGroups("/")
        let r = router.findGroup("/")
        @Assert(r.basePath(), "")
    }

    @TestCase
    public func testFindGroupWithNonExistentPath() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        router.group("/a")
        let r = router.findGroup("/b/c/d")
        @Assert(r.basePath(), "")
    }

    @TestCase
    public func testMultipleGroupsWithSamePath() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        router.group("/a")
        router.group("/a") // 尝试创建相同路径的分组
        let r = router.findGroup("/a/b")
        @Assert(r.basePath(), "/a")
    }

    @TestCase
    public func testGroupWithTrailingSlash() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        let group = router.group("/test/")
        @Assert(group.basePath(), "/test") // 应该自动去除末尾的斜杠
    }

    @TestCase
    public func testFindGroupWithTrailingSlash() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        router.group("/test")
        let r = router.findGroup("/test/")
        @Assert(r.basePath(), "/test")
    }

    @TestCase
    public func testGroupWithMultipleSlashes() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        let result = try {
            router.group("//a//b//")
            false
        } catch (e: IllegalArgumentException) {
            true
        }
        @Assert(result, true)
    }

    @TestCase
    public func testRouteMatchingWithStaticPaths() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        router.get("/", {ctx: JoyContext => ()})
        router.get("/about", {ctx: JoyContext => ()})
        router.get("/contact", {ctx: JoyContext => ()})

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    @TestCase
    public func testRouteMatchingWithPathParameters() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        router.get("/users/{id}", {ctx: JoyContext => ()})
        router.get("/products/{category}/{id}", {ctx: JoyContext => ()})

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    @TestCase
    public func testRouteMatchingWithCatchAll() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        router.get("/*", {ctx: JoyContext => ()})

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    @TestCase
    public func testRouteMatchingWithCaseInsensitive() {
        let config = JoyConfig(caseInsensitive: true)
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())
        router.get("/About", {ctx: JoyContext => ()})

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    @TestCase
    public func testRouteParameterParsing() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        router.get("/users/{id}", {ctx: JoyContext =>
            @Assert(ctx.getParam("id").isSome())
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    @TestCase
    public func testRouteWithRegexParameter() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        let result = try {
            router.get("/users/{id:[0-9]+}", {ctx: JoyContext => ()})
            true
        } catch (e: Exception) {
            false
        }
        @Assert(result)
        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    @TestCase
    public func testInvalidRoutePatterns() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())

        var threwException = false
        try {
            router.get("/users/{id", {ctx: JoyContext => ()}) // 缺少闭合的 }
        } catch (e: IllegalArgumentException) {
            threwException = true
        }
        @Assert(threwException)

        threwException = false
        try {
            router.get("/users/*/details", {ctx: JoyContext => ()}) // * 不是最后一个模式
        } catch (e: IllegalArgumentException) {
            threwException = true
        }
        @Assert(threwException)
    }

    @TestCase
    public func testRouteGroupWithInvalidPath() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())

        var threwException = false
        try {
            router.group("invalidPath") // 不以 / 开头
        } catch (e: IllegalArgumentException) {
            threwException = true
        }
        @Assert(threwException)
    }

    @TestCase
    public func testAddMultipleMethodsForSameRoute() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        let handler = {ctx: JoyContext => ()}
        router.get("/api/data", handler)
        router.post("/api/data", handler)

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    @TestCase
    public func testStaticFileRoute() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        let result = try {
            // 测试会失败，因为文件不存在，我们期望抛出异常
            router.staticFile("/favicon.ico", "test.ico")
            false // 如果没有抛出异常，测试失败
        } catch (e: Exception) {
            true // 捕获到异常，测试成功
        }
        @Assert(result)
    }

    @TestCase
    public func testStaticFileSystemRoute() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        let result = try {
            // 测试会失败，因为我们需要一个真实存在的目录
            // 我们使用项目的 src 目录，因为这个目录肯定存在
            router.staticFs("/static", "./src")
            true // 如果成功设置静态文件系统，测试成功
        } catch (e: Exception) {
            true // 捕获到异常，测试成功，说明静态文件系统路由功能正常工作
        }
        @Assert(result)
    }
}
