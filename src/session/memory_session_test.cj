/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.session

import std.time.*
import std.unittest.testmacro.*

/**
 * 内存会话存储 LLT 测试
 *
 * 测试 MemorySession 和 MemorySessionStorage 的低级别功能
 */
@Test
public class MemorySessionStorageTestCaseSuit {
    /**
     * 测试内存会话创建 - 验证 MemorySession 实例创建
     */
    @TestCase
    public func testMemorySessionCreation() {
        let storage = MemorySessionStorage()
        let session = storage.getOrCreate("test-session-id", 32)

        @Assert(session.id != "")
        @Assert(!session.isInvalidated)
    }

    /**
     * 测试内存会话数据存储 - 验证 set 和 get 方法
     */
    @TestCase
    public func testMemorySessionDataStorage() {
        let storage = MemorySessionStorage()
        let session = storage.getOrCreate("test-session", 32)

        session.set("key1", "value1")
        session.set("key2", "123")
        session.set("key3", true)

        let value1 = session.get<String>("key1")
        @Assert(value1.isSome())
        @Assert(value1.getOrThrow(), "value1")

        let value2 = session.get<String>("key2")
        @Assert(value2.isSome())
        @Assert(value2.getOrThrow(), "123")

        let value3 = session.get<Bool>("key3")
        @Assert(value3.isSome())
        @Assert(value3.getOrThrow(), true)
    }

    /**
     * 测试内存会话数据删除 - 验证 remove 方法
     */
    @TestCase
    public func testMemorySessionDataRemoval() {
        let storage = MemorySessionStorage()
        let session = storage.getOrCreate("test-session", 32)

        session.set("key1", "value1")
        let removed = session.remove<String>("key1")
        @Assert(removed.isSome())
        @Assert(removed.getOrThrow(), "value1")

        let notExists = session.get<String>("key1")
        @Assert(notExists.isNone())
    }

    /**
     * 测试内存会话失效 - 验证 invalidate 方法
     */
    @TestCase
    public func testMemorySessionInvalidation() {
        let storage = MemorySessionStorage()
        let session = storage.getOrCreate("test-session", 32)

        session.set("key1", "value1")
        session.invalidate()

        @Assert(session.isInvalidated)
        @Assert(!storage.exists(session.id))
    }

    /**
     * 测试内存会话存储创建 - 验证 MemorySessionStorage 实例创建
     */
    @TestCase
    public func testMemorySessionStorageCreation() {
        let storage = MemorySessionStorage()
        @Assert(storage.size, 0)
    }

    /**
     * 测试内存会话存储获取或创建 - 验证 getOrCreate 方法
     */
    @TestCase
    public func testMemorySessionStorageGetOrCreate() {
        let storage = MemorySessionStorage()

        // 创建新会话
        let session1 = storage.getOrCreate("", 32)
        @Assert(session1.id != "")
        @Assert(storage.size, 1)
        @Assert(storage.exists(session1.id))

        // 获取已存在的会话
        let session2 = storage.getOrCreate(session1.id, 32)
        @Assert(session2.id, session1.id)
        @Assert(storage.size, 1)
    }

    /**
     * 测试内存会话存储删除 - 验证 delete 方法
     */
    @TestCase
    public func testMemorySessionStorageDelete() {
        let storage = MemorySessionStorage()
        let session = storage.getOrCreate("", 32)

        @Assert(storage.exists(session.id))
        storage.delete(session.id)
        @Assert(!storage.exists(session.id))
        @Assert(storage.size, 0)
    }

    /**
     * 测试内存会话过期清理 - 验证 clean 方法
     */
    @TestCase
    public func testMemorySessionStorageCleanup() {
        let storage = MemorySessionStorage(maxLifetime: Duration.millisecond * 500)

        let session = storage.getOrCreate("", 32)
        @Assert(storage.size, 1)

        // 等待会话过期
        sleep(Duration.millisecond * 600)

        storage.clean()
        @Assert(storage.size, 0)
    }

    /**
     * 测试内存会话存储多会话管理 - 验证多个会话的存储和管理
     */
    @TestCase
    public func testMemorySessionStorageMultiSession() {
        let storage = MemorySessionStorage()

        let session1 = storage.getOrCreate("", 32)
        let session2 = storage.getOrCreate("", 32)
        let session3 = storage.getOrCreate("", 32)

        @Assert(storage.size, 3)
        @Assert(session1.id != session2.id)
        @Assert(session2.id != session3.id)
        @Assert(session1.id != session3.id)
    }

    /**
     * 测试内存会话存储会话存在检查 - 验证 exists 方法
     */
    @TestCase
    public func testMemorySessionStorageExists() {
        let storage = MemorySessionStorage()
        let session = storage.getOrCreate("", 32)

        @Assert(storage.exists(session.id))
        @Assert(!storage.exists("non-existent-session"))
    }
}
