/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
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
import cjoy.log.*

public class OAuth2Server {
    private let _cfg: ServerConfig
    private let _manager: OAuth2Manager

    private var _clientInfoHandleFunc: ClientInfoHandleFunc
    private var _userAuthorizationHandleFunc: UserAuthorizationHandleFunc
    private var _passwordAuthorizationHanleFunc: PasswordAuthorizationHanleFunc
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
            ctx: JoyContext => throw OAuthException(OAuthErrors.ACCESS_DENIED)
        }
        _passwordAuthorizationHanleFunc = {
            ctx: JoyContext, clientId: String, username: String, password: String => throw OAuthException(
                OAuthErrors.ACCESS_DENIED)
        }
    }

    public func setTokenType(tt: String) {
        _cfg.tokenType = tt
    }

    public func setAllowGetAccessRequest(allow: Bool) {
        _cfg.allowGetAccessRequest = allow
    }

    public func setAllowedResponseType(types: Array<ResponseType>) {
        _cfg.allowGrantTypes = types
    }

    public func setAllowedGrantType(types: Array<GrantType>) {
        _cfg.allowGrantTypes = types
    }

    public func setClientInfoHandleFunc(fn: ClientInfoHandleFunc) {
        _clientInfoHandleFunc = fn
    }

    public func setUserAuthorizationHandleFunc(fn: UserAuthorizationHandleFunc) {
        _userAuthorizationHandleFunc = fn
    }

    public func setPasswordAuthorizationHanleFunc(fn: PasswordAuthorizationHanleFunc) {
        _passwordAuthorizationHanleFunc = fn
    }

    public func setResponseErrorHandleFunc(fn: ResponseErrorHandleFunc) {
        _responseErrorHandleFunc = fn
    }

    public func setInternalErrorHandleFunc(fn: InternalErrorHandleFunc) {
        _internalErrorHandleFunc = fn
    }

    public func setAccessTokenResolveHandleFunc(fn: AccessTokenResolveHandleFunc) {
        _accessTokenResolveHandleFunc = fn
    }

    public func setRefreshTokenResolveHandleFunc(fn: RefreshingValidationHandleFunc) {
        _refreshingValidationHandleFunc = fn
    }

    public func setClientAuthorizedHandleFunc(fn: ClientAuthorizedHandleFunc) {
        _clientAuthorizedHandleFunc = fn
    }

    public func setClientScopeHandleFunc(fn: ClientScopeHandleFunc) {
        _clientScopeHandleFunc = fn
    }

    public func setRefreshingValidationHandleFunc(fn: RefreshingValidationHandleFunc) {
        _refreshingValidationHandleFunc = fn
    }

    public func setPreRedirectErrorHandleFunc(fn: PreRedirectErrorHandleFunc) {
        _preRedirectErrorHandleFunc = fn
    }

    public func setExtensionFieldsHandleFunc(fn: ExtensionFieldsHandleFunc) {
        _extensionFieldsHandleFunc = fn
    }

    public func setAccessTokenExpHandleFunc(fn: AccessTokenExpHandleFunc) {
        _accessTokenExpHandleFunc = fn
    }

    public func setAuthorizeScopeHandleFunc(fn: AuthorizeScopeHandleFunc) {
        _authorizeScopeHandleFunc = fn
    }

    public func setResponseTokenHandleFunc(fn: ResponseTokenHandleFunc) {
        _responseTokenHandleFunc = fn
    }

    public func setRefreshingScopeHandleFunc(fn: RefreshingScopeHandleFunc) {
        _refreshingScopeHandleFunc = fn
    }

    private func handlerError(ctx: JoyContext, req: ?AuthorizeRequest, err: ErrorInfo) {
        if (let Some(h) <- _preRedirectErrorHandleFunc) {
            h(ctx, req.getOrThrow(), err)
        } else {
            redirectError(ctx, req, err)
        }
    }

    private func redirectError(ctx: JoyContext, req: ?AuthorizeRequest, err: ErrorInfo) {
        if (req.isNone()) {
            return
        }

        let data = getErrorData(ctx, err)
        redirect(ctx, req.getOrThrow(), data)
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

    private func getRedirectURI(req: AuthorizeRequest, data: HashMap<String, JsonSerializable>): String {
        let url = URL.parse(req.redirectURI)
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
                url.replace(query: q.toEncodeString())
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
                url.replace(query: "")
                url.replace(fragment: b.toString())
            case _ => ()
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

    private func validationAuthorizeRequest(ctx: JoyContext): AuthorizeRequest {
        let redirectURI = ctx
            .getPostForm("redirect_uri")
            .getOrThrow(
                {
                    =>
                    @LogError("[OAuth2] invalid request, redirectURI is not existed")
                    OAuthException(OAuthErrors.INVALID_REQ)
                }
            )
        let clientId = ctx
            .getPostForm("client_id")
            .getOrThrow(
                {
                    =>
                    @LogError("[OAuth2] invalid request, client_id is not existed")
                    OAuthException(OAuthErrors.INVALID_REQ)
                }
            )
        if (!(ctx.method == JoyHttpConsts.METHOD_GET || ctx.method == JoyHttpConsts.METHOD_POST)) {
            @LogError("[OAuth2] invalid request, method(${ctx.method}) is invalid")
            throw OAuthException(OAuthErrors.INVALID_REQ)
        }
        if (clientId == "") {
            @LogError("[OAuth2] invalid request, clientId is empty")
            throw OAuthException(OAuthErrors.INVALID_REQ)
        }

        let respType = ctx
            .getPostForm("response_type")
            .getOrThrow(
                {
                    =>
                    @LogError("[OAuth2] invalid request, response_type is not existed")
                    OAuthException(OAuthErrors.UNSUPPORTED_RESP_TYPE)
                }
            )
        if (!checkResponeType(respType)) {
            @LogError("[OAuth2] unauthorized_client, response type (${respType}) is invalid")
            throw OAuthException(OAuthErrors.UNAUTHORIZED_CLIENT)
        }

        let cc = ctx.getPostForm("code_challenge").getOrDefault({=> ""})
        if (cc == "" && _cfg.forcePKCE) {
            @LogError("[OAuth2] invalid_request, code_challenge is empty")
            throw OAuthException(OAuthErrors.CODE_CHALLENG_ERQUIRED)
        }
        if (cc != "" && cc.size < 43 || cc.size > 128) {
            @LogError("[OAuth2] invalid_request, code_challenge len (${cc.size}) is invalid")
            throw OAuthException(OAuthErrors.INVALID_CODE_CHALLENGE_LEN)
        }

        var ccm = ctx.getPostForm("code_challenge_method").getOrDefault({=> ""})
        if (ccm == "") {
            ccm = OAuthConsts.CODE_CHALLENGE_PLAIN
        }
        if (ccm != "" && !checkCodeChallengeMethod(ccm)) {
            @LogError("[OAuth2] invalid_request, code_challenge_method l (${ccm}) is invalid")
            throw OAuthException(OAuthErrors.UNSUPPORTED_CODE_CHALLENGE_METHOD)
        }

        let scope = ctx.getPostForm("scope").getOrDefault({=> ""})
        let state = ctx.getPostForm("state").getOrDefault({=> ""})
        AuthorizeRequest(responseType: respType, clientId: clientId, scope: scope, redirectURI: redirectURI,
            state: state, codeChallenge: cc, codeChallengeMethod: ccm, userId: "", accessTokenExp: Duration.Zero,
            request: ctx)
    }

    private func getAuthorizeToken(ctx: JoyContext, req: AuthorizeRequest): TokenInfo {
        let gt = if (req.responseType == OAuthConsts.RESPONSE_TYPE_CODE) {
            OAuthConsts.GRANT_TYPE_AUTHORIZATION_CODE
        } else {
            OAuthConsts.GRANT_TYPE_IMPLICIT
        }
        var allowed = _clientAuthorizedHandleFunc?(req.clientId, gt) ?? true
        if (!allowed) {
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

    public func authorizeRequestHandleFunc(ctx: JoyContext): Unit {
        try {
            let req = validationAuthorizeRequest(ctx)
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
            handlerError(ctx, None, ex.errorInfo)
        } catch (ex: Exception) {
            handlerError(ctx, None, OAuthErrors.SERVER_ERROR)
        }
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

    public func tokenRequestHandleFunc(ctx: JoyContext): Unit {
        try {
            let (gt, tgr) = validationTokenRequest(ctx)
            let ti = getAccessToken(ctx, gt, tgr)
            token(ctx, getTokenData(ti))
        } catch (ex: OAuthException) {
            tokenError(ctx, ex.errorInfo)
        } catch (ex: Exception) {
            tokenError(ctx, OAuthErrors.SERVER_ERROR)
        }
    }

    private func validationTokenRequest(ctx: JoyContext): (String, TokenGenerateRequest) {
        if (!(ctx.method == JoyHttpConsts.METHOD_POST || _cfg.allowGetAccessRequest && ctx.method == JoyHttpConsts
            .METHOD_GET)) {
            @LogError("[OAuth2] invalid_request, method (${ctx.method}) is invalid")
            throw OAuthException(OAuthErrors.INVALID_REQ)
        }
        let gt = ctx
            .getPostForm("grant_type")
            .getOrThrow(
                {
                    =>
                    @LogError("[OAuth2] invalid_request, grant_type is not existed")
                    OAuthException(OAuthErrors.UNSUPPORTED_GRANT_TYPE)
                }
            )

        let (clientId, clientSecret) = _clientInfoHandleFunc(ctx)
        let tgr = TokenGenerateRequest(
            request: ctx,
            clientId: clientId,
            clientSecret: clientSecret
        )
        match (gt) {
            case "authorization_code" =>
                tgr.redirectURI = ctx.getPostForm("redirect_uri").getOrDefault({=> ""})
                tgr.code = ctx.getPostForm("code").getOrDefault({=> ""})
                if (tgr.redirectURI == "" || tgr.code == "") {
                    @LogError("[OAuth2] invalid request, redirectURI or code is empty")
                    throw OAuthException(OAuthErrors.INVALID_REQ)
                }
                tgr.codeVerifier = ctx.getPostForm("code_verifier").getOrDefault({=> ""})
                if (tgr.codeVerifier == "" && _cfg.forcePKCE) {
                    @LogError("[OAuth2] invalid request, code verifier is empty")
                    throw OAuthException(OAuthErrors.INVALID_REQ)
                }
            case "password" =>
                tgr.code = ctx.getPostForm("scope").getOrDefault({=> ""})
                let username = ctx.getPostForm("username").getOrDefault({=> ""})
                let password = ctx.getPostForm("password").getOrDefault({=> ""})
                if (password == "" || username == "") {
                    @LogError("[OAuth2] invalid request, username or password is empty")
                    throw OAuthException(OAuthErrors.INVALID_REQ)
                }
                let userId = _passwordAuthorizationHanleFunc(ctx, clientId, username, password)
                if (userId == "") {
                    throw OAuthException(OAuthErrors.INVALID_GRANT)
                }
                tgr.userId = userId
            case "client_credentials" => tgr.code = ctx.getPostForm("scope").getOrDefault({=> ""})
            case "refresh_token" =>
                tgr.refresh = _refreshTokenResolveHandleFunc(ctx)
                tgr.code = ctx.getPostForm("scope").getOrDefault({=> ""})
            case _ => ()
        }

        (gt, tgr)
    }

    private func getAccessToken(ctx: JoyContext, gt: GrantType, tgr: TokenGenerateRequest): TokenInfo {
        if (!checkGrantType(gt)) {
            throw OAuthException(OAuthErrors.UNAUTHORIZED_CLIENT)
        }

        var allowed = _clientAuthorizedHandleFunc?(tgr.clientId, gt) ?? true
        if (!allowed) {
            throw OAuthException(OAuthErrors.UNAUTHORIZED_CLIENT)
        }

        match (gt) {
            case "authorization_code" => return _manager.generateAccessToken(gt, tgr)
            case "password" | "client_credentials" =>
                allowed = _clientScopeHandleFunc?(tgr) ?? true
                if (!allowed) {
                    throw OAuthException(OAuthErrors.INVALID_SCOPE)
                }
                return _manager.generateAccessToken(gt, tgr)
            case "refresh_token" =>
                if (let Some(scopeFn) <- _refreshingScopeHandleFunc && tgr.scope != "") {
                    let rti = _manager.loadRefreshToken(tgr.refresh)
                    allowed = scopeFn(tgr, rti.scope)
                    if (!allowed) {
                        throw OAuthException(OAuthErrors.INVALID_SCOPE)
                    }
                }
                if (let Some(validationFn) <- _refreshingValidationHandleFunc) {
                    let rti = _manager.loadRefreshToken(tgr.refresh)
                    allowed = validationFn(rti)
                    if (!allowed) {
                        throw OAuthException(OAuthErrors.INVALID_SCOPE)
                    }
                    return _manager.refreshAccessToken(tgr)
                }
                return _manager.refreshAccessToken(tgr)
            case _ => throw OAuthException(OAuthErrors.UNSUPPORTED_GRANT_TYPE)
        }
    }

    private func token(ctx: JoyContext, data: HashMap<String, JsonSerializable>): Unit {
        if (let Some(fn) <- _responseTokenHandleFunc) {
            fn(ctx, data)
            return
        }

        ctx.header(JoyHttpConsts.HEADER_CACHE_CONTROL, "no-store")
        ctx.header(JoyHttpConsts.HEADER_PRAGMA, "no-cache")
        ctx.json(data)
    }

    private func tokenError(ctx: JoyContext, ei: ErrorInfo) {
        let data = getErrorData(ctx, ei)
        token(ctx, data)
    }
}
