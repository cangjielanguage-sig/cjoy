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
public class PropertiesConfigTestCaseSuit {
    /**
     * 测试简单 Properties 配置 - 验证基本 Properties 配置文件的加载和解析
     */
    @TestCase
    public func testSimple1(): Unit {
        let loader = PropertiesConfigLoader("./testdata/joy.properties")
        let data = loader.load()
        let manager = ConfigManager()
        manager.addLoader(loader)
        @Assert(manager.getValue("joy.server.address", ""), "127.0.0.1")
        @Assert(manager.getValue("joy.server.port", ""), "18881")
    }

    /**
     * 测试文件未找到 - 验证加载不存在的 Properties 配置文件时的错误处理
     */
    @TestCase
    public func testFileNotFound(): Unit {
        try {
            let loader = PropertiesConfigLoader("./testdata/nonexistent.properties")
            loader.load()
            @Fail("should throw exception")
        } catch (ex: Exception) {
            @Assert(true) // 只要抛出异常就算成功
        }
    }

    /**
     * 测试空文件 - 验证加载空 Properties 文件时的处理
     */
    @TestCase
    public func testEmptyFile(): Unit {
        let loader = PropertiesConfigLoader("./testdata/empty.properties")
        let data = loader.load()
        @Assert(data.size, 0)
    }

    /**
     * 测试含等号的值 - 验证包含等号的属性值解析
     */
    @TestCase
    public func testValueWithEqualSign(): Unit {
        let loader = PropertiesConfigLoader("./testdata/equal-sign.properties")
        let data = loader.load()
        let manager = ConfigManager()
        manager.addLoader(loader)
        @Assert(manager.getValue("app.version", ""), "1.0.0")
        @Assert(manager.getValue("app.description", ""), "This is a=test")
        @Assert(manager.getValue("app.config", ""), "key=value=pair")
    }

    /**
     * 测试注释行 - 验证包含注释的 Properties 文件解析
     */
    @TestCase
    public func testCommentLines(): Unit {
        let loader = PropertiesConfigLoader("./testdata/comments.properties")
        let data = loader.load()
        let manager = ConfigManager()
        manager.addLoader(loader)
        @Assert(manager.getValue("app.name", ""), "TestApp")
        @Assert(manager.getValue("app.version", ""), "1.0.0")
        @Assert(manager.bind<Bool>("app.debug") ?? false, true)
    }

    /**
     * 测试单字符键 - 验证只有一个字符的配置键也能被解析
     */
    @TestCase
    public func testSingleCharKey(): Unit {
        let loader = PropertiesConfigLoader("./testdata/single-char.properties")
        let manager = ConfigManager()
        manager.addLoader(loader)
        @Assert(manager.getValue("a", ""), "1")
        @Assert(manager.getValue("b", ""), "two=three")
    }

    /**
     * 测试 Properties 加载器优先级 - 验证 Properties 配置加载器的优先级设置功能
     */
    @TestCase
    public func testPriority(): Unit {
        let loader1 = PropertiesConfigLoader("./testdata/joy.properties", priorityNum: 10)
        let loader2 = PropertiesConfigLoader("./testdata/joy.properties", priorityNum: 20)
        @Assert(loader1.priority, 10)
        @Assert(loader2.priority, 20)
    }

    /**
     * 测试特殊字符处理 - 验证包含中文字符和特殊字符的 Properties 配置解析
     */
    @TestCase
    public func testSpecialChars(): Unit {
        let loader = PropertiesConfigLoader("./testdata/special-chars.properties")
        let data = loader.load()
        let manager = ConfigManager()
        manager.addLoader(loader)
        @Assert(manager.getValue("app.title", ""), "测试应用")
        @Assert(manager.getValue("app.description", ""), "这是一个测试应用")
        @Assert(manager.getValue("app.path", ""), "/usr/local/app")
    }
}
