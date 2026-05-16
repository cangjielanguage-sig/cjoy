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

import std.collection.{HashMap, any}
import stdx.encoding.url.{URL, Form}
import stdx.net.http.HttpStatusCode
import cjoy.framework.{JoyContext, JoyHttpConsts}
import cjoy.json.*
import cjoy.log.macros.*

/**
 * OAuth2 服务器实现，用于处理授权和令牌请求
 */
public class OAuth2Server {
    private let _cfg: ServerConfig
    private let _manager: OAuth2Manager

    private var _clientInfoHandleFunc: ClientInfoHandleFunc
    private var _userAuthorizationHandleFunc: UserAuthorizationHandleFunc
    private var _passwordAuthorizationHanleFunc: PasswordAuthorizationHandleFunc
    private var _responseErrorHandleFunc: ResponseErrorHandleFunc
    private var _internalErrorHandleFunc: InternalErrorHandleFunc
    private var _accessTokenResolveHandleFunc: AccessTokenResolveHandleFunc
    private var _refreshTokenResolveHandleFunc: RefreshTokenResolveHandleFunc

    private var _clientAuthorizedHandleFunc: ?ClientAuthorizedHandleFunc = None
    private var _clientScopeHandleFunc: ?ClientScopeHandleFunc = None
    private var _refreshingValidationHandleFunc: ?RefreshingValidationHandleFunc = None
    private var _preRedirectErrorHandleFunc: ?PreRedirectErrorHandleFunc = None
    private var _extensionFieldsHandleFunc: ?ExtensionFieldsHandleFunc = None
    private var _accessTokenExpHandleFunc: ?AccessTokenExpHandleFunc = None
    private var _authorizeScopeHandleFunc: ?AuthorizeScopeHandleFunc = None
    private var _responseTokenHandleFunc: ?ResponseTokenHandleFunc = None
    private var _refreshingScopeHandleFunc: ?RefreshingScopeHandleFunc = None

    public init(manager: OAuth2Manager, cfg!: ServerConfig = ServerConfig()) {
        _cfg = cfg
        _manager = manager

        _clientInfoHandleFunc = clientBasicHandleFunc
        _refreshTokenResolveHandleFunc = refreshTokenFormResolveHandleFunc
        _accessTokenResolveHandleFunc = accessTokenDefaultResolveHandleFunc
        _internalErrorHandleFunc = defaultInternalErrorHandleFunc
        _responseErrorHandleFunc = defaultResponseErrorHandleFunc
        _userAuthorizationHandleFunc = {
            _: JoyContext => throw OAuthException(OAuthErrors.ACCESS_DENIED)
        }
        _passwordAuthorizationHanleFunc = {
            _: JoyContext, _: String, _: String, _: String => throw OAuthException(OAuthErrors.ACCESS_DENIED)
        }
    }

    /**
     * 设置 OAuth2 的令牌类型
     *
     * @param tt 令牌类型字符串
     */
    public func setTokenType(tt: String): Unit {
        _cfg.tokenType = tt
    }

    /**
     * 设置是否允许使用 GET 方法请求令牌
     *
     * @param allow 允许为 true，否则为 false
     */
    public func setAllowGetAccessRequest(allow: Bool): Unit {
        _cfg.allowGetAccessRequest = allow
    }

    /**
     * 设置允许的响应类型
     *
     * @param types 响应类型数组
     */
    public func setAllowedResponseType(types: Array<ResponseType>): Unit {
        _cfg.allowResponseTypes = types
    }

    /**
     * 设置允许的授权类型
     *
     * @param types 授权类型数组
     */
    public func setAllowedGrantType(types: Array<GrantType>): Unit {
        _cfg.allowGrantTypes = types
    }

    /**
     * 设置获取客户端信息的函数
     *
     * @param fn 获取客户端信息的函数
     */
    public func setClientInfoHandleFunc(fn: ClientInfoHandleFunc): Unit {
        _clientInfoHandleFunc = fn
    }

    /**
     * 设置用户授权函数
     *
     * @param fn 用户授权函数
     */
    public func setUserAuthorizationHandleFunc(fn: UserAuthorizationHandleFunc): Unit {
        _userAuthorizationHandleFunc = fn
    }

    /**
     * 设置密码授权函数
     *
     * @param fn 密码授权函数
     */
    public func setPasswordAuthorizationHandleFunc(fn: PasswordAuthorizationHandleFunc): Unit {
        _passwordAuthorizationHanleFunc = fn
    }

    /**
     * 设置响应错误处理函数
     *
     * @param fn 响应错误处理函数
     */
    public func setResponseErrorHandleFunc(fn: ResponseErrorHandleFunc): Unit {
        _responseErrorHandleFunc = fn
    }

    /**
     * 设置内部错误处理函数
     *
     * @param fn 内部错误处理函数
     */
    public func setInternalErrorHandleFunc(fn: InternalErrorHandleFunc): Unit {
        _internalErrorHandleFunc = fn
    }

    /**
     * 设置访问令牌解析函数
     *
     * @param fn 访问令牌解析函数
     */
    public func setAccessTokenResolveHandleFunc(fn: AccessTokenResolveHandleFunc): Unit {
        _accessTokenResolveHandleFunc = fn
    }

    /**
     * 设置刷新令牌验证函数
     *
     * @param fn 刷新令牌验证函数
     */
    public func setRefreshTokenResolveHandleFunc(fn: RefreshingValidationHandleFunc): Unit {
        _refreshingValidationHandleFunc = fn
    }

    /**
     * 设置客户端授权检查函数
     *
     * @param fn 客户端授权检查函数
     */
    public func setClientAuthorizedHandleFunc(fn: ClientAuthorizedHandleFunc): Unit {
        _clientAuthorizedHandleFunc = fn
    }

    /**
     * 设置客户端范围检查函数
     *
     * @param fn 客户端范围检查函数
     */
    public func setClientScopeHandleFunc(fn: ClientScopeHandleFunc): Unit {
        _clientScopeHandleFunc = fn
    }

    /**
     * 设置刷新令牌验证函数
     *
     * @param fn 刷新令牌验证函数
     */
    public func setRefreshingValidationHandleFunc(fn: RefreshingValidationHandleFunc): Unit {
        _refreshingValidationHandleFunc = fn
    }

    /**
     * 设置重定向前错误处理函数
     *
     * @param fn 重定向前错误处理函数
     */
    public func setPreRedirectErrorHandleFunc(fn: PreRedirectErrorHandleFunc): Unit {
        _preRedirectErrorHandleFunc = fn
    }

    /**
     * 设置扩展字段处理函数
     *
     * @param fn 扩展字段处理函数
     */
    public func setExtensionFieldsHandleFunc(fn: ExtensionFieldsHandleFunc): Unit {
        _extensionFieldsHandleFunc = fn
    }

    /**
     * 设置访问令牌过期时间函数
     *
     * @param fn 访问令牌过期时间函数
     */
    public func setAccessTokenExpHandleFunc(fn: AccessTokenExpHandleFunc): Unit {
        _accessTokenExpHandleFunc = fn
    }

    /**
     * 设置授权范围函数
     *
     * @param fn 授权范围函数
     */
    public func setAuthorizeScopeHandleFunc(fn: AuthorizeScopeHandleFunc): Unit {
        _authorizeScopeHandleFunc = fn
    }

    /**
     * 设置令牌响应处理函数
     *
     * @param fn 令牌响应处理函数
     */
    public func setResponseTokenHandleFunc(fn: ResponseTokenHandleFunc): Unit {
        _responseTokenHandleFunc = fn
    }

    /**
     * 设置刷新范围处理函数
     *
     * @param fn 刷新范围处理函数
     */
    public func setRefreshingScopeHandleFunc(fn: RefreshingScopeHandleFunc): Unit {
        _refreshingScopeHandleFunc = fn
    }

    /**
     * 处理授权 HTTP 请求，您可以将此函数绑定到 `/authorize` 路径
     */
    public func authorizeRequestHandleFunc(ctx: JoyContext): Unit {
        try {
            let req = validateAuthorizeRequest(ctx)
            let userId = _userAuthorizationHandleFunc(ctx)
            req.userId = userId
            let scope = _authorizeScopeHandleFunc?(ctx) ?? ""
            if (scope != "") {
                req.scope = scope
            }
            let exp = _accessTokenExpHandleFunc?(ctx) ?? Duration.Zero
            req.accessTokenExp = exp

            let ti = getAuthorizeToken(ctx, req)
            if (req.redirectURI == "") {
                let client = _manager.getClient(req.clientId)
                req.redirectURI = client.domain
            }
            redirect(ctx, req, getAuthorizeData(req.responseType, ti))
        } catch (ex: OAuthException) {
            authorizeReturnError(ctx, None, ex.errorInfo)
        } catch (ex: Exception) {
            authorizeReturnError(ctx, None, OAuthErrors.SERVER_ERROR)
        }
    }

    private func authorizeReturnError(ctx: JoyContext, req: ?AuthorizeRequest, err: ErrorInfo) {
        if (let Some(h) <- _preRedirectErrorHandleFunc) {
            if (let Some(r) <- req) {
                h(ctx, r, err)
            }
        } else {
            redirectError(ctx, req, err)
        }
    }

    private func redirectError(ctx: JoyContext, req: ?AuthorizeRequest, err: ErrorInfo) {
        let data = getErrorData(ctx, err)
        if (let Some(r) <- req) {
            redirect(ctx, r, data)
        }
    }

    private func redirect(ctx: JoyContext, req: AuthorizeRequest, data: HashMap<String, JsonSerializable>) {
        let uri = getRedirectURI(req, data)
        ctx.header(JoyHttpConsts.HEADER_LOCATION, uri)
        ctx.status(HttpStatusCode.STATUS_FOUND)
    }

    private func getErrorData(ctx: JoyContext, ei: ErrorInfo): HashMap<String, JsonSerializable> {
        var err = ei
        if (err.description == "") {
            _internalErrorHandleFunc(ctx, err)
            err = OAuthErrors.SERVER_ERROR
        }

        let er = ErrorResponse(err)
        _responseErrorHandleFunc(ctx, er)

        let data = HashMap<String, JsonSerializable>(
            [("error_code", er.errorInfo.code), ("error_description", er.errorInfo.description)])
        if (er.error != "") {
            data.add("error", er.error)
        }
        if (er.uri != "") {
            data.add("error_uri", er.uri)
        }
        for ((k, v) in er.header) {
            ctx.header(k, v)
        }
        ctx.status(err.statusCode)
        data
    }

    /**
     * @throws OAuthException
     */
    private func getRedirectURI(req: AuthorizeRequest, data: HashMap<String, JsonSerializable>): String {
        var url = URL.parse(req.redirectURI)
        match (req.responseType) {
            case "code" =>
                let q = Form()
                if (req.state != "") {
                    q.add("state", req.state)
                }
                for ((k, v) in data) {
                    match (v) {
                        case x: String => q.add(k, x)
                        case x: Int64 => q.add(k, "${x}")
                        case _ => ()
                    }
                }
                url = url.replace(query: q.toEncodeString())
            case "token" =>
                let b = StringBuilder()
                if (req.state != "") {
                    b.append("state=", req.state)
                }
                for ((k, v) in data) {
                    let s: String = match (v) {
                        case x: String => x
                        case x: Int64 => "${x}"
                        case _ => ""
                    }
                    if (b.size > 0) {
                        b.append("&${k}=", s)
                    } else {
                        b.append("${k}=", s)
                    }
                }
                url = url.replace(query: "")
                url = url.replace(fragment: b.toString())
            case _ =>
                @JoyLogError("[OAuth2] unsupported_response_type, invalid response type ${req.responseType}")
                throw OAuthException(OAuthErrors.UNSUPPORTED_RESP_TYPE)
        }
        url.toString()
    }

    private func checkResponeType(rt: ResponseType): Bool {
        _cfg.allowResponseTypes |> any {it => it == rt}
    }

    private func checkGrantType(gt: GrantType): Bool {
        _cfg.allowGrantTypes |> any {it => it == gt}
    }

    private func checkCodeChallengeMethod(ccm: CodeChallengeMethod): Bool {
        _cfg.allowedCodeChallengeMethods |> any {it => it == ccm}
    }

    /**
     * @throws OAuthException
     */
    private func validateAuthorizeRequest(ctx: JoyContext): AuthorizeRequest {
        if (!(ctx.method == JoyHttpConsts.METHOD_GET || ctx.method == JoyHttpConsts.METHOD_POST)) {
            @JoyLogError("[OAuth2] invalid request, method(${ctx.method}) is invalid")
            throw OAuthException(OAuthErrors.INVALID_REQ)
        }
        let redirectURI = ctx.getForm("redirect_uri").getOrThrow {
            =>
                @JoyLogError("[OAuth2] invalid request, redirectURI is not existed")
                OAuthException(OAuthErrors.INVALID_REQ)
        }

        let clientId = validateClientId(ctx)
        let respType = validateResponeType(ctx)
        let cc = validateCodeChange(ctx)
        var ccm = validateCodeChangeMethod(ctx)
        let scope = ctx.getForm("scope") ?? ""
        let state = ctx.getForm("state") ?? ""

        AuthorizeRequest(responseType: respType, clientId: clientId, scope: scope, redirectURI: redirectURI,
            state: state, codeChallenge: cc, codeChallengeMethod: ccm, userId: "", accessTokenExp: Duration.Zero,
            request: ctx)
    }

    /**
     * @throws OAuthException
     */
    private func validateClientId(ctx: JoyContext): String {
        let clientId = ctx.getForm("client_id").getOrThrow {
            =>
                @JoyLogError("[OAuth2] invalid request, client_id is not existed")
                OAuthException(OAuthErrors.INVALID_REQ)
        }

        if (clientId == "") {
            @JoyLogError("[OAuth2] invalid request, clientId is empty")
            throw OAuthException(OAuthErrors.INVALID_REQ)
        }
        clientId
    }

    /**
     * @throws OAuthException
     */
    private func validateResponeType(ctx: JoyContext): String {
        let respType = ctx.getForm("response_type").getOrThrow {
            =>
                @JoyLogError("[OAuth2] invalid request, response_type is not existed")
                OAuthException(OAuthErrors.UNSUPPORTED_RESP_TYPE)
        }

        if (!checkResponeType(respType)) {
            @JoyLogError("[OAuth2] unauthorized_client, response type (${respType}) is invalid")
            throw OAuthException(OAuthErrors.UNAUTHORIZED_CLIENT)
        }
        respType
    }

    /**
     * @throws OAuthException
     */
    private func validateCodeChange(ctx: JoyContext): String {
        let cc = ctx.getForm("code_challenge") ?? ""
        if (cc == "" && _cfg.forcePKCE) {
            @JoyLogError("[OAuth2] invalid_request, code_challenge is empty")
            throw OAuthException(OAuthErrors.CODE_CHALLENG_ERQUIRED)
        }
        if (cc != "" && cc.size < 43 || cc.size > 128) {
            @JoyLogError("[OAuth2] invalid_request, code_challenge len (${cc.size}) is invalid")
            throw OAuthException(OAuthErrors.INVALID_CODE_CHALLENGE_LEN)
        }
        cc
    }

    /**
     * @throws OAuthException
     */
    private func validateCodeChangeMethod(ctx: JoyContext): String {
        var ccm = ctx.getForm("code_challenge_method") ?? ""
        if (ccm == "") {
            ccm = OAuthConsts.CODE_CHALLENGE_PLAIN
        }
        if (ccm != "" && !checkCodeChallengeMethod(ccm)) {
            @JoyLogError("[OAuth2] invalid_request, code_challenge_method l (${ccm}) is invalid")
            throw OAuthException(OAuthErrors.UNSUPPORTED_CODE_CHALLENGE_METHOD)
        }
        ccm
    }

    /**
     * @throws OAuthException
     */
    private func getAuthorizeToken(ctx: JoyContext, req: AuthorizeRequest): TokenInfo {
        let gt = if (req.responseType == OAuthConsts.RESPONSE_TYPE_CODE) {
            OAuthConsts.GRANT_TYPE_AUTHORIZATION_CODE
        } else {
            OAuthConsts.GRANT_TYPE_IMPLICIT
        }
        var allowed = _clientAuthorizedHandleFunc?(req.clientId, gt) ?? true
        if (!allowed) {
            @JoyLogError("[OAuth2] client authorized handle return not allowed")
            throw OAuthException(OAuthErrors.UNAUTHORIZED_CLIENT)
        }

        let tgr = TokenGenerateRequest(
            request: ctx,
            clientId: req.clientId,
            userId: req.userId,
            redirectURI: req.redirectURI,
            scope: req.scope,
            accessTokenExp: req.accessTokenExp
        )

        allowed = _clientScopeHandleFunc?(tgr) ?? true
        if (!allowed) {
            throw OAuthException(OAuthErrors.INVALID_SCOPE)
        }
        tgr.codeChallenge = req.codeChallenge
        tgr.codeChallengeMethod = req.codeChallengeMethod

        _manager.generateAuthToken(req.responseType, tgr)
    }

    private func getAuthorizeData(rt: ResponseType, token: TokenInfo): HashMap<String, JsonSerializable> {
        if (rt == OAuthConsts.RESPONSE_TYPE_CODE) {
            HashMap<String, JsonSerializable>([("code", token.code)])
        } else {
            getTokenData(token)
        }
    }

    private func getTokenData(token: TokenInfo): HashMap<String, JsonSerializable> {
        let data = HashMap<String, JsonSerializable>(
            [("access_token", token.access), ("token_type", _cfg.tokenType), ("expires_in", token.accessExpiredIn)])
        if (token.scope != "") {
            data["code"] = token.scope
        }
        if (token.refresh != "") {
            data["refresh_token"] = token.refresh
        }

        let ext = _extensionFieldsHandleFunc?(token) ?? HashMap<String, JsonSerializable>()
        for ((k, v) in ext) {
            if (data.get(k).isNone()) {
                data[k] = v
            }
        }
        data
    }

    /**
     * 处理令牌 HTTP 请求，您可以将此函数绑定到 `/token` 路径
     */
    public func tokenRequestHandleFunc(ctx: JoyContext): Unit {
        try {
            let (gt, tgr) = validateTokenRequest(ctx)
            let ti = getAccessToken(ctx, gt, tgr)
            tokenReturn(ctx, getTokenData(ti))
        } catch (ex: OAuthException) {
            tokenReturnError(ctx, ex.errorInfo)
        } catch (ex: Exception) {
            tokenReturnError(ctx, OAuthErrors.SERVER_ERROR)
        }
    }
    /**
     * @throws OAuthException
     */
    private func validateTokenRequest(ctx: JoyContext): (String, TokenGenerateRequest) {
        @JoyLogDebug("[OAuth2] form=${ctx.httpContext.request.form.toEncodeString()}")
        if (!(ctx.method == JoyHttpConsts.METHOD_POST || _cfg.allowGetAccessRequest && ctx.method == JoyHttpConsts
            .METHOD_GET)) {
            @JoyLogError("[OAuth2] invalid_request, method (${ctx.method}) is invalid")
            throw OAuthException(OAuthErrors.INVALID_REQ)
        }
        let gt = ctx.getForm("grant_type").getOrThrow {
            =>
                @JoyLogError("[OAuth2] invalid_request, grant_type is not existed")
                OAuthException(OAuthErrors.UNSUPPORTED_GRANT_TYPE)
        }

        let (clientId, clientSecret) = _clientInfoHandleFunc(ctx)
        // @JoyLogDebug("[OAuth2] client info: ${clientId}, ${clientSecret}")
        let tgr = TokenGenerateRequest(
            request: ctx,
            clientId: clientId,
            clientSecret: clientSecret
        )
        match (gt) {
            case "authorization_code" => validateAuthorizationCode(tgr, ctx)
            case "password" => validatePassword(tgr, ctx)
            case "client_credentials" => validateClientCredentials(tgr, ctx)
            case "refresh_token" => validateRefreshToken(tgr, ctx)
            case _ =>
                @JoyLogError("[OAuth2] unsupported_grant_type, invalid grant type ${gt}")
                throw OAuthException(OAuthErrors.UNSUPPORTED_GRANT_TYPE)
        }

        (gt, tgr)
    }

    /**
     * @throws OAuthException
     */
    private func validateAuthorizationCode(tgr: TokenGenerateRequest, ctx: JoyContext): Unit {
        tgr.redirectURI = ctx.getForm("redirect_uri") ?? ""
        tgr.code = ctx.getForm("code") ?? ""
        if (tgr.redirectURI == "" || tgr.code == "") {
            @JoyLogError("[OAuth2] invalid request, redirectURI or code is empty")
            throw OAuthException(OAuthErrors.INVALID_REQ)
        }
        tgr.codeVerifier = ctx.getForm("code_verifier") ?? ""
        if (tgr.codeVerifier == "" && _cfg.forcePKCE) {
            @JoyLogError("[OAuth2] invalid request, code verifier is empty")
            throw OAuthException(OAuthErrors.INVALID_REQ)
        }
    }

    /**
     * @throws OAuthException
     */
    private func validatePassword(tgr: TokenGenerateRequest, ctx: JoyContext): Unit {
        tgr.code = ctx.getForm("scope") ?? ""
        let username = ctx.getForm("username") ?? ""
        let pwd = ctx.getForm("password") ?? ""
        if (pwd == "" || username == "") {
            @JoyLogError("[OAuth2] invalid request, username or password is empty")
            throw OAuthException(OAuthErrors.INVALID_REQ)
        }

        let userId = _passwordAuthorizationHanleFunc(ctx, tgr.clientId, username, pwd)
        if (userId == "") {
            @JoyLogError("[OAuth2] invalid grant, PasswordAuthorizationHandleFunc return user_id empty")
            throw OAuthException(OAuthErrors.INVALID_GRANT)
        }
        tgr.userId = userId
    }

    private func validateClientCredentials(tgr: TokenGenerateRequest, ctx: JoyContext): Unit {
        tgr.scope = ctx.getForm("scope") ?? ""
    }

    private func validateRefreshToken(tgr: TokenGenerateRequest, ctx: JoyContext): Unit {
        tgr.refresh = _refreshTokenResolveHandleFunc(ctx)
        tgr.scope = ctx.getForm("scope") ?? ""
    }

    /**
     * @throws OAuthException
     */
    private func getAccessToken(_: JoyContext, gt: GrantType, tgr: TokenGenerateRequest): TokenInfo {
        if (!checkGrantType(gt)) {
            @JoyLogError("[OAuth2] unauthorized_client, invalid grant type ${gt}")
            throw OAuthException(OAuthErrors.UNAUTHORIZED_CLIENT)
        }

        var allowed = _clientAuthorizedHandleFunc?(tgr.clientId, gt) ?? true
        if (!allowed) {
            @JoyLogError("[OAuth2] unauthorized_client, client authorized handle return not allowed")
            throw OAuthException(OAuthErrors.UNAUTHORIZED_CLIENT)
        }

        match (gt) {
            case "authorization_code" => return _manager.generateAccessToken(gt, tgr)
            case "password" | "client_credentials" =>
                allowed = _clientScopeHandleFunc?(tgr) ?? true
                if (!allowed) {
                    @JoyLogError("[OAuth2] invalid scope, ClientScopeHandleFunc return not allowed")
                    throw OAuthException(OAuthErrors.INVALID_SCOPE)
                }
                return _manager.generateAccessToken(gt, tgr)
            case "refresh_token" =>
                if (let Some(scopeFn) <- _refreshingScopeHandleFunc && tgr.scope != "") {
                    let rti = _manager.loadRefreshToken(tgr.refresh)
                    allowed = scopeFn(tgr, rti.scope)
                    if (!allowed) {
                        @JoyLogError("[OAuth2] invalid scope, RefreshingScopeHandleFunc return not allowed")
                        throw OAuthException(OAuthErrors.INVALID_SCOPE)
                    }
                }
                if (let Some(validationFn) <- _refreshingValidationHandleFunc) {
                    let rti = _manager.loadRefreshToken(tgr.refresh)
                    allowed = validationFn(rti)
                    if (!allowed) {
                        @JoyLogError("[OAuth2] invalid refresh_token, RefreshingValidationHandleFunc return not allowed")
                        throw OAuthException(OAuthErrors.INVALID_REFRESH_TOKEN)
                    }
                    return _manager.refreshAccessToken(tgr)
                }
                return _manager.refreshAccessToken(tgr)
            case _ =>
                @JoyLogError("[OAuth2] unsupported_grant_type, invalid grant type ${gt}")
                throw OAuthException(OAuthErrors.UNSUPPORTED_GRANT_TYPE)
        }
    }

    private func tokenReturn(ctx: JoyContext, data: HashMap<String, JsonSerializable>): Unit {
        if (let Some(fn) <- _responseTokenHandleFunc) {
            fn(ctx, data)
            return
        }

        ctx.header(JoyHttpConsts.HEADER_CACHE_CONTROL, "no-store")
        ctx.header(JoyHttpConsts.HEADER_PRAGMA, "no-cache")
        ctx.json(data)
    }

    private func tokenReturnError(ctx: JoyContext, ei: ErrorInfo) {
        let data = getErrorData(ctx, ei)
        tokenReturn(ctx, data)
    }

    /**
     * 验证持有者令牌
     *
     * @throws OAuthException 如果令牌不存在或无效
     */
    public func validateBearerToken(ctx: JoyContext): TokenInfo {
        let access = _accessTokenResolveHandleFunc(ctx)
        if (access.isEmpty()) {
            @JoyLogError("[OAuth2] validate bearer token failed, the access token is empty")
            throw OAuthException(OAuthErrors.INVALID_ACCESS_TOKEN)
        }
        _manager.loadAccessToken(access)
    }
}
