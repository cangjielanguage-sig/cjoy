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
 * 测试 AbstractSession 抽象基类的实现
 */
class TestSession <: AbstractSession {
    public init(sid: String) {
        super(sid)
    }
}

/**
 * 测试 AbstractSessionStorage 抽象基类的实现
 */
class TestSessionStorage <: AbstractSessionStorage {
    public init(maxLifetime!: Duration = Duration.hour) {
        super(maxLifetime)
    }

    protected func createSession(sid: String): AbstractSession {
        TestSession(sid)
    }
}

/**
 * 会话基类 LLT 测试
 *
 * 测试 AbstractSession 和 AbstractSessionStorage 的低级别功能
 */
@Test
public class SessionBaseTestCaseSuit {
    /**
     * 测试抽象会话创建 - 验证 AbstractSession 实例化
     */
    @TestCase
    public func testAbstractSessionCreation() {
        let session = TestSession("test-session-id")

        @Assert(session.id, "test-session-id")
        @Assert(!session.isInvalidated)
    }

    /**
     * 测试抽象会话属性访问 - 验证 id 和 isInvalidated 属性
     */
    @TestCase
    public func testAbstractSessionProperties() {
        let session = TestSession("test-session")

        @Assert(session.id, "test-session")
        @Assert(!session.isInvalidated)

        session.invalidate()
        @Assert(session.isInvalidated)
    }

    /**
     * 测试会话数据存储和检索 - 验证 set 和 get 方法
     */
    @TestCase
    public func testSessionDataOperations() {
        let session = TestSession("test-session")

        // 存储数据
        session.set("key1", "value1")
        session.set("key2", "123")
        session.set("key3", true)

        // 检索数据
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
     * 测试会话数据删除 - 验证 remove 方法
     */
    @TestCase
    public func testSessionDataRemoval() {
        let session = TestSession("test-session")

        session.set("key1", "value1")
        let removed = session.remove<String>("key1")
        @Assert(removed.isSome())
        @Assert(removed.getOrThrow(), "value1")

        let notExists = session.get<String>("key1")
        @Assert(notExists.isNone())
    }

    /**
     * 测试会话失效 - 验证 invalidate 方法
     */
    @TestCase
    public func testSessionInvalidation() {
        let session = TestSession("test-session")

        @Assert(!session.isInvalidated)
        session.invalidate()
        @Assert(session.isInvalidated)
    }

    /**
     * 测试会话存储创建 - 验证 AbstractSessionStorage 实例化
     */
    @TestCase
    public func testAbstractSessionStorageCreation() {
        let storage = TestSessionStorage()
        @Assert(storage.size, 0)
    }

    /**
     * 测试会话存储获取或创建 - 验证 getOrCreate 方法
     */
    @TestCase
    public func testSessionStorageGetOrCreate() {
        let storage = TestSessionStorage()

        // 创建新会话
        let session1 = storage.getOrCreate("test-session-1", 32)
        @Assert(session1.id != "")
        @Assert(storage.size, 1)
        @Assert(storage.exists(session1.id))

        // 获取已存在的会话
        let session2 = storage.getOrCreate(session1.id, 32)
        @Assert(session2.id, session1.id)
        @Assert(storage.size, 1)
    }

    /**
     * 测试会话存储删除 - 验证 delete 方法
     */
    @TestCase
    public func testSessionStorageDelete() {
        let storage = TestSessionStorage()
        let session = storage.getOrCreate("test-session", 32)

        @Assert(storage.exists(session.id))
        storage.delete(session.id)
        @Assert(!storage.exists(session.id))
        @Assert(storage.size, 0)
    }

    /**
     * 测试会话存储过期清理 - 验证 clean 方法
     */
    @TestCase
    public func testSessionStorageCleanup() {
        let storage = TestSessionStorage(maxLifetime: Duration.millisecond * 500)

        let session = storage.getOrCreate("expiring-session", 32)
        @Assert(storage.size, 1)

        // 等待会话过期
        sleep(Duration.millisecond * 600)

        storage.clean()
        @Assert(storage.size, 0)
    }

    /**
     * 测试会话存储多会话管理 - 验证多个会话的存储
     */
    @TestCase
    public func testSessionStorageMultiSession() {
        let storage = TestSessionStorage()

        let session1 = storage.getOrCreate("session-1", 32)
        let session2 = storage.getOrCreate("session-2", 32)
        let session3 = storage.getOrCreate("session-3", 32)

        @Assert(storage.size, 3)
        @Assert(session1.id != "")
        @Assert(session2.id != "")
        @Assert(session3.id != "")
        @Assert(session1.id != session2.id)
        @Assert(session2.id != session3.id)
        @Assert(session1.id != session3.id)
    }

    /**
     * 测试会话存在性检查 - 验证 exists 方法
     */
    @TestCase
    public func testSessionStorageExists() {
        let storage = TestSessionStorage()
        let session = storage.getOrCreate("test-session", 32)

        @Assert(storage.exists(session.id))
        @Assert(!storage.exists("non-existent-session"))
    }

    /**
     * 测试会话存储大小属性 - 验证 size 属性
     */
    @TestCase
    public func testSessionStorageSize() {
        let storage = TestSessionStorage()

        @Assert(storage.size, 0)

        let session1 = storage.getOrCreate("session-1", 32)
        @Assert(storage.size, 1)

        let session2 = storage.getOrCreate("session-2", 32)
        @Assert(storage.size, 2)

        storage.delete(session1.id)
        @Assert(storage.size, 1)

        storage.delete(session2.id)
        @Assert(storage.size, 0)
    }

    /**
     * 测试会话存储创建 - 验证默认构造函数
     */
    @TestCase
    public func testSessionStorageDefaultConstructor() {
        let storage = TestSessionStorage()
        @Assert(storage.size, 0)
    }
}
