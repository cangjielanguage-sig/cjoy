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

import std.time.{DateTime, DateTimeFormat}
import stdx.net.http.{HttpStatusCode, Cookie}
import stdx.crypto.keys.{RSAPrivateKey, RSAPublicKey}
import cjoy.{JoyMiddlewareHandler, JoyRequestHandlerChain, JoyContext, JoyHttpConsts, JoyRequestHandlerFunc}
import cjoy.log.*
import cjoy.jwt.*
import cjoy.json.*

const jwtCtxKey = "__jwt__"
const jwtPayloadCtxKey = "__jwt_payload__"

/**
 * return the jwt token form context
 */
public func getJwt(ctx: JoyContext): ?String {
    ctx.getCtxParam(jwtCtxKey)
}

public interface Jwtkey {
    /**
     * return the sign and verify key
     */
    func getKeys(jwt: Jwt): Array<Any>
}

/**
 * the HSXXX algorithm key
 */
public class HmacSigningkey <: Jwtkey {
    public HmacSigningkey(let key: Array<Byte>) {
    }

    public func getKeys(_: Jwt): Array<Any> {
        [key, key]
    }
}

/**
 * the RSXXX algorithm key
 */
public class RsaSigningkey <: Jwtkey {
    public RsaSigningkey(let privateKey: RSAPrivateKey, let publicKey: RSAPublicKey) {
    }

    public func getKeys(_: Jwt): Array<Any> {
        [privateKey, publicKey]
    }
}

/**
 * jwt authentication middleware
 */
public class JwtAuth <: JoyMiddlewareHandler {
    private let _getTokenFunc: (ctx: JoyContext) -> ?String

    public JwtAuth(
        // Realm name to display to the user.
        let realm!: String,
        // Signing algorithm - possible values are HS256, HS384, HS512, RS256, RS384 or RS512
        let signingAlg!: String,
        // Callback to retrieve key used for signing or verifing.
        let keyProvider!: Jwtkey,
        // Callback function that should perform the authentication of the user based on login info.
        // Must set user data as user identifier in context, it will be stored in Claim Array.
        let authenticator!: JoyRequestHandlerFunc,
        // Callback function that should perform the authorization of the authenticated user.
        // called only after an authentication success. Must return true on success, false on failure.
        let authorizator!: (ctx: JoyContext, identity: String) -> Bool = defaultAuthorizator,
        // Callback function that will be called during login.
        // Using this function it is possible to add additional payload data to the webtoken.
        // Note that the payload is not encrypted.
        // The attributes mentioned on jwt.io can't be used as keys for the map.
        let setPayload!: (ctx: JoyContext, jwt: Jwt) -> Unit = defaultPayloadFunc,
        // User can define own Unauthorized func.
        let unauthorized!: (ctx: JoyContext, code: UInt16, message: String) -> Unit = defaultUnauthorized,
        // User can define own LoginResponse func.
        let loginResponse!: (ctx: JoyContext, code: UInt16, token: String, expire: DateTime) -> Unit = defaultLoginResponse,
        // User can define own LogoutResponse func.
        let logoutResponse!: (ctx: JoyContext, code: UInt16) -> Unit = defaultLogoutResponse,
        // User can define own RefreshResponse func.
        let refreshResponse!: (ctx: JoyContext, code: UInt16, token: String, expire: DateTime) -> Unit = defaultLoginResponse,
        // Duration that a jwt token is valid. 
        let timeout!: Duration = Duration.minute * 30,
        // Refresh their token until MaxRefresh has passed.
        // Note that clients can refresh their token in the last moment of maxRefresh.
        // This means that the maximum validity timespan for a token is tokenTime + maxRefresh.
        // defaults to 0 meaning not refreshable.
        let maxRefresh!: Duration = Duration.Zero,
        // Set the identity key
        let identityKey!: String = "identity",
        // Set the identity handler function
        var identityHandler!: ?(ctx: JoyContext) -> String = None,
        // TokenLookup is a string in the form of "<source>:<name>" that is used to extract token from the request.
        // Possible values:
        // - "header:<name>"
        // - "query:<name>"
        // - "cookie:<name>"
        // - "param:<name>"
        // - "form:<name>"
        let tokenLookup!: String = "header:Authorization",
        // is a string in the header.
        let tokenHeadName!: String = "Bearer",
        // token as a cookie
        let sendCookie!: Bool = false,
        // Duration that a cookie is valid. Optional, by default equals to Timeout value.
        let cookieMaxAge!: Duration = Duration.minute * 30,
        let cookieSecure!: Bool = false,
        let cookieHttpOnly!: Bool = true,
        let cookieDomain!: String = "",
        let cookieName!: String = "jwt",
        // allow return authorization header for every request
        let sendAuthorization!: Bool = false,
        // modify the jwt parse config
        let jwtParserConfig!: ?ParserConfig = None
    ) {
        _getTokenFunc = createGetTokenFunc(tokenLookup, tokenHeadName)
        if (this.identityHandler.isNone()) {
            this.identityHandler = {
                ctx: JoyContext =>
                    let claims = ctx.getCtxParam<Claims>(jwtPayloadCtxKey)
                    claims.getOrThrow().getClaimString(identityKey) ?? ""
            }
        }
    }

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
            if (ctx.config.enableDebugLog) {
                ex.printStackTrace()
            }
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
            if (ctx.config.enableDebugLog) {
                ex.printStackTrace()
            }
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
            if (ctx.config.enableDebugLog) {
                ex.printStackTrace()
            }
            doUnauthorized(ctx, HttpStatusCode.STATUS_UNAUTHORIZED, ex.message)
        }
    }

    private func paserToken(ctx: JoyContext): Jwt {
        let token = _getTokenFunc(ctx).getOrThrow({=> throw JwtException("not found token in reqired field")})
        let jwt = Jwt.pasrse(token,
            config: jwtParserConfig ?? ParserConfig(expirationRequired: true, issueAtRequired: true))
        if (jwt.headers.alg != signingAlg) {
            throw JwtException("invalid signing algorithm")
        }

        jwt.verifyWith(keyProvider.getKeys(jwt)[1])
        // save token string if valid
        ctx.setCtxParam(jwtCtxKey, token)
        jwt
    }

    private func setClaims(ctx: JoyContext): Unit {
        let jwt = paserToken(ctx)
        if (sendAuthorization) {
            if (let Some(t) <- getJwt(ctx)) {
                ctx.header(JoyHttpConsts.HEADER_AUTHORIZATION, "${tokenHeadName} ${t}")
            }
        }

        ctx.setCtxParam(jwtPayloadCtxKey, jwt.claims)
    }

    private func checkIfTokenExpire(ctx: JoyContext): Jwt {
        let jwt = paserToken(ctx)
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
        @LogError("[JwtAuth] auth failed, ${ctx.getClientIP()}, ${ctx.method} ${ctx.url}, ${message}")
        unauthorized(ctx, code, message)
    }
}

func defaultAuthorizator(ctx: JoyContext, identity: String): Bool {
    return true
}

func defaultPayloadFunc(ctx: JoyContext, jwt: Jwt): Unit {
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
