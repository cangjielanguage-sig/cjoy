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
 * ClientPasswordVerifier 接口用于验证 OAuth2 授权的客户端密码
 */
public interface ClientPasswordVerifier {
    /**
     * 验证客户端密码
     *
     * @param client 客户端信息
     * @param pwd 要验证的密码
     * @return 如果密码有效返回 true，否则返回 false
     */
    func verifyPassword(client: ClientInfo, pwd: String): Bool
}

/**
 * ValidateURIFunc 类型用于验证 URI
 *
 * @param baseURI 基础 URI
 * @param redirectURI 要验证的重定向 URI
 * @throws OAuthException 如果重定向 URI 无效
 */
public type ValidateURIFunc = (baseURI: String, redirectURI: String) -> Unit

/**
 * ValidateURIFunc 的默认实现
 *
 * @throws OAuthException 如果重定向 URI 无效
 */
func defaultValidateURIFunc(baseURI: String, redirectURI: String): Unit {
    let base = URL.parse(baseURI)
    let redirect = URL.parse(redirectURI)
    // @JoyLogInfo("${base.host} --- ${redirect.host}")
    if (!redirect.host.endsWith(base.host)) {
        @JoyLogWarn("[OAuth2] invalid redirect uri, baseURI=${baseURI}, redirectURI=${redirectURI}")
        throw OAuthException(OAuthErrors.INVALID_REDIRECT_URI)
    }
}

/**
 * ExtractExtensionHandler 类型用于从令牌生成请求中提取扩展字段
 *
 * @param request 令牌生成请求
 * @param tokenInfo 要填充的令牌信息
 */
public type ExtractExtensionHandler = (request: TokenGenerateRequest, tokenInfo: TokenInfo) -> Unit

/**
 * ClientInfoHandleFunc 类型用于从请求中获取客户端信息
 *
 * @param ctx HTTP 上下文
 * @return 客户端 ID 和客户端密钥的元组
 */
public type ClientInfoHandleFunc = (ctx: JoyContext) -> (String, String)

/**
 * ClientAuthorizedHandleFunc 类型用于检查客户端是否被授权使用特定的授权类型
 *
 * @param clientId 客户端 ID
 * @param grant 授权类型
 * @return 如果客户端被授权使用此授权类型返回 true，否则返回 false
 */
public type ClientAuthorizedHandleFunc = (clientId: String, grant: GrantType) -> Bool

/**
 * ClientScopeHandleFunc 类型用于检查客户端范围是否有效
 *
 * @param request 令牌生成请求
 * @return 如果客户端范围有效返回 true，否则返回 false
 */
public type ClientScopeHandleFunc = (request: TokenGenerateRequest) -> Bool

/**
 * UserAuthorizationHandleFunc 类型用于从请求授权中获取用户 ID
 *
 * @param ctx HTTP 上下文
 * @return 用户 ID
 */
public type UserAuthorizationHandleFunc = (ctx: JoyContext) -> String

/**
 * PasswordAuthorizationHandleFunc 类型用于从用户名和密码获取用户 ID
 *
 * @param ctx HTTP 上下文
 * @param clientId 客户端 ID
 * @param username 用户名
 * @param password 密码
 * @return 用户 ID
 */
public type PasswordAuthorizationHandleFunc = (ctx: JoyContext, clientId: String, username: String, password: String) -> String

/**
 * RefreshingScopeHandleFunc 类型用于检查刷新令牌的范围
 *
 * @param request 令牌生成请求
 * @param oldScope 旧范围
 * @return 如果刷新范围有效返回 true，否则返回 false
 */
public type RefreshingScopeHandleFunc = (request: TokenGenerateRequest, oldScope: String) -> Bool

/**
 * RefreshingValidationHandleFunc 类型用于检查刷新令牌是否仍然有效
 *
 * @param token 令牌信息
 * @return 如果刷新令牌仍然有效返回 true，否则返回 false
 */
public type RefreshingValidationHandleFunc = (token: TokenInfo) -> Bool

/**
 * ResponseErrorHandleFunc 类型用于处理响应错误
 *
 * @param ctx HTTP 上下文
 * @param er 错误响应
 */
public type ResponseErrorHandleFunc = (ctx: JoyContext, er: ErrorResponse) -> Unit

/**
 * InternalErrorHandleFunc 类型用于处理内部错误
 *
 * @param ctx HTTP 上下文
 * @param ex 错误信息
 */
public type InternalErrorHandleFunc = (ctx: JoyContext, ex: ErrorInfo) -> Unit

/**
 * PreRedirectErrorHandleFunc 类型用于覆盖"错误时重定向"行为
 *
 * @param ctx HTTP 上下文
 * @param req 授权请求
 * @param ei 错误信息
 */
public type PreRedirectErrorHandleFunc = (ctx: JoyContext, req: AuthorizeRequest, ei: ErrorInfo) -> Unit

/**
 * AuthorizeScopeHandleFunc 类型用于设置授权范围
 *
 * @param ctx HTTP 上下文
 * @return 授权范围
 */
public type AuthorizeScopeHandleFunc = (ctx: JoyContext) -> String

/**
 * AccessTokenExpHandleFunc 类型用于设置访问令牌过期时间
 *
 * @param ctx HTTP 上下文
 * @return 访问令牌过期持续时间
 */
public type AccessTokenExpHandleFunc = (ctx: JoyContext) -> Duration

/**
 * ExtensionFieldsHandleFunc 类型用于向令牌响应添加扩展字段
 *
 * @param token 令牌信息
 * @return 扩展字段的映射
 */
public type ExtensionFieldsHandleFunc = (token: TokenInfo) -> HashMap<String, JsonSerializable>

/**
 * ResponseTokenHandleFunc 类型用于处理令牌响应
 *
 * @param ctx HTTP 上下文
 * @param data 令牌响应数据
 */
public type ResponseTokenHandleFunc = (ctx: JoyContext, data: HashMap<String, JsonSerializable>) -> Unit

/**
 * RefreshTokenResolveHandleFunc 类型用于从请求中获取刷新令牌
 *
 * @param ctx HTTP 上下文
 * @return 刷新令牌
 */
public type RefreshTokenResolveHandleFunc = (ctx: JoyContext) -> String

/**
 * AccessTokenResolveHandleFunc 类型用于从请求中获取访问令牌
 *
 * @param ctx HTTP 上下文
 * @return 访问令牌
 */
public type AccessTokenResolveHandleFunc = (ctx: JoyContext) -> String

/**
 * clientFormHandleFunc 从请求表单数据中获取客户端信息
 *
 * @param ctx HTTP 上下文
 * @return 客户端 ID 和客户端密钥的元组
 * @throws OAuthException 如果客户端 ID 缺失或无效
 */
public func clientFormHandleFunc(ctx: JoyContext): (String, String) {
    let clientId = ctx.getForm("client_id").getOrThrow {
        =>
            @JoyLogError("[OAuth2] get client_id from form failed")
            throw OAuthException(OAuthErrors.INVALID_CLIENT)
    }
    let clientSecret = ctx.getForm("client_secret") ?? ""
    return (clientId, clientSecret)
}

/**
 * clientBasicHandleFunc 从 Basic Auth 头部获取客户端信息
 *
 * @param ctx HTTP 上下文
 * @return 客户端 ID 和客户端密钥的元组
 * @throws OAuthException 如果 Basic Auth 头部缺失或无效
 */
public func clientBasicHandleFunc(ctx: JoyContext): (String, String) {
    ctx.basicAuth().getOrThrow {
        =>
            @JoyLogError("[OAuth2] get basic auth from header failed")
            throw OAuthException(OAuthErrors.INVALID_CLIENT)
    }
}

/**
 * refreshTokenFormResolveHandleFunc 从表单数据中获取刷新令牌
 *
 * @param ctx HTTP 上下文
 * @return 刷新令牌
 * @throws OAuthException 如果刷新令牌缺失
 */
public func refreshTokenFormResolveHandleFunc(ctx: JoyContext): String {
    ctx.getForm("refresh_token") ?? throw OAuthException(OAuthErrors.INVALID_REQ)
}

/**
 * refreshTokenCookieResolveHandleFunc 从 Cookie 中获取刷新令牌
 *
 * @param ctx HTTP 上下文
 * @return 刷新令牌
 * @throws OAuthException 如果刷新令牌 Cookie 缺失
 */
public func refreshTokenCookieResolveHandleFunc(ctx: JoyContext): String {
    ctx.getCookie("refresh_token") ?? throw OAuthException(OAuthErrors.INVALID_REQ)
}

private const PREFIX: String = "Bearer "

/**
 * accessTokenDefaultResolveHandleFunc 从授权头部或表单数据中获取访问令牌
 *
 * @param ctx HTTP 上下文
 * @return 访问令牌
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
 * accessTokenCookieResolveHandleFunc 从 Cookie 中获取访问令牌
 *
 * @param ctx HTTP 上下文
 * @return 访问令牌
 */
public func accessTokenCookieResolveHandleFunc(ctx: JoyContext): String {
    ctx.getCookie("access_token") ?? ""
}

/**
 * defaultInternalErrorHandleFunc 使用默认日志处理内部错误
 *
 * @param ctx HTTP 上下文
 * @param ex 错误信息
 */
func defaultInternalErrorHandleFunc(_: JoyContext, ex: ErrorInfo): Unit {
    @JoyLogError("[OAuth2] internal error, ${ex.code}, ${ex.description}")
}

/**
 * defaultResponseErrorHandleFunc 使用默认日志处理响应错误
 *
 * @param ctx HTTP 上下文
 * @param er 错误响应
 */
func defaultResponseErrorHandleFunc(_: JoyContext, er: ErrorResponse): Unit {
    @JoyLogError("[OAuth2] response error, ${er.errorInfo.code}, ${er.errorInfo.description}")
}
