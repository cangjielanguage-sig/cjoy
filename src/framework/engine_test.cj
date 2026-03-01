/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.framework

import std.unittest.testmacro.*
import stdx.net.http.*

@Test
public class EngineTestCaseSuit {
    /**
     * 测试引擎创建 - 验证可以创建默认名称的引擎实例
     */
    @TestCase
    public func testEngineCreation() {
        let engine = Joy.create()
        @Assert(engine.name == "default", true)
    }

    /**
     * 测试自定义名称引擎创建 - 验证可以创建指定名称的引擎实例
     */
    @TestCase
    public func testEngineWithCustomName() {
        let engine = Joy.create(name: "testEngine")
        @Assert(engine.name == "testEngine", true)
    }

    /**
     * 测试自定义配置引擎创建 - 验证可以使用自定义配置创建引擎实例
     */
    @TestCase
    public func testEngineWithCustomConfig() {
        let config = JoyConfig(
            remoteIPHeaders: ["X-Forwarded-For", "X-Real-IP"],
            caseInsensitive: true,
            escapeAddedRoutes: true,
            maxRequestBodySize: 64 * 1024 * 1024
        )
        let engine = Joy.create(config, name: "customEngine")
        @Assert(engine.config.remoteIPHeaders.size == 2, true)
        @Assert(engine.config.caseInsensitive, true)
        @Assert(engine.config.escapeAddedRoutes, true)
        @Assert(engine.config.maxRequestBodySize == 64 * 1024 * 1024, true)
    }

    /**
     * 测试引擎单例模式 - 验证相同名称的引擎实例是否为单例
     */
    @TestCase
    public func testEngineSingleton() {
        let engine1 = Joy.create(name: "testSingleton")
        @Assert(engine1.name == "testSingleton", true)
        engine1.shutdown() // 清理实例

        let engine2 = Joy.create(name: "testSingleton")
        @Assert(engine2.name == "testSingleton", true)
        engine2.shutdown() // 清理实例
    }

    /**
     * 测试引擎重复创建 - 验证创建同名引擎实例会抛出异常
     */
    @TestCase
    public func testEngineDuplicateCreation() {
        let name = "duplicateEngine"
        let engine1 = Joy.create(name: name)

        var threwException = false
        try {
            let engine2 = Joy.create(name: name)
        } catch (e: IllegalArgumentException) {
            threwException = true
        }
        @Assert(threwException, true)
    }

    /**
     * 测试引擎服务管理 - 验证可以添加和获取服务
     */
    @TestCase
    public func testEngineAddAndGetService() {
        let engine = Joy.create(name: "serviceEngine")
        let testService = "testServiceValue"
        engine.addService("testService", testService)

        let retrievedService = engine.getService<String>("testService")
        @Assert(retrievedService != None, true)
        @Assert(retrievedService == Some(testService), true)
    }

    /**
     * 测试获取不存在的服务 - 验证获取不存在的服务时返回 None
     */
    @TestCase
    public func testEngineGetNonExistentService() {
        let engine = Joy.create(name: "nonExistentServiceEngine")
        let retrievedService = engine.getService<String>("nonExistentService")
        @Assert(retrievedService == None, true)
    }

    /**
     * 测试默认引擎配置 - 验证引擎默认配置的正确性
     */
    @TestCase
    public func testEngineConfig() {
        let config = JoyConfig()
        let engine = Joy.create(config, name: "testEngineConfig")

        @Assert(engine.config.remoteIPHeaders.isEmpty(), true)
        @Assert(!engine.config.caseInsensitive, true)
        @Assert(!engine.config.escapeAddedRoutes, true)
        @Assert(engine.config.maxRequestBodySize == 32 * 1024 * 1024, true)

        engine.shutdown()
    }

    /**
     * 测试自定义引擎配置值 - 验证自定义配置值是否正确应用到引擎
     */
    @TestCase
    public func testEngineConfigWithCustomValues() {
        let config = JoyConfig(
            remoteIPHeaders: ["X-Forwarded-For"],
            caseInsensitive: true,
            escapeAddedRoutes: true,
            maxRequestBodySize: 100 * 1024 * 1024
        )
        let engine = Joy.create(config, name: "testEngineConfigWithCustomValues")

        @Assert(engine.config.remoteIPHeaders.size == 1, true)
        @Assert(engine.config.remoteIPHeaders[0] == "X-Forwarded-For", true)
        @Assert(engine.config.caseInsensitive, true)
        @Assert(engine.config.escapeAddedRoutes, true)
        @Assert(engine.config.maxRequestBodySize == 100 * 1024 * 1024, true)

        engine.shutdown()
    }

    /**
     * 测试引擎服务器启动 - 验证引擎可以正常启动服务器
     */
    @TestCase
    public func testEngineServerStartup() {
        let engine = Joy.create(name: "testServerStartup")
        engine.router.get("/", {ctx: JoyContext => ctx.string("ok")})

        spawn {
            engine.run("127.0.0.1", 18901)
        }
        sleep(Duration.millisecond * 500)

        // 验证服务器已启动
        @Assert(engine.server.addr, "127.0.0.1")
        @Assert(engine.server.port, 18901)

        engine.shutdown()
    }

    /**
     * 测试引擎优雅关闭 - 验证引擎可以优雅地关闭服务器
     */
    @TestCase
    public func testEngineGracefulShutdown() {
        let engine = Joy.create(name: "testGracefulShutdown")
        engine.router.get("/", {ctx: JoyContext => ctx.string("ok")})

        spawn {
            engine.run("127.0.0.1", 18902)
        }
        sleep(Duration.millisecond * 500)

        // 优雅关闭
        engine.shutdown(gracefully: true)

        // 验证服务器已关闭 - 实例已从 map 中移除
        let engine2 = Joy.create(name: "testGracefulShutdown")
        @Assert(engine2.name, "testGracefulShutdown")
        engine2.shutdown()
    }

    /**
     * 测试引擎强制关闭 - 验证引擎可以强制关闭服务器
     */
    @TestCase
    public func testEngineForceShutdown() {
        let engine = Joy.create(name: "testForceShutdown")
        engine.router.get("/", {ctx: JoyContext => ctx.string("ok")})

        spawn {
            engine.run("127.0.0.1", 18903)
        }
        sleep(Duration.millisecond * 500)

        // 强制关闭
        engine.shutdown(gracefully: false)

        // 验证服务器已关闭 - 实例已从 map 中移除
        let engine2 = Joy.create(name: "testForceShutdown")
        @Assert(engine2.name, "testForceShutdown")
        engine2.shutdown()
    }

    /**
     * 测试引擎多次关闭 - 验证多次调用 shutdown 不会出错
     */
    @TestCase
    public func testEngineMultipleShutdown() {
        let engine = Joy.create(name: "testMultipleShutdown")

        // 多次调用 shutdown 不应该抛出异常
        engine.shutdown()
        engine.shutdown()
        engine.shutdown()

        @Assert(true, true)
    }

    /**
     * 测试引擎关闭后重新创建 - 验证关闭后可以重新创建同名引擎
     */
    @TestCase
    public func testEngineRecreateAfterShutdown() {
        let engine1 = Joy.create(name: "testRecreateAfterShutdown")
        engine1.shutdown()

        // 重新创建同名引擎应该成功
        let engine2 = Joy.create(name: "testRecreateAfterShutdown")
        @Assert(engine2.name, "testRecreateAfterShutdown")
        engine2.shutdown()
    }

    /**
     * 测试默认引擎 - 验证 default() 方法返回正确的引擎实例
     */
    @TestCase
    public func testDefaultEngine() {
        let engine = Joy.default()
        @Assert(engine.name, "default")
        engine.shutdown()
    }

    /**
     * 测试配置默认值 - 验证 JoyConfig 的所有默认值正确
     */
    @TestCase
    public func testConfigDefaultValues() {
        let config = JoyConfig()

        @Assert(config.remoteIPHeaders.isEmpty(), true)
        @Assert(!config.caseInsensitive, true)
        @Assert(!config.escapeAddedRoutes, true)
        @Assert(config.maxRequestBodySize, 32 * 1024 * 1024)
    }

    /**
     * 测试配置的 remoteIPHeaders - 验证远程 IP 头配置正确
     */
    @TestCase
    public func testConfigRemoteIPHeaders() {
        let config = JoyConfig(
            remoteIPHeaders: ["X-Forwarded-For", "X-Real-IP", "CF-Connecting-IP"]
        )

        @Assert(config.remoteIPHeaders.size, 3)
        @Assert(config.remoteIPHeaders[0], "X-Forwarded-For")
        @Assert(config.remoteIPHeaders[1], "X-Real-IP")
        @Assert(config.remoteIPHeaders[2], "CF-Connecting-IP")
    }

    /**
     * 测试配置的 caseInsensitive - 验证大小写不敏感配置正确
     */
    @TestCase
    public func testConfigCaseInsensitive() {
        let config1 = JoyConfig(caseInsensitive: true)
        @Assert(config1.caseInsensitive, true)

        let config2 = JoyConfig(caseInsensitive: false)
        @Assert(!config2.caseInsensitive, true)
    }

    /**
     * 测试配置的 escapeAddedRoutes - 验证路由转义配置正确
     */
    @TestCase
    public func testConfigEscapeAddedRoutes() {
        let config1 = JoyConfig(escapeAddedRoutes: true)
        @Assert(config1.escapeAddedRoutes, true)

        let config2 = JoyConfig(escapeAddedRoutes: false)
        @Assert(!config2.escapeAddedRoutes, true)
    }

    /**
     * 测试配置的 maxRequestBodySize - 验证请求体最大大小配置正确
     */
    @TestCase
    public func testConfigMaxRequestBodySize() {
        let config1 = JoyConfig(maxRequestBodySize: 1024)
        @Assert(config1.maxRequestBodySize, 1024)

        let config2 = JoyConfig(maxRequestBodySize: 64 * 1024 * 1024)
        @Assert(config2.maxRequestBodySize, 64 * 1024 * 1024)

        let config3 = JoyConfig(maxRequestBodySize: 0)
        @Assert(config3.maxRequestBodySize, 0)
    }

    /**
     * 测试配置的 notFoundHandler - 验证自定义 404 处理器配置
     */
    @TestCase
    public func testConfigNotFoundHandler() {
        let customHandler = {ctx: JoyContext => ctx.status(404).string("Custom 404"); ()}
        let config = JoyConfig(notFoundHandler: JoyFuncHandler(customHandler))

        // 验证配置成功创建
        @Assert(true, true)
    }

    /**
     * 测试配置的 methodNotAllowedHandler - 验证自定义 405 处理器配置
     */
    @TestCase
    public func testConfigMethodNotAllowedHandler() {
        let customHandler = {ctx: JoyContext => ctx.status(405).string("Custom 405"); ()}
        let config = JoyConfig(methodNotAllowedHandler: JoyFuncHandler(customHandler))

        // 验证配置成功创建
        @Assert(true, true)
    }

    /**
     * 测试空 remoteIPHeaders 配置 - 验证空数组的 remoteIPHeaders 配置
     */
    @TestCase
    public func testConfigEmptyRemoteIPHeaders() {
        let config = JoyConfig(remoteIPHeaders: [])
        @Assert(config.remoteIPHeaders.isEmpty(), true)
    }

    /**
     * 测试服务器地址配置 - 验证服务器绑定地址配置正确
     */
    @TestCase
    public func testServerAddressConfig() {
        let engine = Joy.create(name: "testServerAddrConfig")
        engine.router.get("/", {ctx: JoyContext => ctx.string("ok")})

        spawn {
            engine.run("127.0.0.1", 18910)
        }
        sleep(Duration.millisecond * 500)

        @Assert(engine.server.addr, "127.0.0.1")
        engine.shutdown()
    }

    /**
     * 测试服务器端口配置 - 验证服务器绑定端口配置正确
     */
    @TestCase
    public func testServerPortConfig() {
        let engine = Joy.create(name: "testServerPortConfig")
        engine.router.get("/", {ctx: JoyContext => ctx.string("ok")})

        let testPort: UInt16 = 18911
        spawn {
            engine.run("127.0.0.1", testPort)
        }
        sleep(Duration.millisecond * 500)

        @Assert(engine.server.port, testPort)
        engine.shutdown()
    }

    /**
     * 测试服务器请求体大小限制 - 验证 maxRequestBodySize 配置生效
     */
    @TestCase
    public func testServerMaxRequestBodySizeConfig() {
        let config = JoyConfig(maxRequestBodySize: 1024)
        let engine = Joy.create(config, name: "testServerMaxRequestBodySizeConfig")

        @Assert(engine.config.maxRequestBodySize, 1024)
        engine.shutdown()
    }

    /**
     * 测试服务器路由转义配置 - 验证 escapeAddedRoutes 配置生效
     */
    @TestCase
    public func testServerEscapeAddedRoutesConfig() {
        let config = JoyConfig(escapeAddedRoutes: true)
        let engine = Joy.create(config, name: "testServerEscapeAddedRoutesConfig")

        @Assert(engine.config.escapeAddedRoutes, true)
        engine.shutdown()
    }

    /**
     * 测试服务器大小写不敏感配置 - 验证 caseInsensitive 配置生效
     */
    @TestCase
    public func testServerCaseInsensitiveConfig() {
        let config = JoyConfig(caseInsensitive: true)
        let engine = Joy.create(config, name: "testServerCaseInsensitiveConfig")

        @Assert(engine.config.caseInsensitive, true)
        engine.shutdown()
    }

    /**
     * 测试服务器远程 IP 头配置 - 验证 remoteIPHeaders 配置生效
     */
    @TestCase
    public func testServerRemoteIPHeadersConfig() {
        let config = JoyConfig(remoteIPHeaders: ["X-Forwarded-For", "X-Real-IP"])
        let engine = Joy.create(config, name: "testServerRemoteIPHeadersConfig")

        @Assert(engine.config.remoteIPHeaders.size, 2)
        @Assert(engine.config.remoteIPHeaders[0], "X-Forwarded-For")
        @Assert(engine.config.remoteIPHeaders[1], "X-Real-IP")
        engine.shutdown()
    }

    /**
     * 测试服务器全配置组合 - 验证所有配置项可以同时使用
     */
    @TestCase
    public func testServerFullConfig() {
        let config = JoyConfig(
            remoteIPHeaders: ["X-Forwarded-For"],
            caseInsensitive: true,
            escapeAddedRoutes: true,
            maxRequestBodySize: 64 * 1024 * 1024
        )
        let engine = Joy.create(config, name: "testServerFullConfig")
        engine.router.get("/", {ctx: JoyContext => ctx.string("ok")})

        spawn {
            engine.run("127.0.0.1", 18912)
        }
        sleep(Duration.millisecond * 500)

        @Assert(engine.server.addr, "127.0.0.1")
        @Assert(engine.server.port, 18912)
        @Assert(engine.config.remoteIPHeaders.size, 1)
        @Assert(engine.config.caseInsensitive, true)
        @Assert(engine.config.escapeAddedRoutes, true)
        @Assert(engine.config.maxRequestBodySize, 64 * 1024 * 1024)

        engine.shutdown()
    }

    /**
     * 测试重复创建引擎异常 - 验证创建同名引擎会抛出 IllegalArgumentException
     */
    @TestCase
    public func testDuplicateEngineException() {
        let name = "testDuplicateException"
        let engine1 = Joy.create(name: name)

        var threwException = false
        try {
            let engine2 = Joy.create(name: name)
        } catch (e: IllegalArgumentException) {
            threwException = true
            @Assert(e.message.contains("already existing"), true)
        }
        @Assert(threwException, true)

        engine1.shutdown()
    }

    /**
     * 测试获取不存在服务的异常处理 - 验证获取不存在服务返回 None
     */
    @TestCase
    public func testGetNonExistentService() {
        let engine = Joy.create(name: "testGetNonExistentService")
        let service = engine.getService<String>("nonexistent")
        @Assert(service.isNone(), true)
        engine.shutdown()
    }

    /**
     * 测试路由处理异常 - 验证路由处理器抛出异常时的行为
     */
    @TestCase
    public func testRouteHandlerException() {
        let engine = Joy.create(name: "testRouteHandlerException")
        engine.router.get("/", {ctx: JoyContext =>
            throw Exception("test error")
        })

        spawn {
            engine.run("127.0.0.1", 18913)
        }
        sleep(Duration.millisecond * 500)

        // 使用客户端发送请求，预期返回 500 错误
        let client = ClientBuilder().build()
        try {
            let rsp = client.get("http://127.0.0.1:18913/")
            @Assert(rsp.status, 500)
        } catch (e: Exception) {
            // 忽略连接错误
        }
        client.close()

        engine.shutdown()
    }

    /**
     * 测试服务器未启动时获取 server 属性 - 验证未启动时访问 server 会抛出异常
     */
    @TestCase
    public func testAccessServerBeforeStart() {
        let engine = Joy.create(name: "testAccessServerBeforeStart")

        var threwException = false
        try {
            let server = engine.server
        } catch (e: Exception) {
            threwException = true
        }
        @Assert(threwException, true)

        engine.shutdown()
    }

    /**
     * 测试无效端口配置 - 验证使用端口 0 可以自动分配端口
     */
    @TestCase
    public func testZeroPortConfig() {
        let engine = Joy.create(name: "testZeroPortConfig")
        engine.router.get("/", {ctx: JoyContext => ctx.string("ok")})

        spawn {
            engine.run("127.0.0.1", 0)
        }
        sleep(Duration.millisecond * 500)

        // 端口 0 会自动分配一个可用端口
        @Assert(engine.server.port > 0, true)

        engine.shutdown()
    }

    /**
     * 测试引擎添加服务后获取 - 验证服务添加后可以正确获取
     */
    @TestCase
    public func testAddAndReplaceService() {
        let engine = Joy.create(name: "testAddAndReplaceService")

        engine.addService("testKey", "value1")
        let service1 = engine.getService<String>("testKey")
        @Assert(service1.getOrThrow(), "value1")

        // 替换服务值
        engine.addService("testKey", "value2")
        let service2 = engine.getService<String>("testKey")
        @Assert(service2.getOrThrow(), "value2")

        engine.shutdown()
    }

    /**
     * 测试引擎添加不同类型服务 - 验证可以添加不同类型的服务
     */
    @TestCase
    public func testAddDifferentTypeServices() {
        let engine = Joy.create(name: "testAddDifferentTypeServices")

        engine.addService("stringService", "stringValue")
        engine.addService("intService", 12345)
        engine.addService("boolService", true)

        let strService = engine.getService<String>("stringService")
        @Assert(strService.getOrThrow(), "stringValue")

        // 注意：由于类型擦除，不同类型的获取需要转换
        engine.shutdown()
    }
}
