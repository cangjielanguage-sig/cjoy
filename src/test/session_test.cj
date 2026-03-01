/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.test

import std.io.*
import std.fs.*
import stdx.net.http.*
import cjoy.*
import cjoy.json.*
import cjoy.session.*
import cjoy.middleware.{SessionManager, getSession, JoySessionConfig}

@Test
public class SessionTestCaseSuit {
    var _instance: ?Joy = None
    let _client = ClientBuilder().build()

    @BeforeAll
    func setup() {
        let sessionManager = SessionManager(MemorySessionStorage())
        spawn {
            let joy = Joy.default()
            let router = joy.router
            router.use(sessionManager)
            router.get(
                "/session",
                {
                    ctx: JoyContext =>
                    let session = getSession(ctx).getOrThrow()
                    session.set("session-data-key1", "session-data-value1")
                }
            )
            router.get(
                "/session-data",
                {
                    ctx: JoyContext =>
                    let session = getSession(ctx).getOrThrow()
                    let data = session.get<String>("session-data-key1").getOrDefault({=> ""})
                    ctx.string(data)
                }
            )
            router.get(
                "/session-remove",
                {
                    ctx: JoyContext =>
                    let session = getSession(ctx).getOrThrow()
                    session.remove<String>("session-data-key1")
                    ctx.string(session.get<String>("session-data-key1").getOrDefault({=> "not-exist"}))
                }
            )
            router.get(
                "/session-multiple",
                {
                    ctx: JoyContext =>
                    let session = getSession(ctx).getOrThrow()
                    session.set("key1", "value1")
                    session.set("key2", "value2")
                    session.set("key3", "value3")
                    let result = "${session.get<String>("key1").getOrDefault({=> ""})},${session.get<String>("key2").getOrDefault({=> ""})},${session.get<String>("key3").getOrDefault({=> ""})}"
                    ctx.string(result)
                }
            )
            router.get(
                "/session-delete",
                {
                    ctx: JoyContext =>
                    let session = getSession(ctx).getOrThrow()
                    session.invalidate()
                }
            )
            _instance = joy
            joy.run("127.0.0.1", 18881)
        }
        sleep(Duration.second)
    }

    @AfterAll
    func tearDown() {
        _client.close()
        _instance?.shutdown()
    }

    private func getSessionId(cookie: String) {
        var cname = ""
        let keyvals = cookie.split(",")
        for (it in keyvals) {
            let nvs = it.split("=")
            if (nvs[0].trimAscii() == "sid") {
                cname = nvs[1]
                break
            }
        }
        cname
    }

    /**
     * 测试会话获取与存储 - 验证会话创建、数据存储和读取
     */
    @TestCase
    public func testGetOk() {
        var rsp = _client.get("http://127.0.0.1:18881/session")
        let cookie: String = rsp.headers.getFirst(JoyHttpConsts.HEADER_SET_COOKIE).getOrThrow()
        @Assert(cookie != "")
        var cname = getSessionId(cookie)
        @Assert(cname != "")
        rsp.close()

        rsp = _client.get("http://127.0.0.1:18881/session-data")
        let reader = StringReader(rsp.body)
        @Assert(reader.readToEnd(), "session-data-value1")
        rsp.close()

        let rsp2 = _client.get("http://127.0.0.1:18881/session-delete")
        rsp2.close()
    }

    /**
     * 测试会话删除与重新创建 - 验证会话删除和重新创建
     */
    @TestCase
    public func testDelOk() {
        var rsp = _client.get("http://127.0.0.1:18881/session")
        var cookie: String = rsp.headers.getFirst(JoyHttpConsts.HEADER_SET_COOKIE).getOrThrow()
        @Assert(cookie != "")
        var cname1 = getSessionId(cookie)
        @Assert(cname1 != "")
        rsp.close()

        // delete session
        let rspDel = _client.get("http://127.0.0.1:18881/session-delete")
        rspDel.close()

        // create new session
        rsp = _client.get("http://127.0.0.1:18881/session")
        cookie = rsp.headers.getFirst(JoyHttpConsts.HEADER_SET_COOKIE).getOrThrow()
        @Assert(cookie != "")
        var cname2 = getSessionId(cookie)
        @Assert(cname1 != cname2)
        rsp.close()

        let rspDel2 = _client.get("http://127.0.0.1:18881/session-delete")
        rspDel2.close()
    }

    /**
     * 测试会话数据 remove 方法 - 验证会话数据删除
     */
    @TestCase
    public func testRemoveOk() {
        var rsp = _client.get("http://127.0.0.1:18881/session")
        let cookie: String = rsp.headers.getFirst(JoyHttpConsts.HEADER_SET_COOKIE).getOrThrow()
        @Assert(cookie != "")
        rsp.close()

        rsp = _client.get("http://127.0.0.1:18881/session-remove")
        let reader = StringReader(rsp.body)
        @Assert(reader.readToEnd(), "not-exist")
        rsp.close()

        let rspDel = _client.get("http://127.0.0.1:18881/session-delete")
        rspDel.close()
    }

    /**
     * 测试会话存储多个键值对 - 验证会话存储和读取多个数据
     */
    @TestCase
    public func testMultipleKeysOk() {
        var rsp = _client.get("http://127.0.0.1:18881/session-multiple")
        let cookie: String = rsp.headers.getFirst(JoyHttpConsts.HEADER_SET_COOKIE).getOrThrow()
        @Assert(cookie != "")

        let reader = StringReader(rsp.body)
        @Assert(reader.readToEnd(), "value1,value2,value3")
        rsp.close()

        let rspDel = _client.get("http://127.0.0.1:18881/session-delete")
        rspDel.close()
    }

    /**
     * 测试 FileSessionStorage - 验证文件会话存储的功能
     */
    @TestCase
    public func testFileSessionStorageOk() {
        let tempDir = "/tmp/cjoy-session-test"
        let fileStorage = FileSessionStorage(tempDir)
        // 测试会话创建和获取
        let session1 = fileStorage.getOrCreate("test-session-id", 32)
        @Assert(session1.id != "")
        @Assert(fileStorage.exists(session1.id))

        session1.set("key", "value")
        let value = session1.get<String>("key")
        @Assert(value.isSome())
        @Assert(value.getOrThrow(), "value")

        // 测试会话删除
        fileStorage.delete(session1.id)
        @Assert(!fileStorage.exists(session1.id))

        // 清理临时目录
        if (exists(tempDir)) {
            removeIfExists(tempDir, recursive: true)
        }
    }

    /**
     * 测试会话配置自定义 - 验证自定义会话配置
     */
    @TestCase
    public func testSessionConfigOk() {
        // 测试自定义 cookie 名称和 ID 长度
        let config = JoySessionConfig(
            cookieName: "custom-sid",
            cookiePath: "/test",
            cookieMaxAge: 7200,
            idLength: 16
        )
        let storage = MemorySessionStorage()
        let manager = SessionManager(storage, config: config)

        // 验证配置
        @Assert(config.cookieName, "custom-sid")
        @Assert(config.cookiePath, "/test")
        @Assert(config.cookieMaxAge, 7200)
        @Assert(config.idLength, 16)
    }

    /**
     * 测试 MemorySessionStorage 基本功能 - 验证内存会话存储
     */
    @TestCase
    public func testMemorySessionStorageOk() {
        let storage = MemorySessionStorage()

        // 测试会话创建
        let session1 = storage.getOrCreate("", 32)
        @Assert(session1.id != "")
        @Assert(storage.exists(session1.id))
        @Assert(storage.size, 1)

        // 测试会话获取
        let session2 = storage.getOrCreate(session1.id, 32)
        @Assert(session2.id, session1.id)
        @Assert(storage.size, 1)

        // 测试会话删除
        storage.delete(session1.id)
        @Assert(!storage.exists(session1.id))
        @Assert(storage.size, 0)
    }

    /**
     * 测试会话过期清理 - 验证会话过期后会被正确清理
     */
    @TestCase
    public func testSessionCleanupOk() {
        let shortLivedStorage = MemorySessionStorage(maxLifetime: Duration.second * 1)

        // 创建会话
        let session = shortLivedStorage.getOrCreate("", 32)
        @Assert(shortLivedStorage.size, 1)

        // 等待会话过期
        sleep(Duration.second * 2)

        // 清理过期会话
        shortLivedStorage.clean()

        // 验证会话已被清理
        @Assert(shortLivedStorage.size, 0)
    }
}
