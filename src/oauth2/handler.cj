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
 * ClientPasswordVerifier interface to verify client password for OAuth2 authorization
 */
public interface ClientPasswordVerifier {
    /**
     * Verifies the client password
     *
     * @param client The client information
     * @param pwd The password to verify
     * @return true if password is valid, false otherwise
     */
    func verifyPassword(client: ClientInfo, pwd: String): Bool
}

/**
 * ValidateURIFunc type for validating URI
 *
 * @param baseURI Base URI
 * @param redirectURI Redirect URI to validate
 * @throws OAuthException if redirect URI is invalid
 */
public type ValidateURIFunc = (baseURI: String, redirectURI: String) -> Unit

/**
 * Default implementation of ValidateURIFunc
 *
 * @throws OAuthException if redirect URI is invalid
 */
func defaultValidateURIFunc(baseURI: String, redirectURI: String): Unit {
    let base = URL.parse(baseURI)
    let redirect = URL.parse(redirectURI)
    if (!redirect.host.endsWith(base.host)) {
        throw OAuthException(OAuthErrors.INVALID_REDIRECT_URI)
    }
}

/**
 * ExtractExtensionHandler type for extracting extension fields from token generation requests
 *
 * @param request Token generate request
 * @param tokenInfo Token information to populate
 */
public type ExtractExtensionHandler = (request: TokenGenerateRequest, tokenInfo: TokenInfo) -> Unit

/**
 * ClientInfoHandleFunc type for getting client info from requests
 *
 * @param ctx HTTP context
 * @return Tuple of client ID and client secret
 */
public type ClientInfoHandleFunc = (ctx: JoyContext) -> (String, String)

/**
 * ClientAuthorizedHandleFunc type for checking if client is authorized to use a specific grant type
 *
 * @param clientId Client ID
 * @param grant Grant type
 * @return true if client is authorized to use this grant type, false otherwise
 */
public type ClientAuthorizedHandleFunc = (clientId: String, grant: GrantType) -> Bool

/**
 * ClientScopeHandleFunc type for checking if client scope is valid
 *
 * @param request Token generate request
 * @return true if client scope is valid, false otherwise
 */
public type ClientScopeHandleFunc = (request: TokenGenerateRequest) -> Bool

/**
 * UserAuthorizationHandleFunc type for getting user ID from request authorization
 *
 * @param ctx HTTP context
 * @return User ID
 */
public type UserAuthorizationHandleFunc = (ctx: JoyContext) -> String

/**
 * PasswordAuthorizationHandleFunc type for getting user ID from username and password
 *
 * @param ctx HTTP context
 * @param clientId Client ID
 * @param username Username
 * @param password Password
 * @return User ID
 */
public type PasswordAuthorizationHandleFunc = (ctx: JoyContext, clientId: String, username: String, password: String) -> String

/**
 * RefreshingScopeHandleFunc type for checking scope of refreshing token
 *
 * @param request Token generate request
 * @param oldScope Old scope
 * @return true if refreshing scope is valid, false otherwise
 */
public type RefreshingScopeHandleFunc = (request: TokenGenerateRequest, oldScope: String) -> Bool

/**
 * RefreshingValidationHandleFunc type for checking if refresh token is still valid
 *
 * @param token Token information
 * @return true if refresh token is still valid, false otherwise
 */
public type RefreshingValidationHandleFunc = (token: TokenInfo) -> Bool

/**
 * ResponseErrorHandleFunc type for handling response errors
 *
 * @param ctx HTTP context
 * @param er Error response
 */
public type ResponseErrorHandleFunc = (ctx: JoyContext, er: ErrorResponse) -> Unit

/**
 * InternalErrorHandleFunc type for handling internal errors
 *
 * @param ctx HTTP context
 * @param ex Error information
 */
public type InternalErrorHandleFunc = (ctx: JoyContext, ex: ErrorInfo) -> Unit

/**
 * PreRedirectErrorHandleFunc type used to override "redirect-on-error" behavior
 *
 * @param ctx HTTP context
 * @param req Authorize request
 * @param ei Error information
 */
public type PreRedirectErrorHandleFunc = (ctx: JoyContext, req: AuthorizeRequest, ei: ErrorInfo) -> Unit

/**
 * AuthorizeScopeHandleFunc type for setting authorized scope
 *
 * @param ctx HTTP context
 * @return Authorized scope
 */
public type AuthorizeScopeHandleFunc = (ctx: JoyContext) -> String

/**
 * AccessTokenExpHandleFunc type for setting access token expiration
 *
 * @param ctx HTTP context
 * @return Access token expiration duration
 */
public type AccessTokenExpHandleFunc = (ctx: JoyContext) -> Duration

/**
 * ExtensionFieldsHandleFunc type for adding extension fields to token response
 *
 * @param token Token information
 * @return Map of extension fields
 */
public type ExtensionFieldsHandleFunc = (token: TokenInfo) -> HashMap<String, JsonSerializable>

/**
 * ResponseTokenHandleFunc type for handling token responses
 *
 * @param ctx HTTP context
 * @param data Token response data
 */
public type ResponseTokenHandleFunc = (ctx: JoyContext, data: HashMap<String, JsonSerializable>) -> Unit

/**
 * RefreshTokenResolveHandleFunc type for fetching refresh token from request
 *
 * @param ctx HTTP context
 * @return Refresh token
 */
public type RefreshTokenResolveHandleFunc = (ctx: JoyContext) -> String

/**
 * AccessTokenResolveHandleFunc type for fetching access token from request
 *
 * @param ctx HTTP context
 * @return Access token
 */
public type AccessTokenResolveHandleFunc = (ctx: JoyContext) -> String

/**
 * clientFormHandleFunc retrieves client info from request form data
 *
 * @param ctx HTTP context
 * @return Tuple of client ID and client secret
 * @throws OAuthException if client ID is missing or invalid
 */
public func clientFormHandleFunc(ctx: JoyContext): (String, String) {
    let clientId = ctx.getForm("client_id") ?? throw OAuthException(OAuthErrors.INVALID_CLIENT)
    let clientSecret = ctx.getForm("client_secret") ?? ""
    return (clientId, clientSecret)
}

/**
 * clientBasicHandleFunc retrieves client info from Basic Auth header
 *
 * @param ctx HTTP context
 * @return Tuple of client ID and client secret
 * @throws OAuthException if Basic Auth header is missing or invalid
 */
public func clientBasicHandleFunc(ctx: JoyContext): (String, String) {
    ctx.basicAuth().getOrThrow {
        =>
            @JoyLogError("[OAuth2] get basic auth from header failed")
            throw OAuthException(OAuthErrors.INVALID_CLIENT)
    }
}

/**
 * refreshTokenFormResolveHandleFunc retrieves refresh token from form data
 *
 * @param ctx HTTP context
 * @return Refresh token
 * @throws OAuthException if refresh token is missing
 */
public func refreshTokenFormResolveHandleFunc(ctx: JoyContext): String {
    ctx.getForm("refresh_token") ?? throw OAuthException(OAuthErrors.INVALID_REQ)
}

/**
 * refreshTokenCookieResolveHandleFunc retrieves refresh token from cookie
 *
 * @param ctx HTTP context
 * @return Refresh token
 * @throws OAuthException if refresh token cookie is missing
 */
public func refreshTokenCookieResolveHandleFunc(ctx: JoyContext): String {
    ctx.getCookie("refresh_token") ?? throw OAuthException(OAuthErrors.INVALID_REQ)
}

private const PREFIX: String = "Bearer "

/**
 * accessTokenDefaultResolveHandleFunc fetches access token from authorization header or form data
 *
 * @param ctx HTTP context
 * @return Access token
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
 * accessTokenCookieResolveHandleFunc fetches access token from cookie
 *
 * @param ctx HTTP context
 * @return Access token
 */
public func accessTokenCookieResolveHandleFunc(ctx: JoyContext): String {
    ctx.getCookie("access_token") ?? ""
}

/**
 * defaultInternalErrorHandleFunc handles internal errors with default logging
 *
 * @param ctx HTTP context
 * @param ex Error information
 */
func defaultInternalErrorHandleFunc(_: JoyContext, ex: ErrorInfo): Unit {
    @JoyLogError("[OAuth2] internal error, ${ex.code}, ${ex.description}")
}

/**
 * defaultResponseErrorHandleFunc handles response errors with default logging
 *
 * @param ctx HTTP context
 * @param er Error response
 */
func defaultResponseErrorHandleFunc(_: JoyContext, er: ErrorResponse): Unit {
    @JoyLogError("[OAuth2] response error, ${er.errorInfo.code}, ${er.errorInfo.description}")
}
