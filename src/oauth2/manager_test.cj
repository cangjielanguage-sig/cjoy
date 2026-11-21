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
import std.collection.HashMap
import std.time.DateTime
import cjoy.framework.*

class AcceptPwVerifier <: ClientPasswordVerifier {
    public func verifyPassword(client: ClientInfo, pwd: String): Bool {
        pwd == "pw"
    }
}

class SimpleTokenStore <: TokenStore {
    let data = HashMap<String, TokenInfo>()
    public func create(tokenInfo: TokenInfo): Unit {
        if (tokenInfo.code != "") { data[tokenInfo.code] = tokenInfo }
        if (tokenInfo.access != "") { data[tokenInfo.access] = tokenInfo }
        if (tokenInfo.refresh != "") { data[tokenInfo.refresh] = tokenInfo }
    }
    public func removeByCode(code: String): Unit { data.remove(code) }
    public func removeByAccess(access: String): Unit { data.remove(access) }
    public func removeByRefresh(refresh: String): Unit { data.remove(refresh) }
    public func getByCode(code: String): ?TokenInfo { data.get(code) }
    public func getByAccess(access: String): ?TokenInfo { data.get(access) }
    public func getByRefresh(refresh: String): ?TokenInfo { data.get(refresh) }
}

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
        @Assert(at.accessExpiredIn, (Duration.hour * 5).toSeconds())
    }

    /**
     * 测试无效客户端ID - 验证当客户端ID不存在时会抛出异常
     */
    @TestCase
    public func testInvalidClientId() {
        let manager = createManager()
        try {
            manager.getClient("invalid-client")
            @Fail("should throw exception")
        } catch (ex: OAuthException) {
            @Assert(ex.errorInfo.code, OAuthErrors.INVALID_CLIENT.code)
        }
    }

    /**
     * 测试无效的客户端密码 - 验证当客户端密码不匹配时会抛出异常
     */
    @TestCase
    public func testInvalidClientSecret() {
        let manager = createManager()
        let tgr = TokenGenerateRequest(request: mock<JoyContext>(), clientId: "1", clientSecret: "invalid-secret",
            redirectURI: "http://localhost/oauth2", scope: "all")

        try {
            manager.generateAccessToken(OAuthConsts.GRANT_TYPE_AUTHORIZATION_CODE, tgr)
            @Fail("should throw exception")
        } catch (ex: OAuthException) {
            @Assert(ex.errorInfo.code, OAuthErrors.INVALID_CLIENT.code)
        }
    }

    /**
     * 测试无效的授权码 - 验证当授权码无效时会抛出异常
     */
    @TestCase
    public func testInvalidAuthorizationCode() {
        let manager = createManager()
        let tgr = TokenGenerateRequest(request: mock<JoyContext>(), clientId: "1", clientSecret: "11",
            redirectURI: "http://localhost/oauth2", code: "invalid-code")

        try {
            manager.generateAccessToken(OAuthConsts.GRANT_TYPE_AUTHORIZATION_CODE, tgr)
            @Fail("should throw exception")
        } catch (ex: OAuthException) {
            @Assert(ex.errorInfo.code, OAuthErrors.INVALID_AUTHORIZE_CODE.code)
        }
    }

    /**
     * 测试无效的刷新令牌 - 验证当刷新令牌无效时会抛出异常
     */
    @TestCase
    public func testInvalidRefreshToken() {
        let manager = createManager()
        let tgr = TokenGenerateRequest(request: mock<JoyContext>(), refresh: "invalid-refresh-token")

        try {
            manager.refreshAccessToken(tgr)
            @Fail("should throw exception")
        } catch (ex: OAuthException) {
            @Assert(ex.errorInfo.code, OAuthErrors.INVALID_REFRESH_TOKEN.code)
        }
    }

    /**
     * 测试自定义客户端密码验证器 - 验证器返回 true 时不应再强制比对原始 secret
     */
    @TestCase
    public func testCustomClientPasswordVerifier() {
        let clientStore = MemoryClientStore()
        clientStore.add(ClientInfo(id: "1", secret: "hashed-secret", domain: "http://localhost"))
        let manager = DefaultOAuth2Manager(clientStore: clientStore, clientPasswordVerifier: AcceptPwVerifier())
        let tgr = TokenGenerateRequest(request: mock<JoyContext>(), clientId: "1", clientSecret: "pw")
        let token = manager.generateAccessToken(OAuthConsts.GRANT_TYPE_CLIENT_CREDENTIALS, tgr)
        @Assert(token.access != "")
    }

    /**
     * 测试刷新配置中的刷新令牌有效期 - 验证 refreshTokenExp 在刷新时生效
     */
    @TestCase
    public func testRefreshConfigRefreshExpiry() {
        let manager = (createManager() as DefaultOAuth2Manager).getOrThrow()
        let tgr = TokenGenerateRequest(request: mock<JoyContext>(), clientId: "1", clientSecret: "11",
            redirectURI: "http://localhost/oauth2", scope: "all")
        let codeToken = manager.generateAuthToken(OAuthConsts.RESPONSE_TYPE_CODE, tgr)
        let atgr = TokenGenerateRequest(request: mock<JoyContext>(), clientId: "1", clientSecret: "11",
            redirectURI: tgr.redirectURI, code: codeToken.code)
        let token = manager.generateAccessToken(OAuthConsts.GRANT_TYPE_AUTHORIZATION_CODE, atgr)

        manager.setRefreshingConfig(RefreshingConfig(Duration.hour, Duration.day, true, false, true, true))
        let refreshed = manager.refreshAccessToken(TokenGenerateRequest(request: mock<JoyContext>(), refresh: token.refresh))
        @Assert(refreshed.refreshExpiredIn, Duration.day.toSeconds())
    }

    /**
     * 测试 PKCE 校验失败不清空授权码 - 验证验证器错误后仍可用正确 verifier 兑换
     */
    @TestCase
    public func testPkceFailureDoesNotConsumeCode() {
        let manager = createManager()
        let challenge = "ThisIsAFourtyThreeCharactersLongStringThing"
        let tgr = TokenGenerateRequest(request: mock<JoyContext>(), clientId: "1", clientSecret: "11",
            redirectURI: "http://localhost/oauth2", scope: "all")
        tgr.codeChallenge = challenge
        tgr.codeChallengeMethod = OAuthConsts.CODE_CHALLENGE_PLAIN
        let codeToken = manager.generateAuthToken(OAuthConsts.RESPONSE_TYPE_CODE, tgr)

        let bad = TokenGenerateRequest(request: mock<JoyContext>(), clientId: "1", clientSecret: "11",
            redirectURI: tgr.redirectURI, code: codeToken.code, codeVerifier: "wrong-verifier")
        try {
            manager.generateAccessToken(OAuthConsts.GRANT_TYPE_AUTHORIZATION_CODE, bad)
            @Fail("should reject wrong code verifier")
        } catch (ex: OAuthException) {
            @Assert(ex.errorInfo.code, OAuthErrors.INVALID_CODE_CHALLENGE.code)
        }

        let good = TokenGenerateRequest(request: mock<JoyContext>(), clientId: "1", clientSecret: "11",
            redirectURI: tgr.redirectURI, code: codeToken.code, codeVerifier: challenge)
        let token = manager.generateAccessToken(OAuthConsts.GRANT_TYPE_AUTHORIZATION_CODE, good)
        @Assert(token.access != "")
    }

    /**
     * 测试重定向 URI 校验 - 必须使用精确 host，避免后缀域名绕过
     */
    @TestCase
    public func testRedirectUriExactHostMatch() {
        defaultValidateURIFunc("http://localhost", "http://localhost/cb")
        try {
            defaultValidateURIFunc("http://localhost", "http://evil-localhost/cb")
            @Fail("should reject host that only shares a suffix")
        } catch (ex: OAuthException) {
            @Assert(ex.errorInfo.code, OAuthErrors.INVALID_REDIRECT_URI.code)
        }
    }

    /**
     * 测试 access token 有效性不受 refresh token 过期影响
     */
    @TestCase
    public func testLoadAccessTokenIgnoresExpiredRefresh() {
        let store = SimpleTokenStore()
        let manager = DefaultOAuth2Manager(clientStore: MemoryClientStore(), tokenStore: store)
        let info = TokenInfo(clientId: "1", userId: "u")
        info.access = "valid-access"
        info.accessCreateAt = DateTime.now()
        info.accessExpiredIn = (Duration.hour * 2).toSeconds()
        info.refresh = "expired-refresh"
        info.refreshCreateAt = DateTime.now().addSeconds(-10)
        info.refreshExpiredIn = 1
        store.create(info)

        let loaded = manager.loadAccessToken(info.access)
        @Assert(loaded.access, info.access)
    }

    /**
     * 测试刷新令牌与客户端绑定 - 不允许用其他客户端的 clientId 刷新
     */
    @TestCase
    public func testRefreshTokenClientBinding() {
        let store = MemoryTokenStore()
        let manager = DefaultOAuth2Manager(clientStore: createManagerClientStore(), tokenStore: store)
        let info = TokenInfo(clientId: "1", userId: "u")
        info.refresh = "refresh-token"
        info.refreshCreateAt = DateTime.now()
        info.refreshExpiredIn = (Duration.hour).toSeconds()
        store.create(info)

        let tgr = TokenGenerateRequest(request: mock<JoyContext>(), clientId: "2", refresh: info.refresh)
        try {
            manager.refreshAccessToken(tgr)
            @Fail("should reject refresh token from another client")
        } catch (ex: OAuthException) {
            @Assert(ex.errorInfo.code, OAuthErrors.INVALID_CLIENT.code)
        }
    }

    private func createManagerClientStore(): ClientStore {
        let clientStore = MemoryClientStore()
        clientStore.add(ClientInfo(id: "1", secret: "11", domain: "http://localhost"))
        clientStore.add(ClientInfo(id: "2", secret: "22", domain: "http://localhost"))
        clientStore
    }
}
