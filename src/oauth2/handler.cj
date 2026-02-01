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
import stdx.encoding.url.URL
import cjoy.framework.{JoyContext, JoyHttpConsts}
import cjoy.json.*
import cjoy.log.macros.*

/**
 * the interface to verify client password for OAuth2 authorization
 */
public interface ClientPasswordVerifier {
    /**
     * verify the client password
     *
     * @param client:  the client information
     * @param pwd:  the password to verify
     * @return true if password is valid, false otherwise
     */
    func verifyPassword(client: ClientInfo, pwd: String): Bool
}

/**
 * validate URI function
 *
 * @param baseURI:  base URI
 * @param redirectURI:  redirect URI to validate
 * @throws OAuthException if redirect URI is invalid
 */
public type ValidateURIFunc = (baseURI: String, redirectURI: String) -> Unit

/**
 * @throws  OAuthException
 */
func defaultValidateURIFunc(baseURI: String, redirectURI: String): Unit {
    let base = URL.parse(baseURI)
    let redirect = URL.parse(redirectURI)
    if (!redirect.host.endsWith(base.host)) {
        throw OAuthException(OAuthErrors.INVALID_REDIRECT_URI)
    }
}

/**
 * extract extension handler function
 *
 * @param request:  token generate request
 * @param tokenInfo:  token information
 */
public type ExtractExtensionHandler = (request: TokenGenerateRequest, tokenInfo: TokenInfo) -> Unit

/**
 * get client info from request, return clientID, clientSecret
 *
 * @param ctx:  context
 * @return tuple of client ID and client secret
 */
public type ClientInfoHandleFunc = (ctx: JoyContext) -> (String, String)

/**
 * check client allows to use this authorization grant type, return true or false
 *
 * @param clientId:  client ID
 * @param grant:  grant type
 * @return true if client is authorized to use this grant type
 */
public type ClientAuthorizedHandleFunc = (clientId: String, grant: GrantType) -> Bool

/**
 * check client allows to use scope, return true or false
 *
 * @param request:  token generate request
 * @return true if client scope is valid
 */
public type ClientScopeHandleFunc = (request: TokenGenerateRequest) -> Bool

/**
 * get user id from request authorization, return userId
 *
 * @param ctx:  context
 * @return user ID
 */
public type UserAuthorizationHandleFunc = (ctx: JoyContext) -> String

/**
 * get user id from username and password, return userId
 *
 * @param ctx:  context
 * @param clientId:  client ID
 * @param username:  username
 * @param password:  password
 * @return user ID
 */
public type PasswordAuthorizationHandleFunc = (ctx: JoyContext, clientId: String, username: String, password: String) -> String

/**
 * check scope of refreshing token, return true or false
 *
 * @param request:  token generate request
 * @param oldScope:  old scope
 * @return true if refreshing scope is valid
 */
public type RefreshingScopeHandleFunc = (request: TokenGenerateRequest, oldScope: String) -> Bool

/**
 * check if refresh_token is still valid. eg no revocation or other, return true or false
 *
 * @param token:  token information
 * @return true if refresh token is still valid
 */
public type RefreshingValidationHandleFunc = (token: TokenInfo) -> Bool

/**
 * response error handling function
 *
 * @param ctx:  context
 * @param er:  error response
 */
public type ResponseErrorHandleFunc = (ctx: JoyContext, er: ErrorResponse) -> Unit

/**
 * internal error handling function
 *
 * @param ctx:  context
 * @param ex:  error information
 */
public type InternalErrorHandleFunc = (ctx: JoyContext, ex: ErrorInfo) -> Unit

/**
 * is used to override "redirect-on-error" behavior
 *
 * @param ctx:  context
 * @param req:  authorize request
 * @param ei:  error information
 */
public type PreRedirectErrorHandleFunc = (ctx: JoyContext, req: AuthorizeRequest, ei: ErrorInfo) -> Unit

/**
 * set authorized scope, return scope
 *
 * @param ctx:  context
 * @return authorized scope
 */
public type AuthorizeScopeHandleFunc = (ctx: JoyContext) -> String

/**
 * set expiration date for access token
 *
 * @param ctx:  context
 * @return access token expiration duration
 */
public type AccessTokenExpHandleFunc = (ctx: JoyContext) -> Duration

/**
 * response in response to access token with extension of field
 *
 * @param token:  token information
 * @return map of extension fields
 */
public type ExtensionFieldsHandleFunc = (token: TokenInfo) -> HashMap<String, JsonSerializable>

/**
 * response token handling function
 *
 * @param ctx:  context
 * @param data:  token response data
 */
public type ResponseTokenHandleFunc = (ctx: JoyContext, data: HashMap<String, JsonSerializable>) -> Unit

/**
 * fetch refresh token from request
 *
 * @param ctx:  context
 * @return refresh token
 */
public type RefreshTokenResolveHandleFunc = (ctx: JoyContext) -> String

/**
 * fetch access token from request
 *
 * @param ctx:  context
 * @return access token
 */
public type AccessTokenResolveHandleFunc = (ctx: JoyContext) -> String

/**
 * @throws OAuthException
 */
public func clientFormHandleFunc(ctx: JoyContext): (String, String) {
    let clientId = ctx.getForm("client_id") ?? throw OAuthException(OAuthErrors.INVALID_CLIENT)
    let clientSecret = ctx.getForm("client_secret") ?? ""
    return (clientId, clientSecret)
}

/**
 * @throws OAuthException
 */
public func clientBasicHandleFunc(ctx: JoyContext): (String, String) {
    ctx.basicAuth().getOrThrow {
        =>
            @JoyLogError("[OAuth2] get basic auth from header failed")
            throw OAuthException(OAuthErrors.INVALID_CLIENT)
    }
}

/**
 * @throws OAuthException
 */
public func refreshTokenFormResolveHandleFunc(ctx: JoyContext): String {
    ctx.getForm("refresh_token") ?? throw OAuthException(OAuthErrors.INVALID_REQ)
}

/**
 * @throws OAuthException
 */
public func refreshTokenCookieResolveHandleFunc(ctx: JoyContext): String {
    ctx.getCookie("refresh_token") ?? throw OAuthException(OAuthErrors.INVALID_REQ)
}

private const PREFIX: String = "Bearer "

/**
 * fetch access token from authorization header or form
 *
 * @param ctx:  context
 * @return access token
 */
public func accessTokenDefaultResolveHandleFunc(ctx: JoyContext): String {
    let auth = ctx.getHeader(JoyHttpConsts.HEADER_AUTHORIZATION)

    if (let Some(h) <- auth && h.startsWith(PREFIX)) {
        h[PREFIX.size..]
    } else {
        ctx.getForm("access_token") ?? ""
    }
}

/**
 * fetch access token from cookie
 *
 * @param ctx:  context
 * @return access token
 */
public func accessTokenCookieResolveHandleFunc(ctx: JoyContext): String {
    ctx.getCookie("access_token") ?? ""
}

/**
 * handle internal error with default logging
 *
 * @param ctx:  context
 * @param ex:  error info
 */
func defaultInternalErrorHandleFunc(_: JoyContext, ex: ErrorInfo): Unit {
    @JoyLogError("[OAuth2] internal error, ${ex.code}, ${ex.description}")
}

/**
 * handle response error with default logging
 *
 * @param ctx:  context
 * @param er:  error response
 */
func defaultResponseErrorHandleFunc(_: JoyContext, er: ErrorResponse): Unit {
    @JoyLogError("[OAuth2] response error, ${er.errorInfo.code}, ${er.errorInfo.description}")
}
