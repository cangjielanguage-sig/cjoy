/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.middleware

import std.crypto.digest.digest
import stdx.crypto.digest.SHA256
import stdx.net.http.HttpStatusCode
import cjoy.{JoyMiddlewareHandler, JoyRequestHandlerChain, JoyContext, JoyHttpConsts, JoyRequestHandler, 
    JoyRequestHandlerFunc, JoyFuncHandler, JoyRequestFilterFunc}
import cjoy.log.macros.*
import cjoy.utils.{secureRandStr, rawBase64URLEncode}

const csrfSecretCtxKey = "__csrf_secret__"
const csrfTokenCtxKey = "__csrf_token__"
const csrfTokenSecretCtxKey = "__csrf_token_secret__"
const csrfSaltCtxKey = "__csrf_salt__"

// 提取令牌的函数
type CsrfExtractFunc = (ctx: JoyContext) -> (String, String)

// 默认的认证失败处理器
class DefaultCsrfErrorHandler <: JoyRequestHandler {
    static let INSTANCE = DefaultCsrfErrorHandler()

    public func handle(ctx: JoyContext): Unit {
        @JoyLogError("[CSRF] verify failed, ${ctx.getClientIP()}, ${ctx.method} ${ctx.url}")
        ctx.status(HttpStatusCode.STATUS_FORBIDDEN)
    }
}

/**
 * obtain or generate one CSRF token
 */
public func getCsrfToken(ctx: JoyContext): String {
    let session = getSession(ctx).getOrThrow()
    let secret = session.get<String>(csrfSecretCtxKey).getOrThrow()

    if (let Some(t) <- session.get<String>(csrfTokenCtxKey)) {
        if (session.get<String>(csrfTokenSecretCtxKey) == secret) {
            return t
        }
    }

    let salt = if (let Some(s) <- session.get<String>(csrfSaltCtxKey)) {
        s
    } else {
        let s = secureRandStr(16)
        session.set(csrfSaltCtxKey, s)
        s
    }

    let token = CsrfProtect.tokenize(secret, salt)
    session.set(csrfTokenCtxKey, token)
    session.set(csrfTokenSecretCtxKey, secret)
    token
}

/**
 * CSRF 令牌保护中间件
 */
public class CsrfProtect <: JoyMiddlewareHandler {
    private let _secret: String
    private let _handleFunc: CsrfExtractFunc
    private let _ignoreMethods: Array<String>
    private let _filterHandler: ?JoyRequestFilterFunc
    private let _errorHandler: JoyRequestHandler

    /**
     * @param secret: 用于生成令牌的密钥
     * @param ignoreMethods: 将被视为不需要保护的HTTP方法列表
     * @param lookupKey: 用于从请求中提取令牌的字符串，格式为 "<source>:<key>"。
     *       可能的值:
     *        - "header:<name>"（从请求头中提取）
     *        - "query:<name>"（从查询参数中提取）
     *        - "param:<name>"（从路径参数中提取）
     *        - "form:<name>"（从表单数据中提取）
     * @param filterHandler: 用于跳过此中间件的函数
     * @param errorHandler: 发生错误时执行的函数
     */
    public init(secret: String,
        ignoreMethods!: Array<String> = [JoyHttpConsts.METHOD_GET, JoyHttpConsts.METHOD_HEAD,
            JoyHttpConsts.METHOD_OPTIONS], lookupKey!: String = "header:X-CSRF-TOKEN",
        filterHandler!: ?JoyRequestFilterFunc = None, errorHandler!: ?JoyRequestHandlerFunc = None) {
        _secret = secret
        _handleFunc = createExtractFunc(lookupKey)
        _ignoreMethods = ignoreMethods
        _filterHandler = filterHandler
        _errorHandler = if (let Some(h) <- errorHandler) {
            JoyFuncHandler(h)
        } else {
            DefaultCsrfErrorHandler.INSTANCE
        }
    }

    private static func createExtractFunc(lookupKey: String): CsrfExtractFunc {
        let sn = lookupKey.split(":")
        if (sn.size != 2) {
            throw IllegalArgumentException("keyLookup format must be <source>:<name>")
        }
        match (sn[0]) {
            case "header" => {
                ctx: JoyContext =>
                    let value = ctx.getHeader(sn[1])
                    if (let Some(v) <- value) {
                        return (v, sn[0])
                    }
                    return ("", sn[0])
            }
            case "query" => {
                ctx: JoyContext =>
                    let value = ctx.getQuery(sn[1])
                    if (let Some(v) <- value) {
                        return (v, sn[0])
                    }
                    return ("", sn[0])
            }
            case "param" => {
                ctx: JoyContext =>
                    let value = ctx.getParam(sn[1])
                    if (let Some(v) <- value) {
                        return (v, sn[0])
                    }
                    return ("", sn[0])
            }
            case "form" => {
                ctx: JoyContext =>
                    let value = ctx.getPostForm(sn[1])
                    if (let Some(v) <- value) {
                        return (v, sn[0])
                    }
                    return ("", sn[0])
            }
            case _ => throw IllegalArgumentException(
                "lookupKey format must be <source>:<name>, source must be one of [header, query, form, param]")
        }
    }

    static func tokenize(secret: String, salt: String): String {
        var md: Array<Byte> = digest(SHA256(), "${salt}-${secret}".toArray())
        rawBase64URLEncode(md)
    }

    public func handle(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
        if (let Some(fn) <- _filterHandler) {
            if (fn(ctx)) {
                chain.next(ctx)
                return
            }
        }

        // Set secret to generate token in getCSRFToken func
        let session = getSession(ctx).getOrThrow()
        session.set(csrfSecretCtxKey, _secret)

        if (_ignoreMethods.contains(ctx.method)) {
            chain.next(ctx)
            return
        }

        let salt = session.get<String>(csrfSaltCtxKey)
        if (salt.isNone()) {
            @JoyLogError("[CSRF] miss salt")
            _errorHandler.handle(ctx)
            return
        }

        let (token, source) = _handleFunc(ctx)
        if (token.isEmpty()) {
            @JoyLogError("[CSRF] miss token in ${source}")
            _errorHandler.handle(ctx)
            return
        }

        if (tokenize(_secret, salt.getOrThrow()) != token) {
            @JoyLogError("[CSRF] invalid token")
            _errorHandler.handle(ctx)
            return
        }

        chain.next(ctx)
    }
}
