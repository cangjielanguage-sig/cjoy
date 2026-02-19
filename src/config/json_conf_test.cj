/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.config

import std.collection.{HashMap, ArrayList}
import cjoy.macros.*

@Test
public class JsonConfigTestCaseSuit {
    /**
     * 测试简单 JSON 配置 - 验证基本 JSON 配置文件的加载和解析
     */
    @TestCase
    public func testSimple1(): Unit {
        let loader = JsonConfigLoader("./testdata/joy.json")
        let data = loader.load()
        let manager = ConfigManager()
        manager.addLoader(loader)
        @Assert(manager.getValue("joy.server.address", ""), "0.0.0.0")
        @Assert(manager.getValue("joy.server.port", ""), "18882")
    }

    /**
     * 测试文件未找到 - 验证加载不存在的 JSON 配置文件时的错误处理
     */
    @TestCase
    public func testFileNotFound(): Unit {
        try {
            let loader = JsonConfigLoader("./testdata/nonexistent.json")
            loader.load()
            @Fail("should throw exception")
        } catch (ex: Exception) {
            @Assert(true) // 只要抛出异常就算成功
        }
    }

    /**
     * 测试无效 JSON - 验证加载包含无效 JSON 格式的配置文件时的错误处理
     */
    @TestCase
    public func testInvalidJson(): Unit {
        try {
            let loader = JsonConfigLoader("./testdata/invalid.json")
            loader.load()
            @Fail("should throw exception")
        } catch (ex: Exception) {
            @Assert(true) // 只要抛出异常就算成功
        }
    }

    /**
     * 测试空文件 - 验证加载空 JSON 文件时的错误处理
     */
    @TestCase
    public func testEmptyFile(): Unit {
        try {
            let loader = JsonConfigLoader("./testdata/empty.json")
            loader.load()
            @Fail("should throw exception for empty file")
        } catch (ex: Exception) {
            @Assert(true) // 空文件无法解析，抛出异常是正确的
        }
    }

    /**
     * 测试复杂 JSON 配置 - 验证包含嵌套结构和多种数据类型的复杂 JSON 配置解析
     */
    @TestCase
    public func testComplexJson(): Unit {
        let loader = JsonConfigLoader("./testdata/complex.json")
        let data = loader.load()
        let manager = ConfigManager()
        manager.addLoader(loader)
        @Assert(manager.getValue("app.name", ""), "TestApp")
        @Assert(manager.getValue("app.version", ""), "1.0.0")
        @Assert(manager.bind<Bool>("app.debug") ?? false, true)
        @Assert(manager.bind<Int>("app.port") ?? 0, 8080)
        @Assert(manager.getValue("app.database.host", ""), "localhost")
        @Assert(manager.bind<Int>("app.database.port") ?? 0, 5432)
        @Assert(manager.getValue("app.database.name", ""), "testdb")
    }

    /**
     * 测试 JSON 加载器优先级 - 验证 JSON 配置加载器的优先级设置功能
     */
    @TestCase
    public func testPriority(): Unit {
        let loader1 = JsonConfigLoader("./testdata/joy.json", priorityNum: 10)
        let loader2 = JsonConfigLoader("./testdata/joy.json", priorityNum: 20)
        @Assert(loader1.priority, 10)
        @Assert(loader2.priority, 20)
    }

    /**
     * 测试特殊字符处理 - 验证包含中文字符和特殊字符的 JSON 配置解析
     */
    @TestCase
    public func testSpecialChars(): Unit {
        let loader = JsonConfigLoader("./testdata/special-chars.json")
        let data = loader.load()
        let manager = ConfigManager()
        manager.addLoader(loader)
        @Assert(manager.getValue("app.title", ""), "测试应用")
        @Assert(manager.getValue("app.description", ""), "这是一个包含特殊字符的\"测试\"应用！")
    }
}
