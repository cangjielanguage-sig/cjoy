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

import std.unittest.mock.*
import cjoy.framework.*

@Test
public class DefaultOAuth2ManagerTestCaseSuit {
    func createManager(): OAuth2Manager {
        let clientStore = MemoryClientStore()
        clientStore.add(ClientInfo(id: "1", secret: "11", domain: "http://localhost"))
        let manager = DefaultOAuth2Manager(clientStore: clientStore)
        manager
    }

    /**
     * 测试 OAuth2 管理器基础 API - 验证客户端查询、授权码生成、访问令牌生成、刷新令牌等核心功能
     */
    @TestCase
    public func testBaseApi() {
        let manager = createManager()
        let tgr = TokenGenerateRequest(request: mock<JoyContext>(), clientId: "1", clientSecret: "123456",
            redirectURI: "http://localhost/oauth2", scope: "all")
        let cli = manager.getClient("1")
        @Assert(cli.secret, "11")

        testManager(tgr, manager)
        testZeroAccessExpireManager(tgr, manager)
        testCannotReqZeroAccessExpireManager(tgr, manager)
        testZeroRefreshExpireManager(tgr, manager)
    }

    private func testManager(tgr: TokenGenerateRequest, manager: OAuth2Manager) {
        var cti = manager.generateAuthToken(OAuthConsts.RESPONSE_TYPE_CODE, tgr)
        @Assert(cti.code != "")

        let atparams = TokenGenerateRequest(request: mock<JoyContext>(), clientId: cti.clientId, clientSecret: "11",
            redirectURI: tgr.redirectURI, code: cti.code)

        cti = manager.generateAccessToken(OAuthConsts.GRANT_TYPE_AUTHORIZATION_CODE, atparams)
        @Assert(cti.access != "")
        @Assert(cti.refresh != "")

        let aiInfo = manager.loadAccessToken(cti.access)
        @Assert(aiInfo.clientId == atparams.clientId)

        let arinfo = manager.loadRefreshToken(cti.refresh)
        @Assert(arinfo.clientId == atparams.clientId)

        try {
            manager.loadRefreshToken(cti.access)
            @Fail("shoud throw exception")
        } catch (ex: OAuthException) {
            @Assert(ex.errorInfo.code, OAuthErrors.INVALID_REFRESH_TOKEN.code)
        }

        let refreshParam = TokenGenerateRequest(request: mock<JoyContext>(), refresh: cti.refresh, scope: "owner")
        let rti = manager.refreshAccessToken(refreshParam)
        @Assert(rti.access != "")

        manager.loadAccessToken(rti.access)

        manager.removeAccessToken(rti.access)
        manager.removeRefreshToken(cti.refresh)

        try {
            manager.loadRefreshToken(cti.refresh)
            @Fail("shoud throw exception")
        } catch (ex: OAuthException) {
            @Assert(ex.errorInfo.code, OAuthErrors.INVALID_REFRESH_TOKEN.code)
        }
    }

    private func testZeroAccessExpireManager(tgr: TokenGenerateRequest, manager: OAuth2Manager) {
        let m = (manager as DefaultOAuth2Manager).getOrThrow()
        // accessTokenExp 0 is (no) expiration
        m.setGrantConfig(OAuthConsts.GRANT_TYPE_AUTHORIZATION_CODE, GrantConfig(Duration.Zero, Duration.day, true))

        var token = manager.generateAuthToken(OAuthConsts.RESPONSE_TYPE_CODE, tgr)
        @Assert(token.code != "")

        let atparams = TokenGenerateRequest(request: mock<JoyContext>(), clientId: token.clientId, clientSecret: "11",
            redirectURI: tgr.redirectURI, code: token.code)
        token = manager.generateAccessToken(OAuthConsts.GRANT_TYPE_AUTHORIZATION_CODE, atparams)
        @Assert(token.access != "")
        @Assert(token.refresh != "")

        let at = manager.loadAccessToken(token.access)
        @Assert(at.access == token.access)
        @Assert(at.accessExpiredIn == 0)
    }

    private func testCannotReqZeroAccessExpireManager(tgr: TokenGenerateRequest, manager: OAuth2Manager) {
        let m = (manager as DefaultOAuth2Manager).getOrThrow()
        // accessTokenExp 0 is (no) expiration
        m.setGrantConfig(OAuthConsts.GRANT_TYPE_AUTHORIZATION_CODE, GrantConfig(Duration.hour * 5, Duration.day, true))

        var token = manager.generateAuthToken(OAuthConsts.RESPONSE_TYPE_CODE, tgr)
        @Assert(token.code != "")

        let atparams = TokenGenerateRequest(request: mock<JoyContext>(), clientId: token.clientId, clientSecret: "11",
            redirectURI: tgr.redirectURI, code: token.code)
        token = manager.generateAccessToken(OAuthConsts.GRANT_TYPE_AUTHORIZATION_CODE, atparams)
        @Assert(token.access != "")
        @Assert(token.refresh != "")

        let at = manager.loadAccessToken(token.access)
        @Assert(at.access == token.access)
        @Assert(at.accessExpiredIn == (Duration.hour*5).toSeconds())
    }

    private func testZeroRefreshExpireManager(tgr: TokenGenerateRequest, manager: OAuth2Manager) {
        let m = (manager as DefaultOAuth2Manager).getOrThrow()
        // refreshTokenExp 0 is (no) expiration
        m.setGrantConfig(OAuthConsts.GRANT_TYPE_AUTHORIZATION_CODE, GrantConfig(Duration.hour * 5, Duration.Zero, true))

        var token = manager.generateAuthToken(OAuthConsts.RESPONSE_TYPE_CODE, tgr)
        @Assert(token.code != "")

        let atparams = TokenGenerateRequest(request: mock<JoyContext>(), clientId: token.clientId, clientSecret: "11",
            redirectURI: tgr.redirectURI, code: token.code)
        token = manager.generateAccessToken(OAuthConsts.GRANT_TYPE_AUTHORIZATION_CODE, atparams)
        @Assert(token.access != "")
        @Assert(token.refresh != "")

        let rt = manager.loadRefreshToken(token.refresh)
        @Assert(rt.refresh == token.refresh)
        @Assert(rt.refreshExpiredIn == 0)

        let at = manager.loadAccessToken(token.access)
        @Assert(at.refresh == token.refresh)
        @Assert(at.refreshExpiredIn == 0)
    }
}
