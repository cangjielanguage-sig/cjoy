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

import std.fs.*

@Test
public class FileSessionStorageTestCaseSuit {
    /**
     * 测试文件会话存储保存功能 - 验证会话数据保存到文件系统
     */
    @TestCase
    public func testFileStorageSave() {
        let storage = FileSessionStorage("./session")
        let session = storage.createSession("123")
        session.set("1", "value1")
        session.set("2", "value2")
        session.flush()
        @Assert(exists("./session/123/1"))
        @Assert(exists("./session/123/2"))

        session.invalidate()
        @Assert(!exists("./session/123/1"))
        @Assert(!exists("./session/123/2"))
        removeIfExists("./session", recursive: true)
    }

    /**
     * 测试文件会话存储删除功能 - 验证会话数据删除操作
     */
    @TestCase
    public func testFileStorageSave2() {
        let storage = FileSessionStorage("./session")
        let session = storage.createSession("123")
        session.set("1", "value1")
        session.set("2", "value2")
        session.flush()
        @Assert(exists("./session/123/1"))
        @Assert(exists("./session/123/2"))

        session.remove<String>("2")
        session.flush()
        @Assert(!exists("./session/123/2"))

        session.invalidate()
        @Assert(!exists("./session/123/1"))
        removeIfExists("./session", recursive: true)
    }

    /**
     * 测试文件会话存储获取功能 - 验证会话创建、获取和删除的完整流程
     */
    @TestCase
    public func testFileStorageGet() {
        let storage = FileSessionStorage("./session")
        let session = storage.getOrCreate("", 8)
        session.set("1", "value1")
        session.flush()
        @Assert(storage.exists(session.id))

        // get session from storage
        let sess = storage.getOrCreate(session.id, 8)
        let value = sess.get<String>("1") ?? ""
        @Assert(value, "value1")

        // delete session
        session.invalidate()
        @Assert(session.isInvalidated)
        @Assert(!storage.exists(session.id))
        removeIfExists("./session", recursive: true)
    }

    /**
     * 测试文件会话存储加载功能 - 验证从磁盘加载会话数据
     */
    @TestCase
    public func testFileStorageLoad() {
        let storage = FileSessionStorage("./session")
        let session = storage.createSession("123")
        session.set("1", "value1")
        session.flush()

        // not in memory, will load from disk
        let sess = storage.getOrCreate("123", 8)
        let value = sess.get<String>("1") ?? ""
        @Assert(value, "value1")
        removeIfExists("./session", recursive: true)
    }

    /**
     * 测试文件会话存储清理功能 - 验证过期会话自动清理
     */
    @TestCase
    public func testFileStorageClean() {
        let storage = FileSessionStorage("./session", maxLifetime: Duration.second)
        let session = storage.getOrCreate("", 8)
        session.set("1", "value1")
        session.flush()
        let sid = session.id

        sleep(Duration.second*1.5)
        storage.clean()
        @Assert(!storage.exists(sid))
        @Assert(exists("./session/${sid}/1"), false)
        removeIfExists("./session", recursive: true)
    }

    /**
     * 测试同一键先删除后设置 - 验证刷新后保留新值而不是删除文件
     */
    @TestCase
    public func testFileStorageRemoveThenSet() {
        let storage = FileSessionStorage("./session-regression")
        let session = storage.createSession("rs")
        session.set("k", "old")
        session.flush()

        session.remove<String>("k")
        session.set("k", "new")
        session.flush()

        let loaded = storage.getOrCreate("rs", 8)
        @Assert(loaded.get<String>("k") ?? "<none>", "new")
        removeIfExists("./session-regression", recursive: true)
    }

    /**
     * 测试删除磁盘中的值 - 验证 remove 返回被删除的值且同一请求内不会从磁盘复活
     */
    @TestCase
    public func testFileStorageGetAfterRemove() {
        let storage = FileSessionStorage("./session-regression")
        let session = storage.createSession("gr")
        session.set("k", "value1")
        session.flush()

        let loaded = storage.getOrCreate("gr", 8)
        @Assert(loaded.get<String>("k") ?? "<none>", "value1")
        let removed = loaded.remove<String>("k")
        @Assert(removed.isSome())
        @Assert(removed.getOrThrow(), "value1")
        @Assert(loaded.get<String>("k").isNone())
        removeIfExists("./session-regression", recursive: true)
    }

    /**
     * 测试直接删除未加载的磁盘值 - 验证从磁盘加载后返回被删除的值
     */
    @TestCase
    public func testFileStorageRemoveDiskValue() {
        let storage = FileSessionStorage("./session-regression")
        let session = storage.createSession("disk-remove")
        session.set("k", "value1")
        session.flush()

        let loaded = storage.getOrCreate("disk-remove", 8)
        let removed = loaded.remove<String>("k")
        @Assert(removed.isSome())
        @Assert(removed.getOrThrow(), "value1")
        loaded.flush()
        @Assert(exists("./session-regression/disk-remove/k"), false)
        removeIfExists("./session-regression", recursive: true)
    }

    /**
     * 测试持久化会话的存在性检查 - 验证未加载进内存的磁盘会话也存在
     */
    @TestCase
    public func testFileStorageExistsPersisted() {
        let storage = FileSessionStorage("./session-regression")
        let session = storage.getOrCreate("", 8)
        session.set("k", "v")
        session.flush()
        let sid = session.id

        // 新的存储实例内存为空，但磁盘中已有会话目录
        let storage2 = FileSessionStorage("./session-regression")
        @Assert(storage2.exists(sid))
        let loaded = storage2.getOrCreate(sid, 8)
        @Assert(loaded.id, sid)
        @Assert(loaded.get<String>("k") ?? "<none>", "v")
        removeIfExists("./session-regression", recursive: true)
    }

    /**
     * 测试非法会话 ID - 验证包含相对路径的 ID 不能写到存储目录之外
     */
    @TestCase
    public func testFileStorageRejectsTraversalSid() {
        Directory.create("./session-outside", recursive: true)
        let storage = FileSessionStorage("./session-regression")
        let session = storage.getOrCreate("../session-outside", 8)
        @Assert(session.id != "../session-outside")
        session.set("k", "v")
        session.flush()
        @Assert(exists("./session-outside/k"), false)
        removeIfExists("./session-regression", recursive: true)
        removeIfExists("./session-outside", recursive: true)
    }

    /**
     * 测试非法会话键名 - 验证键名不能包含路径分隔符或相对路径符号
     */
    @TestCase
    public func testFileStorageRejectsTraversalKey() {
        let storage = FileSessionStorage("./session-regression")
        let session = storage.createSession("safe")
        var setThrew = false
        try {
            session.set("../evil", "v")
        } catch (_: IllegalArgumentException) {
            setThrew = true
        }
        @Assert(setThrew)

        var getThrew = false
        try {
            session.get<String>("a/b")
        } catch (_: IllegalArgumentException) {
            getThrew = true
        }
        @Assert(getThrew)
        removeIfExists("./session-regression", recursive: true)
    }
}
