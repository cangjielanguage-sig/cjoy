/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
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
const csrfSaltCtxKey = "__csrf_salt__"

// the extract token function
type CrsfExtractFunc = (ctx: JoyContext) -> (String, String)

// the default authentication failure handler 
class DefaultCrsfErrorHandler <: JoyRequestHandler {
    static let INSTANCE = DefaultCrsfErrorHandler()

    public func handle(ctx: JoyContext): Unit {
        @LogError("[CRSF] verify failed, ${ctx.getClientIP()}, ${ctx.method} ${ctx.url}")
        ctx.status(HttpStatusCode.STATUS_UNAUTHORIZED)
    }
}

/**
 * obtain or generate one CRSF token
 */
public func getCrsfToken(ctx: JoyContext): String {
    let session = getSession(ctx).getOrThrow()
    let secret = session.get<String>(csrfSecretCtxKey).getOrThrow()

    if (let Some(t) <- session.get<String>(csrfTokenCtxKey)) {
        return t
    }

    let salt = if (let Some(s) <- session.get<String>(csrfSaltCtxKey)) {
        s
    } else {
        let s = secureRandStr(16)
        session.set(csrfSaltCtxKey, s)
        s
    }

    let token = CrsfProtect.tokenize(secret, salt)
    session.set(csrfTokenCtxKey, token)
    token
}

/**
 * token Crsf protect middleware
 */
public class CrsfProtect <: JoyMiddlewareHandler {
    private let _secret: String
    private let _handleFunc: CrsfExtractFunc
    private let _ignoreMethods: Array<String>
    private let _filterHandler: ?JoyRequestFilterFunc
    private let _errorHandler: JoyRequestHandler

    /**
     * @param secret: used to generate token.
     * @param ignoreMethods: will be considered no protection required.
     * @param lookupKey: is a string in the form of "<source>:<key>" that is used to extract the token from the request.
     *       Possible values:
     *        - "header:<name>"
     *        - "query:<name>"
     *        - "param:<name>"
     *        - "form:<name>"
     * @param filterHandler: a function to skip this middleware.
     * @param errorHandler: a function to executed when an error.
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
            DefaultCrsfErrorHandler.INSTANCE
        }
    }

    private static func createExtractFunc(lookupKey: String): CrsfExtractFunc {
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

        // Set secret to generate token in getCrsfToken func
        let session = getSession(ctx).getOrThrow()
        session.set(csrfSecretCtxKey, _secret)

        if (_ignoreMethods.contains(ctx.method)) {
            chain.next(ctx)
            return
        }

        let salt = session.get<String>(csrfSaltCtxKey)
        if (salt.isNone()) {
            @LogError("[CRSF] miss salt")
            _errorHandler.handle(ctx)
            return
        }

        let (token, source) = _handleFunc(ctx)
        if (token.isEmpty()) {
            @LogError("[CRSF] miss token in ${source}")
            _errorHandler.handle(ctx)
            return
        }

        if (tokenize(_secret, salt.getOrThrow()) != token) {
            @LogError("[CRSF] invalid token")
            _errorHandler.handle(ctx)
            return
        }

        chain.next(ctx)
    }
}
