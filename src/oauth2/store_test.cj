/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.oauth2

import std.time.DateTime
import std.unittest.mock.*
import cjoy.framework.*

@Test
public class MemoryTokenStoreTestCaseSuit {
    /**
     * 测试内存令牌存储基础 API - 验证令牌存储的基本操作
     */
    @TestCase
    public func testBaseApi() {
        let store = MemoryTokenStore()
        let token = createTestTokenInfo()

        // 测试创建和获取令牌
        store.create(token)
        let byCode = store.getByCode(token.code)
        @Assert(byCode.isSome())
        @Assert(byCode.getOrThrow().code, token.code)

        let byAccess = store.getByAccess(token.access)
        @Assert(byAccess.isSome())
        @Assert(byAccess.getOrThrow().access, token.access)

        let byRefresh = store.getByRefresh(token.refresh)
        @Assert(byRefresh.isSome())
        @Assert(byRefresh.getOrThrow().refresh, token.refresh)

        // 测试删除令牌
        store.removeByCode(token.code)
        @Assert(store.getByCode(token.code).isNone())

        store.removeByAccess(token.access)
        @Assert(store.getByAccess(token.access).isNone())

        store.removeByRefresh(token.refresh)
        @Assert(store.getByRefresh(token.refresh).isNone())
    }

    /**
     * 测试内存令牌存储的过期令牌清理 - 验证过期令牌会被正确清理
     */
    @TestCase
    public func testExpiredTokenCleanup() {
        let store = MemoryTokenStore()
        let token = createTestTokenInfo()
        // 设置过期时间为 1 秒，这样令牌会在短时间内过期
        // 不设置刷新令牌，这样就不会触发访问令牌过期时间的自动调整逻辑
        token.codeExpiredIn = 1
        token.accessExpiredIn = 1
        token.refresh = ""
        token.refreshExpiredIn = 0

        store.create(token)

        // 等待令牌过期
        sleep(Duration.second * 2)
        // 等待清理任务执行
        sleep(Duration.second * 6)

        // 验证过期令牌已被清理
        @Assert(store.getByCode(token.code).isNone())
        @Assert(store.getByAccess(token.access).isNone())
        @Assert(store.getByRefresh(token.refresh).isNone())
    }

    /**
     * 测试内存令牌存储的销毁方法 - 验证销毁操作
     */
    @TestCase
    public func testDestroy() {
        let store = MemoryTokenStore()
        store.destroy()
    }
}

@Test
public class MemoryClientStoreTestCaseSuit {
    /**
     * 测试内存客户端存储基础 API - 验证客户端存储的基本操作
     */
    @TestCase
    public func testBaseApi() {
        let store = MemoryClientStore()
        let client = ClientInfo(id: "test-client", secret: "test-secret", domain: "http://localhost:8080", isPublic: false)

        // 测试添加和获取客户端
        store.add(client)
        let retrieved = store.getById(client.id)
        @Assert(retrieved.isSome())
        @Assert(retrieved.getOrThrow().id, client.id)
        @Assert(retrieved.getOrThrow().secret, client.secret)
        @Assert(retrieved.getOrThrow().domain, client.domain)
        @Assert(retrieved.getOrThrow().isPublic, client.isPublic)

        // 测试获取不存在的客户端
        let notFound = store.getById("non-existent-client")
        @Assert(notFound.isNone())
    }
}

private func createTestTokenInfo(): TokenInfo {
    let token = TokenInfo()
    token.clientId = "test-client"
    token.userId = "test-user"
    token.redirectURI = "http://localhost:8080/oauth2/callback"
    token.scope = "read write"
    token.code = "test-code-12345"
    token.codeCreateAt = DateTime.now()
    token.codeExpiredIn = 3600
    token.access = "test-access-token-12345"
    token.accessCreateAt = DateTime.now()
    token.accessExpiredIn = 7200
    token.refresh = "test-refresh-token-12345"
    token.refreshCreateAt = DateTime.now()
    token.refreshExpiredIn = 86400
    token
}
