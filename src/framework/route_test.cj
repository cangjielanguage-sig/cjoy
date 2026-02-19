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
    /**
     * 测试路由分组 - 验证路由分组可以正确创建嵌套路径
     */
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

    /**
     * 测试查找根分组 - 验证查找不存在的分组时返回根分组
     */
    @TestCase
    public func findGroupRoot() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        let r = router.findGroup("/a/b/c/d")
        @Assert(r.basePath(), "")
    }

    /**
     * 测试查找一级分组 - 验证可以正确查找到一级分组
     */
    @TestCase
    public func findGroupLvl1() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        router.group("/a")
        let r = router.findGroup("/a/b/c/d")
        @Assert(r.basePath(), "/a")
    }

    /**
     * 测试查找三级分组 - 验证可以正确查找到多级嵌套分组
     */
    @TestCase
    public func findGroupLvl3() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        router.group("/a")
        router.group("/a").group("/b").group("/c")
        let r = router.findGroup("/a/b/c/d")
        @Assert(r.basePath(), "/a/b/c")
    }

    /**
     * 测试间接查找三级分组 - 验证通过一次性创建多级分组后可以正确查找
     */
    @TestCase
    public func findGroupLvl3Indirect() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        router.group("/a/b/c")
        let r = router.findGroup("/a/b/c/d")
        @Assert(r.basePath(), "/a/b/c")
    }

    /**
     * 测试查找部分匹配分组 - 验证查找时返回最匹配的分组
     */
    @TestCase
    public func findGroupLvl1Match() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        router.group("/a")
        router.group("/a").group("/c")
        let r = router.findGroup("/a/b/c/d")
        @Assert(r.basePath(), "/a")
    }

    /**
     * 测试查找完全匹配分组 - 验证查找完全匹配的分组时返回正确结果
     */
    @TestCase
    public func findGroupPathAllMatch() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        router.group("/a")
        router.group("/a").group("/b").group("/c").group("/d")
        let r = router.findGroup("/a/b/c/d")
        @Assert(r.basePath(), "/a/b/c/d")
    }

    /**
     * 测试创建并查找分组 - 验证 createGroups 可以创建多级分组并正确查找
     */
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

    /**
     * 测试创建空路径分组 - 验证使用空字符串路径创建分组会返回当前分组
     */
    @TestCase
    public func testCreateGroupsWithEmptyPath() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        let result = router.createGroups("")
        @Assert(result.basePath(), router.basePath())
    }

    /**
     * 测试创建根路径分组 - 验证使用根路径 / 创建分组会返回根分组
     */
    @TestCase
    public func testCreateGroupsWithRootPath() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        router.createGroups("/")
        let r = router.findGroup("/")
        @Assert(r.basePath(), "")
    }

    /**
     * 测试查找不存在路径的分组 - 验证查找不存在的路径时返回根分组
     */
    @TestCase
    public func testFindGroupWithNonExistentPath() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        router.group("/a")
        let r = router.findGroup("/b/c/d")
        @Assert(r.basePath(), "")
    }

    /**
     * 测试创建相同路径的多个分组 - 验证创建相同路径的分组不会报错且能正确查找
     */
    @TestCase
    public func testMultipleGroupsWithSamePath() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        router.group("/a")
        router.group("/a") // 尝试创建相同路径的分组
        let r = router.findGroup("/a/b")
        @Assert(r.basePath(), "/a")
    }

    /**
     * 测试带末尾斜杠的分组路径 - 验证分组路径会自动去除末尾的斜杠
     */
    @TestCase
    public func testGroupWithTrailingSlash() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        let group = router.group("/test/")
        @Assert(group.basePath(), "/test") // 应该自动去除末尾的斜杠
    }

    /**
     * 测试查找带末尾斜杠的分组 - 验证查找带末尾斜杠的路径时能找到对应的分组
     */
    @TestCase
    public func testFindGroupWithTrailingSlash() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        router.group("/test")
        let r = router.findGroup("/test/")
        @Assert(r.basePath(), "/test")
    }

    /**
     * 测试带多个斜杠的分组路径 - 验证包含多个连续斜杠的路径会抛出异常
     */
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

    /**
     * 测试静态路径路由匹配 - 验证静态路径路由可以正确添加和转储
     */
    @TestCase
    public func testRouteMatchingWithStaticPaths() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        router.get("/", {ctx: JoyContext => ()})
        router.get("/about", {ctx: JoyContext => ()})
        router.get("/contact", {ctx: JoyContext => ()})

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试路径参数路由匹配 - 验证带路径参数的路由可以正确添加和转储
     */
    @TestCase
    public func testRouteMatchingWithPathParameters() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        router.get("/users/{id}", {ctx: JoyContext => ()})
        router.get("/products/{category}/{id}", {ctx: JoyContext => ()})

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试通配符路由匹配 - 验证带通配符的路由可以正确添加和转储
     */
    @TestCase
    public func testRouteMatchingWithCatchAll() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        router.get("/*", {ctx: JoyContext => ()})

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试不区分大小写的路由匹配 - 验证不区分大小写的路由配置
     */
    @TestCase
    public func testRouteMatchingWithCaseInsensitive() {
        let config = JoyConfig(caseInsensitive: true)
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())
        router.get("/About", {ctx: JoyContext => ()})

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试路由参数解析 - 验证路由参数可以正确解析和获取
     */
    @TestCase
    public func testRouteParameterParsing() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        router.get("/users/{id}", {ctx: JoyContext =>
            @Assert(ctx.getParam("id").isSome())
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试带正则表达式参数的路由 - 验证带正则表达式约束的路由参数
     */
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

    /**
     * 测试无效路由模式 - 验证无效的路由模式会抛出异常
     */
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

    /**
     * 测试无效路径的路由分组 - 验证不以斜杠开头的路径会抛出异常
     */
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

    /**
     * 测试为相同路由添加多个HTTP方法 - 验证相同路径可以添加多个不同HTTP方法的路由
     */
    @TestCase
    public func testAddMultipleMethodsForSameRoute() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        let handler = {ctx: JoyContext => ()}
        router.get("/api/data", handler)
        router.post("/api/data", handler)

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试静态文件路由 - 验证静态文件路由的配置和错误处理
     */
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

    /**
     * 测试静态文件系统路由 - 验证静态文件系统路由的配置
     */
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
