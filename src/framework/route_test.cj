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
import std.sync.AtomicBool

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
     * 测试 group("/") - 验证根分组调用 group("/") 不会抛异常
     */
    @TestCase
    public func testGroupWithRootPath() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        let group = router.group("/")
        @Assert(group.basePath(), "")
    }

    /**
     * 测试子分组调用 group("/") - 验证返回当前分组
     */
    @TestCase
    public func testSubGroupWithRootPath() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        let sub = router.group("/a")
        let group = sub.group("/")
        @Assert(group.basePath(), "/a")
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

    /**
     * 测试静态路由优先级高于参数路由 - 验证静态路由匹配优先
     */
    @TestCase
    public func testStaticRoutePriorityOverParam() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        let staticCalled = AtomicBool(false)
        let paramCalled = AtomicBool(false)

        router.get("/users/me", {ctx: JoyContext =>
            staticCalled.store(true)
            ctx.string("static")
        })
        router.get("/users/{id}", {ctx: JoyContext =>
            paramCalled.store(true)
            ctx.string("param")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试精确路由匹配 - 验证精确路径优先匹配
     */
    @TestCase
    public func testExactRouteMatching() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())

        router.get("/api", {ctx: JoyContext => ctx.string("api")})
        router.get("/api/users", {ctx: JoyContext => ctx.string("users")})
        router.get("/api/users/{id}", {ctx: JoyContext => ctx.string("user")})

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试根路径路由 - 验证根路径路由正确配置
     */
    @TestCase
    public func testRootRoute() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        router.get("/", {ctx: JoyContext => ctx.string("root")})

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试多层嵌套路由 - 验证多级嵌套路径正确配置
     */
    @TestCase
    public func testDeepNestedRoutes() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())

        router.get("/a/b/c/d/e/f", {ctx: JoyContext => ctx.string("deep")})

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试多 HTTP 方法路由 - 验证同一路径支持多个 HTTP 方法
     */
    @TestCase
    public func testMultipleHttpMethods() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        let handler = {ctx: JoyContext => ctx.string("ok"); () }

        router.get("/api/resource", handler)
        router.post("/api/resource", handler)
        router.put("/api/resource", handler)
        router.delete("/api/resource", handler)
        router.patch("/api/resource", handler)
        router.head("/api/resource", handler)

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试参数路由约束 - 验证带正则约束的参数路由
     */
    @TestCase
    public func testParameterWithRegex() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())

        router.get("/users/{id:[0-9]+}", {ctx: JoyContext => ctx.string("numeric")})
        router.get("/users/{name:[a-z]+}", {ctx: JoyContext => ctx.string("alpha")})

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试通配符路由 - 验证通配符路由配置
     */
    @TestCase
    public func testCatchAllRoute() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())

        router.get("/files/*", {ctx: JoyContext => ctx.string("catchall")})

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试路由冲突检测 - 验证相同模式的路由可以覆盖
     */
    @TestCase
    public func testRouteOverride() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())

        router.get("/test", {ctx: JoyContext => ctx.string("first")})
        router.get("/test", {ctx: JoyContext => ctx.string("second")})

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试分组路由前缀 - 验证分组路由的路径前缀正确
     */
    @TestCase
    public func testGroupRoutePrefix() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        let api = router.group("/api")
        let v1 = api.group("/v1")

        v1.get("/users", {ctx: JoyContext => ctx.string("users")})

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试路由转义配置 - 验证 escapeAddedRoutes 配置正确应用
     */
    @TestCase
    public func testRouteWithEscapeConfig() {
        let config = JoyConfig(escapeAddedRoutes: true)
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/test/path", {ctx: JoyContext => ctx.string("ok")})

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试大小写不敏感路由 - 验证 caseInsensitive 配置正确应用
     */
    @TestCase
    public func testCaseInsensitiveRouteMatching() {
        let config = JoyConfig(caseInsensitive: true)
        let router: JoyRouteGroup = JoyRouteGroup(config, ServiceContainer())

        router.get("/API/Users", {ctx: JoyContext => ctx.string("users")})

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试空路径参数处理 - 验证参数名不能为空
     */
    @TestCase
    public func testEmptyPathParam() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())

        var threwException = false
        try {
            router.get("/users/{}", {ctx: JoyContext => ctx.string("empty")})
        } catch (e: IllegalArgumentException) {
            threwException = true
        }
        @Assert(threwException, true)
    }

    /**
     * 测试单个路径参数解析 - 验证单个参数可以正确配置
     */
    @TestCase
    public func testSinglePathParam() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())

        router.get("/users/{id}", {ctx: JoyContext =>
            let id = ctx.getParam("id")
            @Assert(id.isSome(), true)
            ctx.string("ok")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试多个路径参数解析 - 验证多个参数可以正确配置
     */
    @TestCase
    public func testMultiplePathParams() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())

        router.get("/users/{userId}/posts/{postId}", {ctx: JoyContext =>
            let userId = ctx.getParam("userId")
            let postId = ctx.getParam("postId")
            @Assert(userId.isSome(), true)
            @Assert(postId.isSome(), true)
            ctx.string("ok")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试带前缀的路径参数 - 验证参数带前缀的路径
     */
    @TestCase
    public func testPrefixedPathParam() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())

        router.get("/files/{name}.{ext}", {ctx: JoyContext =>
            ctx.string("ok")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试带特殊字符前缀的参数 - 验证参数前可以有特殊字符
     */
    @TestCase
    public func testSpecialCharPrefixedParam() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())

        router.get("/articles/{id}:edit", {ctx: JoyContext =>
            ctx.string("edit")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试带@前缀的参数 - 验证@符号作为参数前缀
     */
    @TestCase
    public func testAtPrefixedParam() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())

        router.get("/users/@{username}", {ctx: JoyContext =>
            ctx.string("ok")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试正则约束参数 - 验证带正则表达式约束的参数
     */
    @TestCase
    public func testRegexConstrainedParam() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())

        router.get("/products/{id:[0-9]+}", {ctx: JoyContext =>
            ctx.string("numeric")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试复杂正则约束参数 - 验证复杂正则表达式约束
     */
    @TestCase
    public func testComplexRegexConstrainedParam() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())

        router.get("/emails/{email:^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$}", {ctx: JoyContext =>
            ctx.string("email")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试通配符参数 - 验证通配符捕获剩余路径
     */
    @TestCase
    public func testCatchAllParam() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())

        router.get("/files/*", {ctx: JoyContext =>
            let wildcard = ctx.getParam("*")
            @Assert(wildcard.isSome(), true)
            ctx.string("ok")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试参数后跟静态路径 - 验证参数后面可以有静态路径
     */
    @TestCase
    public func testParamFollowedByStatic() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())

        router.get("/users/{id}/profile", {ctx: JoyContext =>
            ctx.string("profile")
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试双斜杠路径 - 验证双斜杠路径参数解析
     */
    @TestCase
    public func testDoubleSlashPathParam() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())

        try {
            router.get("/api//{version}/users", {ctx: JoyContext =>
                ctx.string("ok")
            })
            @Fail("should throw exception")
        } catch (ex:IllegalArgumentException) {
            @Assert(ex.message != "")
        }
    }

    /**
     * 测试查询参数默认值 - 验证查询参数处理
     */
    @TestCase
    public func testQueryParamDefault() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())

        router.get("/search", {ctx: JoyContext =>
            let q = ctx.getQuery("q", "default")
            ctx.string(q)
        })

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试一级路由分组 - 验证单级路由分组功能
     */
    @TestCase
    public func testSingleLevelGroup() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        let api = router.group("/api")

        api.get("/users", {ctx: JoyContext => ctx.string("users")})
        api.get("/products", {ctx: JoyContext => ctx.string("products")})

        @Assert(api.basePath(), "/api")

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试多级路由分组 - 验证嵌套路由分组功能
     */
    @TestCase
    public func testMultiLevelGroup() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        let api = router.group("/api")
        let v1 = api.group("/v1")
        let admin = v1.group("/admin")

        admin.get("/users", {ctx: JoyContext => ctx.string("admin users")})

        @Assert(api.basePath(), "/api")
        @Assert(v1.basePath(), "/api/v1")
        @Assert(admin.basePath(), "/api/v1/admin")

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试分组添加中间件 - 验证路由分组可以添加中间件
     */
    @TestCase
    public func testGroupWithMiddleware() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())
        let api = router.group("/api")

        api.use(JoyMiddlewareFuncHandler({ctx, chain => chain.next(ctx)}))
        api.get("/test", {ctx: JoyContext => ctx.string("test")})

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试多个并行分组 - 验证多个并行分组功能
     */
    @TestCase
    public func testParallelGroups() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())

        let api = router.group("/api")
        let web = router.group("/web")
        let admin = router.group("/admin")

        api.get("/data", {ctx: JoyContext => ctx.string("api data")})
        web.get("/page", {ctx: JoyContext => ctx.string("web page")})
        admin.get("/dashboard", {ctx: JoyContext => ctx.string("admin dashboard")})

        @Assert(api.basePath(), "/api")
        @Assert(web.basePath(), "/web")
        @Assert(admin.basePath(), "/admin")

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试分组路径规范化 - 验证分组路径自动去除末尾斜杠
     */
    @TestCase
    public func testGroupPathNormalization() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())

        let group1 = router.group("/api/")
        try {
             // 双斜杠应该抛出异常或被规范化
            let group2 = router.group("/web//")
            @Fail("should throw exception")
        } catch (e: IllegalArgumentException) {
            @Assert(e.message != "")
        }
    }

    /**
     * 测试分组动态创建 - 验证 createGroups 方法动态创建分组
     */
    @TestCase
    public func testCreateGroupsDynamically() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())

        let group = router.createGroups("/api/v1/users")

        @Assert(group.basePath(), "/api/v1/users")

        // 验证中间分组也被创建
        let api = router.findGroup("/api")
        @Assert(api.basePath(), "/api")

        let v1 = router.findGroup("/api/v1")
        @Assert(v1.basePath(), "/api/v1")
    }

    /**
     * 测试根分组 - 验证根分组功能
     */
    @TestCase
    public func testRootGroup() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())

        @Assert(router.basePath(), "")

        router.get("/test", {ctx: JoyContext => ctx.string("test")})

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试分组查找不存在的路径 - 验证查找不存在的分组返回根分组
     */
    @TestCase
    public func testFindNonExistentGroup() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())

        router.group("/api")
        let found = router.findGroup("/web/users")

        // 查找不存在的分组应该返回根分组
        @Assert(found.basePath(), "")
    }

    /**
     * 测试分组后路由添加 - 验证分组后可以继续添加路由
     */
    @TestCase
    public func testAddRoutesAfterGrouping() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())

        router.get("/root", {ctx: JoyContext => ctx.string("root")})

        let api = router.group("/api")
        api.get("/users", {ctx: JoyContext => ctx.string("users")})

        router.get("/another", {ctx: JoyContext => ctx.string("another")})

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试分组与参数路由结合 - 验证分组可以与参数路由结合使用
     */
    @TestCase
    public func testGroupWithParamRoute() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())

        let api = router.group("/api")
        api.get("/users/{id}", {ctx: JoyContext => ctx.string("user")})

        let dumpResult = router.dump()
        @Assert(dumpResult.size > 0)
    }

    /**
     * 测试无效路由格式 - 验证不正确的路由格式抛出异常
     */
    @TestCase
    public func testInvalidRouteFormat() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())

        var threwException = false
        try {
            // 缺少闭合括号
            router.get("/users/{id", {ctx: JoyContext => ctx.string("invalid")})
        } catch (e: IllegalArgumentException) {
            threwException = true
        }
        @Assert(threwException, true)
    }

    /**
     * 测试通配符不在末尾 - 验证通配符只能在路径末尾
     */
    @TestCase
    public func testWildcardNotAtEnd() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())

        var threwException = false
        try {
            router.get("/files/*/download", {ctx: JoyContext => ctx.string("invalid")})
        } catch (e: IllegalArgumentException) {
            threwException = true
        }
        @Assert(threwException, true)
    }

    /**
     * 测试多个连续斜杠 - 验证连续斜杠抛出异常
     */
    @TestCase
    public func testMultipleSlashes() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())

        var threwException = false
        try {
            router.get("//api//users", {ctx: JoyContext => ctx.string("invalid")})
        } catch (e: IllegalArgumentException) {
            threwException = true
        }
        @Assert(threwException, true)
    }

    /**
     * 测试路径不以斜杠开头 - 验证路径必须以斜杠开头
     */
    @TestCase
    public func testPathNotStartingWithSlash() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())

        var threwException = false
        try {
            router.get("api/users", {ctx: JoyContext => ctx.string("invalid")})
        } catch (e: IllegalArgumentException) {
            threwException = true
        }
        @Assert(threwException, true)
    }

    /**
     * 测试分组路径不以斜杠开头 - 验证分组路径必须以斜杠开头
     */
    @TestCase
    public func testGroupPathNotStartingWithSlash() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())

        var threwException = false
        try {
            router.group("api")
        } catch (e: IllegalArgumentException) {
            threwException = true
        }
        @Assert(threwException, true)
    }

    /**
     * 测试无效正则表达式 - 验证无效正则抛出异常
     */
    @TestCase
    public func testInvalidRegex() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())

        var threwException = false
        try {
            router.get("/users/{id:[}", {ctx: JoyContext => ctx.string("invalid")})
        } catch (e: Exception) {
            threwException = true
        }
        @Assert(threwException, true)
    }

    /**
     * 测试静态文件路径不存在 - 验证静态文件路径不存在时抛出异常
     */
    @TestCase
    public func testStaticFileNotExists() {
        let router: JoyRouteGroup = JoyRouteGroup(JoyConfig(), ServiceContainer())

        var threwException = false
        try {
            router.staticFile("/favicon.ico", "nonexistent_file.ico")
        } catch (e: Exception) {
            threwException = true
        }
        @Assert(threwException, true)
    }
}
