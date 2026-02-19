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
}
