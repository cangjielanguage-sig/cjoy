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
import std.sync.Mutex
import cjoy.log.macros.*

@JoyCreateLogger("cjoy.oauth2")

/**
 * OAuth2Manager 接口用于授权管理
 */
public interface OAuth2Manager {
    /**
     * 根据客户端 ID 获取客户端信息
     *
     * @param clientId 客户端 ID
     * @return 客户端信息
     * @throws OAuthException 如果客户端未找到
     */
    func getClient(clientId: String): ClientInfo

    /**
     * 生成授权令牌
     *
     * @param rt 响应类型
     * @param request 令牌生成请求
     * @return 生成的令牌信息
     * @throws OAuthException 如果生成失败
     */
    func generateAuthToken(rt: ResponseType, request: TokenGenerateRequest): TokenInfo

    /**
     * 生成访问令牌
     *
     * @param gt 授权类型
     * @param request 令牌生成请求
     * @return 生成的令牌信息
     * @throws OAuthException 如果生成失败
     */
    func generateAccessToken(gt: GrantType, request: TokenGenerateRequest): TokenInfo

    /**
     * 刷新访问令牌
     *
     * @param request 令牌生成请求
     * @return 刷新后的令牌信息
     * @throws OAuthException 如果刷新失败
     */
    func refreshAccessToken(request: TokenGenerateRequest): TokenInfo

    /**
     * 移除访问令牌
     *
     * @param access 要移除的访问令牌
     * @throws OAuthException 如果令牌无效
     */
    func removeAccessToken(access: String): Unit

    /**
     * 移除刷新令牌
     *
     * @param refresh 要移除的刷新令牌
     * @throws OAuthException 如果令牌无效
     */
    func removeRefreshToken(refresh: String): Unit

    /**
     * 加载并验证访问令牌
     *
     * @param access 访问令牌
     * @return 令牌信息
     * @throws OAuthException 如果令牌无效或已过期
     */
    func loadAccessToken(access: String): TokenInfo

    /**
     * 加载并验证刷新令牌
     *
     * @param refresh 刷新令牌
     * @return 令牌信息
     * @throws OAuthException 如果令牌无效或已过期
     */
    func loadRefreshToken(refresh: String): TokenInfo
}

/**
 * 默认的 OAuth2 管理器实现
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
    // 授权码校验与删除必须原子执行，防止同一授权码被并发兑换两次
    private let _codeMutex = Mutex()

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
     * 为特定授权类型设置授权配置
     *
     * @param grantType 授权类型
     * @param config 授权配置
     */
    public func setGrantConfig(grantType: GrantType, config: GrantConfig) {
        _gtcfg.add(grantType, config)
    }

    /**
     * 获取特定授权类型的授权配置
     *
     * @param grantType 授权类型
     * @return 授权配置
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
     * 设置刷新令牌配置
     *
     * @param config 刷新配置
     */
    public func setRefreshingConfig(config: RefreshingConfig) {
        _rfcfg = config
    }

    /**
     * 根据客户端 ID 获取客户端信息
     *
     * @param clientId 客户端 ID
     * @return 客户端信息
     * @throws OAuthException 如果客户端未找到
     */
    public func getClient(clientId: String): ClientInfo {
        let client = _clientStore.getById(clientId)
        if (let Some(c) <- client) {
            c
        } else {
            @JoyLogWarn("[OAuth2] not found clientId, ${clientId}")
            throw OAuthException(OAuthErrors.INVALID_CLIENT)
        }
    }

    /**
     * 生成授权令牌
     *
     * @param rt 响应类型
     * @param request 令牌生成请求
     * @return 令牌信息
     * @throws OAuthException 如果生成失败
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
     * 生成访问令牌
     *
     * @param gt 授权类型
     * @param request 令牌生成请求
     * @return 令牌信息
     * @throws OAuthException 如果生成失败
     */
    public func generateAccessToken(gt: GrantType, request: TokenGenerateRequest): TokenInfo {
        let client = getClient(request.clientId)
        if (let Some(verifier) <- _clientPasswordVerifier) {
            if (!verifier.verifyPassword(client, request.clientSecret)) {
                @JoyLogError("[OAuth2] verify password failed")
                throw OAuthException(OAuthErrors.INVALID_CLIENT)
            }
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
     * 刷新访问令牌
     *
     * @param request 令牌生成请求
     * @return 令牌信息
     * @throws OAuthException 如果刷新失败
     */
    public func refreshAccessToken(request: TokenGenerateRequest): TokenInfo {
        let token = loadRefreshToken(request.refresh)
        if (request.clientId != "" && request.clientId != token.clientId) {
            @JoyLogError("[OAuth2] refresh token belongs to another client")
            throw OAuthException(OAuthErrors.INVALID_CLIENT)
        }
        let client = getClient(token.clientId)
        var (oa, or) = (token.access, token.refresh)

        let td = GenerateBasic(client: client, userId: token.userId, createAt: DateTime.now(), tokenInfo: token,
            request: request.request)
        token.accessCreateAt = td.createAt
        if (_rfcfg.accessTokenExp > Duration.Zero) {
            token.accessExpiredIn = _rfcfg.accessTokenExp.toSeconds()
        }
        if (_rfcfg.refreshTokenExp > Duration.Zero) {
            token.refreshExpiredIn = _rfcfg.refreshTokenExp.toSeconds()
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

        if (_rfcfg.isRemoveAccess) {
            _tokenStore.removeByAccess(oa)
        }
        if (_rfcfg.isRemoveRefreshing) {
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
     * 移除访问令牌
     *
     * @param access 要移除的访问令牌
     * @throws OAuthException 如果令牌为空
     */
    public func removeAccessToken(access: String): Unit {
        if (access.isEmpty()) {
            @JoyLogError("[OAuth2] remove access token but it is empty")
            throw OAuthException(OAuthErrors.INVALID_ACCESS_TOKEN)
        }

        _tokenStore.removeByAccess(access)
    }

    /**
     * 移除刷新令牌
     *
     * @param refresh 要移除的刷新令牌
     * @throws OAuthException 如果令牌为空
     */
    public func removeRefreshToken(refresh: String): Unit {
        if (refresh.isEmpty()) {
            @JoyLogError("[OAuth2] remove refresh token but it is empty")
            throw OAuthException(OAuthErrors.INVALID_REFRESH_TOKEN)
        }

        _tokenStore.removeByRefresh(refresh)
    }

    /**
     * 加载访问令牌并验证
     *
     * @param access 访问令牌
     * @return 令牌信息
     * @throws OAuthException 如果令牌无效或已过期
     */
    public func loadAccessToken(access: String): TokenInfo {
        if (access.isEmpty()) {
            @JoyLogError("[OAuth2] load access token but it is empty")
            throw OAuthException(OAuthErrors.INVALID_ACCESS_TOKEN)
        }

        let ct = DateTime.now()
        let token = _tokenStore.getByAccess(access).getOrThrow(
            {
                =>
                    @JoyLogError("[OAuth2] not found access token in token store")
                    OAuthException(OAuthErrors.INVALID_ACCESS_TOKEN)
            }
        )

        if (token.access != access) {
            @JoyLogError("[OAuth2] access is not equal")
            throw OAuthException(OAuthErrors.INVALID_ACCESS_TOKEN)
        }

        // 资源访问只校验 access token 本身，refresh token 过期不影响仍有效的 access token
        if (token.accessExpiredIn != 0 && token.accessCreateAt.addSeconds(token.accessExpiredIn) < ct) {
            @JoyLogError("[OAuth2] expired access token, create at ${token.accessCreateAt}")
            throw OAuthException(OAuthErrors.EXPIRED_ACCESS_TOKEN)
        }

        token
    }

    /**
     * 加载刷新令牌并验证
     *
     * @param refresh 刷新令牌
     * @return 令牌信息
     * @throws OAuthException 如果令牌无效或已过期
     */
    public func loadRefreshToken(refresh: String): TokenInfo {
        if (refresh.isEmpty()) {
            @JoyLogError("[OAuth2] load refresh token but it is empty")
            throw OAuthException(OAuthErrors.INVALID_REFRESH_TOKEN)
        }

        let ct = DateTime.now()
        let token = _tokenStore.getByRefresh(refresh).getOrThrow(
            {
                =>
                    @JoyLogError("[OAuth2] not found refresh token in token store")
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
        synchronized(_codeMutex) {
            let code = request.code
            let token = getAuthorizationCode(code)
            if (token.clientId != request.clientId) {
                @JoyLogError("[OAuth2] the clientId is not same, token's ${token.clientId} != ${request.clientId} in request")
                throw OAuthException(OAuthErrors.INVALID_AUTHORIZE_CODE)
            } else if (token.redirectURI != "" && token.redirectURI != request.redirectURI) {
                @JoyLogError("[OAuth2] the redirectURI is not same, token's ${token.redirectURI} != ${request.redirectURI} in request")
                throw OAuthException(OAuthErrors.INVALID_AUTHORIZE_CODE)
            }

            // 先校验 PKCE，失败时保留授权码，避免一次错误请求使合法客户端无法再次兑换
            validateCodeChallenge(token, request.codeVerifier)
            removeAuthorizationCode(code)
            token
        }
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
            @JoyLogError("[OAuth2] miss code codeChallenge")
            throw OAuthException(OAuthErrors.MISSING_CODE_CHALLENGE)
        }
        var ccm = token.codeChallengeMethod
        if (ccm == "") {
            ccm = OAuthConsts.CODE_CHALLENGE_PLAIN
        }
        @JoyLogDebug("[OAuth2], code_challenge=${cc}, verfiy_code=${ver}, method=${ccm}")
        if (!ccm.validate(cc, ver)) {
            @JoyLogError("[OAuth2] validate code codeChallenge failed")
            throw OAuthException(OAuthErrors.INVALID_CODE_CHALLENGE)
        }
    }
}
