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

import std.time.{DateTime, DateTimeFormat}
import stdx.net.http.{HttpStatusCode, Cookie}
import stdx.crypto.keys.{RSAPrivateKey, RSAPublicKey}
import cjoy.{JoyMiddlewareHandler, JoyRequestHandlerChain, JoyContext, JoyHttpConsts, JoyRequestHandlerFunc}
import cjoy.log.macros.*
import cjoy.jwt.*
import cjoy.json.*
import cjoy.json.macros.*

private const JWT_CTX_KEY: String = "__jwt__"
private const JWT_PAYLOAD_CTX_KEY: String = "__jwt_payload__"

/**
 * 从上下文中获取 JWT 令牌
 */
public func getJwt(ctx: JoyContext): ?String {
    ctx.getCtxParam(JWT_CTX_KEY)
}

/**
 * JWT 签名和验证密钥的接口
 */
public interface Jwtkey {
    /**
     * 返回签名和验证密钥
     */
    func getKeys(jwt: Jwt): Array<Any>
}

/**
 * HMAC (HS256, HS384, HS512) 算法密钥
 */
public class HmacSigningkey <: Jwtkey {
    /**
     * 创建 HMAC 签名密钥
     *
     * @param key HMAC 密钥字节数组
     */
    public HmacSigningkey(let key: Array<Byte>) {
    }

    public func getKeys(_: Jwt): Array<Any> {
        [key, key]
    }
}

/**
 * RSA (RS256, RS384, RS512) 算法密钥
 */
public class RsaSigningkey <: Jwtkey {
    /**
     * 创建 RSA 签名密钥
     *
     * @param privateKey RSA 私钥，用于签名
     * @param publicKey RSA 公钥，用于验证
     */
    public RsaSigningkey(let privateKey: RSAPrivateKey, let publicKey: RSAPublicKey) {
    }

    public func getKeys(_: Jwt): Array<Any> {
        [privateKey, publicKey]
    }
}

/**
 * JWT 认证中间件
 */
public class JwtAuth <: JoyMiddlewareHandler {
    private let _getTokenFunc: (ctx: JoyContext) -> ?String

    /**
     * 构造 JwtAuth 实例。
     *
     * @param realm 向用户显示的领域名称
     * @param signingAlg 签名算法 -可能的值为 HS256、HS384、HS512、RS256、RS384 或 RS512
     * @param keyProvider 用于获取签名或验证密钥的回调函数
     * @param authenticator 执行用户身份验证的回调函数。必须在上下文中设置用户数据作为用户标识符，它将存储在 Claim 数组中
     * @param authorizator 执行已认证用户授权的回调函数。仅在身份验证成功后调用。成功时返回 true，失败时返回 false
     * @param setPayload 登录时调用的回调函数。使用此函数可以向 webtoken 添加额外的负载数据。请注意，负载未加密。jwt.io 上提到的属性不能用作映射的键
     * @param unauthorized 用户可以定义自己的 Unauthorized 函数
     * @param loginResponse 用户可以定义自己的 LoginResponse 函数
     * @param logoutResponse 用户可以定义自己的 LogoutResponse 函数
     * @param refreshResponse 用户可以定义自己的 RefreshResponse 函数
     * @param timeout JWT 令牌的有效时长
     * @param maxRefresh 刷新令牌的时长。客户端可以在 maxRefresh 结束前的最后时刻刷新令牌。这意味着令牌的最大有效时间跨度为 tokenTime + maxRefresh。默认为 0 表示不可刷新
     * @param identityKey 设置身份密钥
     * @param identityHandler 设置身份处理函数
     * @param tokenLookup TokenLookup 是一个 "<source>:<name>" 形式的字符串，用于从请求中提取令牌。可能的值：header、query、cookie、param、form
     * @param tokenHeadName 头部中的字符串
     * @param sendCookie 作为 cookie 的令牌
     * @param cookieMaxAge Cookie 的有效时长。可选，默认为 Timeout 值
     * @param cookieSecure 是否使用安全 Cookie
     * @param cookieHttpOnly 是否只允许 HTTP 访问 Cookie
     * @param cookieDomain Cookie 域名
     * @param cookieName Cookie 名称
     * @param sendAuthorization 允许为每个请求返回授权头部
     * @param jwtParserConfig 修改 jwt 解析配置
     */
    public JwtAuth(let realm!: String, let signingAlg!: String, let keyProvider!: Jwtkey,
        let authenticator!: JoyRequestHandlerFunc,
        let authorizator!: (ctx: JoyContext, identity: String) -> Bool = defaultAuthorizator,
        let setPayload!: (ctx: JoyContext, jwt: Jwt) -> Unit = defaultPayloadFunc,
        let unauthorized!: (ctx: JoyContext, code: UInt16, message: String) -> Unit = defaultUnauthorized,
        let loginResponse!: (ctx: JoyContext, code: UInt16, token: String, expire: DateTime) -> Unit = defaultLoginResponse,
        let logoutResponse!: (ctx: JoyContext, code: UInt16) -> Unit = defaultLogoutResponse,
        let refreshResponse!: (ctx: JoyContext, code: UInt16, token: String, expire: DateTime) -> Unit = defaultLoginResponse,
        let timeout!: Duration = Duration.minute * 30, let maxRefresh!: Duration = Duration.Zero,
        let identityKey!: String = "identity", var identityHandler!: ?(ctx: JoyContext) -> String = None,
        let tokenLookup!: String = "header:Authorization", let tokenHeadName!: String = "Bearer",
        let sendCookie!: Bool = false, let cookieMaxAge!: Duration = Duration.minute * 30,
        let cookieSecure!: Bool = false, let cookieHttpOnly!: Bool = true, let cookieDomain!: String = "",
        let cookieName!: String = "jwt", let sendAuthorization!: Bool = false,
        let jwtParserConfig!: ?ParserConfig = None) {
        _getTokenFunc = createGetTokenFunc(tokenLookup, tokenHeadName)
        if (this.identityHandler.isNone()) {
            this.identityHandler = {
                ctx: JoyContext =>
                    let claims = ctx.getCtxParam<Claims>(JWT_PAYLOAD_CTX_KEY)
                    claims.getOrThrow().getClaimString(identityKey) ?? ""
            }
        }
    }

    /**
     * @throws IllegalArgumentException
     */
    private static func createGetTokenFunc(tokenLookup: String, tokenHeadName: String): (ctx: JoyContext) -> ?String {
        let sn = tokenLookup.split(":")
        if (sn.size != 2) {
            throw IllegalArgumentException("tokenLookup format must be <source>:<name>")
        }
        match (sn[0]) {
            case "header" => {
                ctx: JoyContext =>
                    let value = ctx.getHeader(sn[1])
                    if (let Some(v) <- value) {
                        if (tokenHeadName != "") {
                            if (v.startsWith("${tokenHeadName} ")) {
                                return v[(tokenHeadName.size + 1)..]
                            }
                        }
                    }
                    value
            }
            case "query" => {
                ctx: JoyContext => ctx.getQuery(sn[1])
            }
            case "form" => {
                ctx: JoyContext => ctx.getPostForm(sn[1])
            }
            case "param" => {
                ctx: JoyContext => ctx.getParam(sn[1])
            }
            case "cookie" => {
                ctx: JoyContext => ctx.getCookie(sn[1])
            }
            case _ => throw IllegalArgumentException(
                "lookupKey format must be <source>:<name>, source must be one of [header, query, form, param, cookie]")
        }
    }

    public func handle(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
        try {
            // authentication: Explain Token
            setClaims(ctx)
            let identifier = identityHandler?(ctx) ?? ""
            if (identifier != "") {
                ctx.setCtxParam(identityKey, identifier)
            }

            // authorization callback
            if (!authorizator(ctx, identifier)) {
                doUnauthorized(ctx, HttpStatusCode.STATUS_FORBIDDEN, "authorizate failed")
                return
            }

            chain.next(ctx)
        } catch (ex: JwtException) {
            doUnauthorized(ctx, HttpStatusCode.STATUS_UNAUTHORIZED, ex.message)
        }
    }

    public func loginHandler(ctx: JoyContext): Unit {
        authenticator(ctx)
        if (ctx.respStatus != HttpStatusCode.STATUS_OK) {
            return
        }

        try {
            // create the token
            let jwt = Jwt.create().alg(signingAlg)
            setPayload(ctx, jwt)

            let now = DateTime.now()
            let expire = now.addNanoseconds(timeout.toNanoseconds())
            jwt.claims.expirationTime(expire)
            jwt.claims.issuedAt(now)

            let token = jwt.signWith(this.keyProvider.getKeys(jwt)[0])
            if (sendCookie) {
                let c = Cookie(cookieName, token, maxAge: cookieMaxAge.toSeconds(), domain: cookieDomain, path: "/",
                    secure: cookieSecure, httpOnly: cookieHttpOnly)
                ctx.cookie(c)
            }

            // callback loginResponse
            loginResponse(ctx, HttpStatusCode.STATUS_OK, token, expire)
        } catch (ex: JwtException) {
            doUnauthorized(ctx, HttpStatusCode.STATUS_UNAUTHORIZED, ex.message)
        }
    }

    public func logoutHandler(ctx: JoyContext): Unit {
        if (sendCookie) {
            // delete auth cookie
            let c = Cookie(cookieName, "", expires: DateTime.UnixEpoch, domain: cookieDomain, path: "/",
                secure: cookieSecure, httpOnly: cookieHttpOnly)
            ctx.cookie(c)
        }

        // callback logoutResponse
        logoutResponse(ctx, HttpStatusCode.STATUS_OK)
    }

    public func refreshTokenHandler(ctx: JoyContext): Unit {
        try {
            let origJwt = checkIfTokenExpire(ctx)

            // create new token
            let jwt = Jwt.create().alg(signingAlg)
            jwt.copyClaims(origJwt)

            let now = DateTime.now()
            let expire = now.addNanoseconds(timeout.toNanoseconds())
            jwt.claims.expirationTime(expire)
            jwt.claims.issuedAt(now)

            let token = jwt.signWith(this.keyProvider.getKeys(jwt)[0])
            if (sendCookie) {
                let c = Cookie(cookieName, token, maxAge: cookieMaxAge.toSeconds(), domain: cookieDomain, path: "/",
                    secure: cookieSecure, httpOnly: cookieHttpOnly)
                ctx.cookie(c)
            }

            // callback refreshResponse
            refreshResponse(ctx, HttpStatusCode.STATUS_OK, token, expire)
        } catch (ex: JwtException) {
            doUnauthorized(ctx, HttpStatusCode.STATUS_UNAUTHORIZED, ex.message)
        }
    }

    private func parseToken(ctx: JoyContext): Jwt {
        let token = _getTokenFunc(ctx).getOrThrow({=> throw JwtException("not found token in reqired field")})
        let jwt = Jwt.parse(token,
            config: jwtParserConfig ?? ParserConfig(expirationRequired: true, issueAtRequired: true))
        if (jwt.headers.alg != signingAlg) {
            throw JwtException("invalid signing algorithm")
        }

        jwt.verifyWith(keyProvider.getKeys(jwt)[1])
        // save token string if valid
        ctx.setCtxParam(JWT_CTX_KEY, token)
        jwt
    }

    private func setClaims(ctx: JoyContext): Unit {
        let jwt = parseToken(ctx)
        if (sendAuthorization) {
            if (let Some(t) <- getJwt(ctx)) {
                ctx.header(JoyHttpConsts.HEADER_AUTHORIZATION, "${tokenHeadName} ${t}")
            }
        }

        ctx.setCtxParam(JWT_PAYLOAD_CTX_KEY, jwt.claims)
    }

    private func checkIfTokenExpire(ctx: JoyContext): Jwt {
        let jwt = parseToken(ctx)
        if (let Some(iat) <- jwt.claims.getIssuedAt()) {
            if (iat.value < DateTime.now().addNanoseconds(-maxRefresh.toNanoseconds())) {
                throw JwtException("token is expired")
            }
        } else {
            throw JwtException("token is expired")
        }
        jwt
    }

    private func doUnauthorized(ctx: JoyContext, code: UInt16, message: String): Unit {
        ctx.header(JoyHttpConsts.HEADER_WWW_AUTHENTICATE, "JWT realm=" + realm)
        @JoyLogError("[JwtAuth] auth failed, ${ctx.getClientIP()}, ${ctx.method} ${ctx.url}, ${message}")
        unauthorized(ctx, code, message)
    }
}

func defaultAuthorizator(_: JoyContext, _: String): Bool {
    return true
}

func defaultPayloadFunc(_: JoyContext, _: Jwt): Unit {
}

func defaultUnauthorized(ctx: JoyContext, code: UInt16, message: String): Unit {
    ctx.status(code).json(@ToJson(
        {
            "code": code,
            "message": message
        }
    ))
}

func defaultLoginResponse(ctx: JoyContext, code: UInt16, token: String, expire: DateTime): Unit {
    let df = expire.format(DateTimeFormat.RFC3339)
    ctx
        .status(code)
        .json(
            @ToJson(
                {
                    "code": code,
                    "token": token,
                    "expire": df
                }
        ))
}

func defaultLogoutResponse(ctx: JoyContext, code: UInt16): Unit {
    ctx.status(code).json(@ToJson(
        {
            "code": code
        }
    ))
}
