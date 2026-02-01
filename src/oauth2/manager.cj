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

import std.collection.HashMap
import std.time.DateTime
import cjoy.log.macros.*

@JoyCreateLogger("cjoy.oauth2")

/**
 * authorization management
 */
public interface OAuth2Manager {
    func getClient(clientId: String): ClientInfo
    func generateAuthToken(rt: ResponseType, request: TokenGenerateRequest): TokenInfo
    func generateAccessToken(gt: GrantType, request: TokenGenerateRequest): TokenInfo
    func refreshAccessToken(request: TokenGenerateRequest): TokenInfo
    func removeAccessToken(access: String): Unit
    func removeRefreshToken(refresh: String): Unit
    func loadAccessToken(access: String): TokenInfo
    func loadRefreshToken(refresh: String): TokenInfo
}

/**
 * Default OAuth2 manager implementation
 */
public class DefaultOAuth2Manager <: OAuth2Manager {
    private let _clientStore: ClientStore
    private let _tokenStore: TokenStore
    private let _tokenGenerate: TokenGenerate
    private let _codeGenerate: CodeGenerate
    private let _validateURIFunc: ValidateURIFunc
    private let _clientPasswordVerifier: ?ClientPasswordVerifier

    private let _gtcfg: HashMap<GrantType, GrantConfig> = HashMap()
    private var _rfcfg: RefreshingConfig = GrantConfig.REFRESH_CODE_TOKEN_CFG
    private var _extractExtension: ?ExtractExtensionHandler = None

    private let _codeExpire: Duration

    public init(
        clientStore!: ClientStore = MemoryClientStore(),
        tokenStore!: TokenStore = MemoryTokenStore(),
        tokenGenerate!: TokenGenerate = SecureRandTokenGenerate(),
        codeGenerate!: CodeGenerate = SecureRandCodeGenerate(),
        validateURIFunc!: ValidateURIFunc = defaultValidateURIFunc,
        codeExpire!: Duration = GrantConfig.CODE_EXP,
        clientPasswordVerifier!: ?ClientPasswordVerifier = None
    ) {
        _clientStore = clientStore
        _tokenStore = tokenStore
        _tokenGenerate = tokenGenerate
        _codeGenerate = codeGenerate
        _validateURIFunc = validateURIFunc
        _codeExpire = codeExpire
        _clientPasswordVerifier = clientPasswordVerifier
    }

    /**
     * set grant config for a specific grant type
     *
     * @param grantType:  grant type
     * @param config:  grant configuration
     */
    public func setGrantConfig(grantType: GrantType, config: GrantConfig) {
        _gtcfg.add(grantType, config)
    }

    /**
     * get grant config for a specific grant type
     *
     * @param grantType:  grant type
     * @return:  grant configuration
     */
    public func getGrantConfig(grantType: GrantType): GrantConfig {
        let cfg = _gtcfg.get(grantType)
        match (cfg) {
            case Some(c) => c
            case _ => match (grantType) {
                case "authorization_code" => GrantConfig.AUTHORIZE_CODE_TOKEN_CFG
                case "__implicit" => GrantConfig.IMPLICIT_CODE_TOKEN_CFG
                case "password" => GrantConfig.PASSWOD_CODE_TOKEN_CFG
                case "client_credentials" => GrantConfig.CLIENT_CODE_TOKEN_CFG
                case _ => GrantConfig(Duration.hour, Duration.hour, false)
            }
        }
    }

    /**
     * set refresh token config
     *
     * @param config:  refreshing configuration
     */
    public func setRefreshingConfig(config: RefreshingConfig) {
        _rfcfg = config
    }

    /**
     * get client info by id
     *
     * @param clientId:  client id
     * @return:  client info
     * @throws OAuthException if client not found
     */
    public func getClient(clientId: String): ClientInfo {
        let client = _clientStore.getById(clientId)
        if (let Some(c) <- client) {
            c
        } else {
            throw OAuthException(OAuthErrors.INVALID_CLIENT)
        }
    }

    /**
     * generate authorization token
     *
     * @param rt:  response type
     * @param request:  token generation request
     * @return:  token info
     * @throws OAuthException if generation fails
     */
    public func generateAuthToken(rt: ResponseType, request: TokenGenerateRequest): TokenInfo {
        let client = getClient(request.clientId)
        if (request.redirectURI != "") {
            _validateURIFunc(client.domain, request.redirectURI)
        }

        let token = TokenInfo(clientId: request.clientId, userId: request.userId, redirectURI: request.redirectURI,
            scope: request.scope)
        _extractExtension?(request, token)

        let createAt = DateTime.now()
        let td = GenerateBasic(client: client, userId: request.userId, createAt: createAt, tokenInfo: token,
            request: request.request)
        match (rt) {
            case "code" =>
                token.codeCreateAt = createAt
                token.codeExpiredIn = _codeExpire.toSeconds()
                if (request.accessTokenExp > Duration.Zero) {
                    token.accessExpiredIn = request.accessTokenExp.toSeconds()
                }
                if (request.codeChallenge != "") {
                    token.codeChallenge = request.codeChallenge
                    token.codeChallengeMethod = request.codeChallengeMethod
                }
                token.code = _codeGenerate.generate(td)
            case "token" =>
                let icfg = getGrantConfig(OAuthConsts.GRANT_TYPE_IMPLICIT)
                var aexp = icfg.accessTokenExp
                if (request.accessTokenExp > Duration.Zero) {
                    aexp = request.accessTokenExp
                }
                token.accessCreateAt = createAt
                token.accessExpiredIn = aexp.toSeconds()
                if (icfg.isGenerateRefresh) {
                    token.refreshCreateAt = createAt
                    token.refreshExpiredIn = icfg.refreshTokenExp.toSeconds()
                }
                let (at, rt) = _tokenGenerate.generate(td, icfg.isGenerateRefresh)
                token.access = at
                token.refresh = rt
            case _ =>
                @JoyLogError("[OAuth2] unsupported response type, ${rt}")
                throw OAuthException(OAuthErrors.UNSUPPORTED_RESP_TYPE)
        }

        _tokenStore.create(token)
        token
    }

    /**
     * generate access token
     *
     * @param gt:  grant type
     * @param request:  token generation request
     * @return:  token info
     * @throws OAuthException if generation fails
     */
    public func generateAccessToken(gt: GrantType, request: TokenGenerateRequest): TokenInfo {
        let client = getClient(request.clientId)
        if (!(_clientPasswordVerifier?.verifyPassword(client, request.clientSecret) ?? true)) {
            throw OAuthException(OAuthErrors.INVALID_CLIENT)
        } else if (client.secret != "" && request.clientSecret != client.secret) {
            @JoyLogError("[OAuth2] invalid client, client secret is invalid")
            throw OAuthException(OAuthErrors.INVALID_CLIENT)
        }

        if (request.redirectURI != "") {
            _validateURIFunc(client.domain, request.redirectURI)
        }

        if (gt == OAuthConsts.GRANT_TYPE_CLIENT_CREDENTIALS && client.isPublic) {
            @JoyLogError("[OAuth2] invalid client, client is public but grant type is client_credentials")
            throw OAuthException(OAuthErrors.INVALID_CLIENT)
        }

        var extension = HashMap<String, String>()
        match (gt) {
            case "authorization_code" =>
                let token = getAndDelAuthorizationCode(request)
                validateCodeChallenge(token, request.codeVerifier)
                request.userId = token.userId
                request.scope = token.scope
                if (token.accessExpiredIn > 0) {
                    request.accessTokenExp = Duration.second * token.accessExpiredIn
                }
                extension = token.extension
            case _ => ()
        }

        let createAt = DateTime.now()
        let token = TokenInfo(clientId: request.clientId, userId: request.userId, redirectURI: request.redirectURI,
            scope: request.scope, accessCreateAt: createAt, extension: extension)
        _extractExtension?(request, token)

        let gcfg = getGrantConfig(gt)
        var aexp = gcfg.accessTokenExp
        if (request.accessTokenExp > Duration.Zero) {
            aexp = request.accessTokenExp
        }
        token.accessExpiredIn = aexp.toSeconds()
        if (gcfg.isGenerateRefresh) {
            token.refreshCreateAt = createAt
            token.refreshExpiredIn = gcfg.refreshTokenExp.toSeconds()
        }

        let td = GenerateBasic(client: client, userId: request.userId, createAt: createAt, tokenInfo: token,
            request: request.request)
        let (at, rt) = _tokenGenerate.generate(td, gcfg.isGenerateRefresh)
        token.access = at
        token.refresh = rt

        _tokenStore.create(token)

        token
    }

    /**
     * refresh access token
     *
     * @param request:  token generation request
     * @return:  token info
     * @throws OAuthException if refresh fails
     */
    public func refreshAccessToken(request: TokenGenerateRequest): TokenInfo {
        let token = loadRefreshToken(request.refresh)
        let client = getClient(token.clientId)
        var (oa, or) = (token.access, token.refresh)

        let td = GenerateBasic(client: client, userId: token.userId, createAt: DateTime.now(), tokenInfo: token,
            request: request.request)
        token.accessCreateAt = td.createAt
        if (_rfcfg.accessTokenExp > Duration.Zero) {
            token.accessExpiredIn = _rfcfg.accessTokenExp.toSeconds()
        }
        if (_rfcfg.accessTokenExp > Duration.Zero) {
            token.accessExpiredIn = _rfcfg.accessTokenExp.toSeconds()
        }
        if (_rfcfg.isResetRefreshTime) {
            token.refreshCreateAt = td.createAt
        }
        if (request.scope != "") {
            token.scope = request.scope
        }
        let (at, rt) = _tokenGenerate.generate(td, _rfcfg.isGenerateRefresh)
        token.access = at
        token.refresh = rt

        _tokenStore.create(token)

        if (_rfcfg.isRemoveRefreshing) {
            _tokenStore.removeByAccess(oa)
        }
        if (_rfcfg.isRemoveRefreshing && at != "") {
            _tokenStore.removeByRefresh(or)
        }
        if (rt == "") {
            token.refresh = ""
            token.refreshCreateAt = DateTime.now()
            token.refreshExpiredIn = 0
        }

        token
    }

    /**
     * remove access token
     *
     * @param access:  access token to remove
     * @throws OAuthException if token is empty
     */
    public func removeAccessToken(access: String): Unit {
        if (access == "") {
            throw OAuthException(OAuthErrors.INVALID_ACCESS_TOKEN)
        }

        _tokenStore.removeByAccess(access)
    }

    /**
     * remove refresh token
     *
     * @param refresh:  refresh token to remove
     * @throws OAuthException if token is empty
     */
    public func removeRefreshToken(refresh: String): Unit {
        if (refresh == "") {
            throw OAuthException(OAuthErrors.INVALID_REFRESH_TOKEN)
        }

        _tokenStore.removeByRefresh(refresh)
    }

    /**
     * load access token and validate it
     *
     * @param access:  access token
     * @return:  token info
     * @throws OAuthException if token is invalid or expired
     */
    public func loadAccessToken(access: String): TokenInfo {
        if (access == "") {
            throw OAuthException(OAuthErrors.INVALID_ACCESS_TOKEN)
        }

        let ct = DateTime.now()
        let token = _tokenStore.getByAccess(access).getOrThrow({
            => OAuthException(OAuthErrors.INVALID_ACCESS_TOKEN)
        })

        if (token.access != access) {
            throw OAuthException(OAuthErrors.INVALID_ACCESS_TOKEN)
        }

        if (token.refresh != "" && token.refreshExpiredIn != 0 &&
            token.refreshCreateAt.addSeconds(token.refreshExpiredIn) < ct) {
            @JoyLogError("[OAuth2] expired refresh token, create at ${token.refreshCreateAt}")
            throw OAuthException(OAuthErrors.EXPIRED_REFRESHT_OKEN)
        } else if (token.accessExpiredIn != 0 && token.accessCreateAt.addSeconds(token.accessExpiredIn) < ct) {
            @JoyLogError("[OAuth2] expired access token, create at ${token.accessCreateAt}")
            throw OAuthException(OAuthErrors.EXPIRED_ACCESS_TOKEN)
        }

        token
    }

    /**
     * load refresh token and validate it
     *
     * @param refresh:  refresh token
     * @return:  token info
     * @throws OAuthException if token is invalid or expired
     */
    public func loadRefreshToken(refresh: String): TokenInfo {
        if (refresh == "") {
            @JoyLogError("[OAuth2] refresh token is empty")
            throw OAuthException(OAuthErrors.INVALID_REFRESH_TOKEN)
        }

        let ct = DateTime.now()
        let token = _tokenStore
            .getByRefresh(refresh)
            .getOrThrow(
                {
                    =>
                    @JoyLogError("[OAuth2] not found refresh token")
                    OAuthException(OAuthErrors.INVALID_REFRESH_TOKEN)
                }
            )

        if (token.refresh != refresh) {
            @JoyLogError("[OAuth2] refresh token is not equal")
            throw OAuthException(OAuthErrors.INVALID_REFRESH_TOKEN)
        }

        if (token.refresh != "" && token.refreshExpiredIn != 0 &&
            token.refreshCreateAt.addSeconds(token.refreshExpiredIn) < ct) {
            @JoyLogError("[OAuth2] expired refresh token, create at ${token.refreshCreateAt}")
            throw OAuthException(OAuthErrors.EXPIRED_REFRESHT_OKEN)
        }
        token
    }

    private func getAndDelAuthorizationCode(request: TokenGenerateRequest): TokenInfo {
        let code = request.code
        let token = getAuthorizationCode(code)
        if (token.clientId != request.clientId) {
            throw OAuthException(OAuthErrors.INVALID_AUTHORIZE_CODE)
        } else if (token.redirectURI != "" && token.redirectURI != request.redirectURI) {
            throw OAuthException(OAuthErrors.INVALID_AUTHORIZE_CODE)
        }

        removeAuthorizationCode(code)
        token
    }

    private func getAuthorizationCode(code: String): TokenInfo {
        let token = _tokenStore.getByCode(code).getOrThrow({=> OAuthException(OAuthErrors.INVALID_AUTHORIZE_CODE)})
        if (token.code != code || token.codeCreateAt.addSeconds(token.codeExpiredIn) < DateTime.now()) {
            @JoyLogError("[OAuth2] expired authorize code, create at ${token.codeCreateAt}")
            throw OAuthException(OAuthErrors.INVALID_AUTHORIZE_CODE)
        }
        token
    }

    private func removeAuthorizationCode(code: String): Unit {
        _tokenStore.removeByCode(code)
    }

    private func validateCodeChallenge(token: TokenInfo, ver: String): Unit {
        let cc = token.codeChallenge
        if (cc == "" && ver == "") {
            return
        }
        if (cc == "") {
            throw OAuthException(OAuthErrors.MISSING_CODE_CHALLENGE)
        }
        var ccm = token.codeChallengeMethod
        if (ccm == "") {
            ccm = OAuthConsts.CODE_CHALLENGE_PLAIN
        }
        @JoyLogDebug("[OAuth2], code_challenge=${cc}, verfiy_code=${ver}, method=${ccm}")
        if (!ccm.validate(cc, ver)) {
            throw OAuthException(OAuthErrors.INVALID_CODE_CHALLENGE)
        }
    }
}
