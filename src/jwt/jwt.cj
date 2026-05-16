/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.jwt

import std.time.DateTime
import cjoy.json.JsonTool
import cjoy.utils.{rawBase64URLEncode, rawBase64URLDecode}

/**
 * 用于认证和信息交换的 JWT (JSON Web Token)
 */
public class Jwt {
    private var _headers: MapHeaders = MapHeaders()
    private var _claims: MapClaims = MapClaims()
    private var _method: ?SigningMethod = None

    private var _valid: Bool = false
    private var _signature: String = ""
    private var _text: String = ""
    private var _parseConfig: ?ParserConfig = None

    private init() {
        _headers.header("typ", "JWT")
    }

    /**
     * 创建 JWT 并将其签名为令牌字符串
     */
    public static func create(): Jwt {
        Jwt()
    }

    /**
     * 返回 JWT 的头部
     */
    public prop headers: Headers {
        get() {
            _headers
        }
    }

    /**
     * 返回 JWT 的声明
     */
    public prop claims: Claims {
        get() {
            _claims
        }
    }

    /**
     * 指定签名算法
     *
     * @param alg 算法
     * @throws JwtException 如果未找到签名算法
     */
    public func alg(alg: String): Jwt {
        _method = SigningMethods.getMethod(alg)
        if (_method.isNone()) {
            throw JwtException("not found signing methods for ${alg}")
        }
        _headers.header("alg", alg)
        this
    }

    /**
     * 从原始 JWT 复制声明
     *
     * @param jwt 原始 JWT
     */
    public func copyClaims(jwt: Jwt): Unit {
        _claims.add(all: jwt._claims)
    }

    /**
     * 使用算法和密钥将 JWT 签名为字符串
     *
     * @param key 算法密钥，如 Array<Byte> 或 RSAPrivateKey
     * @return 已签名的 JWT 字符串
     * @throws JwtException 如果未调用 alg
     */
    public func signWith(key: Any): String {
        if (_method.isNone()) {
            throw JwtException("must invoke alg(str) firstly.")
        }

        let sstr = signingString()
        let sig = _method?.sign(sstr, key) ?? Array<Byte>()
        sstr + "." + encodeSegment(sig)
    }

    /**
     * 将字符串令牌解析为 JWT
     *
     * @param token 要解析的令牌
     * @param config 解析器配置
     * @return JWT 对象
     */
    public static func parse(token: String, config!: ParserConfig = ParserConfig()): Jwt {
        let jwt = Jwt()
        jwt._parseConfig = config
        jwt.parseToken(token)
        jwt
    }

    /**
     * 使用算法密钥验证 JWT
     *
     * @param key 算法密钥，如 Array<Byte> 或 RSAPublicKey
     * @throws JwtException 如果验证失败
     */
    public func verifyWith(key: Any): Jwt {
        if (_valid) {
            return this
        }

        let cfg = _parseConfig.getOrThrow()
        validateMethod(cfg)

        let sig = decodeSegemnt(_signature)
        _method?.verify(_text, sig, key)

        if (cfg.skipClaimsValidation) {
            _valid = true
            return this
        }

        let now = if (let Some(fn) <- cfg.timeFunc) {
            fn()
        } else {
            DateTime.now()
        }

        validateExpirationTime(cfg, now)
        validateNotBefore(cfg, now)
        validateIssuedAt(cfg, now)
        validateAudience(cfg)
        validateIssuer(cfg)
        validateSubject(cfg)

        _valid = true
        this
    }

    /**
     * @throws JwtException
     */
    private func validateMethod(cfg: ParserConfig): Unit {
        if (!cfg.validMethods.isEmpty()) {
            let alg = _method?.alg ?? ""
            if (!cfg.validMethods.contains(alg)) {
                throw JwtException("token signature is invalid, signing method ${alg} is invalid")
            }
        }
    }

    /**
     *
     *  The "exp" (expiration time) claim identifies the expiration time on
     *  or after which the JWT MUST NOT be accepted for processing.  The
     *  processing of the "exp" claim requires that the current date/time
     *  MUST be before the expiration date/time listed in the "exp" claim.
     * @throws JwtException if validate failed
     */
    private func validateExpirationTime(cfg: ParserConfig, now: DateTime): Unit {
        if (let Some(v) <- _claims.getExpirationTime()) {
            if ((v.value + cfg.leeway) < now) {
                throw JwtException("token is expired")
            }
        } else {
            if (cfg.expirationRequired) {
                throw JwtException("token is missing required claim, not found expireTime")
            }
        }
    }

    /**
     *
     *  The "nbf" (not before) claim identifies the time before which the JWT
     *  MUST NOT be accepted for processing.  The processing of the "nbf"
     *  claim requires that the current date/time MUST be after or equal to
     *  the not-before date/time listed in the "nbf" claim.  Implementers MAY
     *  provide for some small leeway, usually no more than a few minutes, to
     *  account for clock skew.  Its value MUST be a number containing a
     *  NumericDate value.  Use of this claim is OPTIONAL.
     *    
     * @throws JwtException if validate failed
     */
    private func validateNotBefore(cfg: ParserConfig, now: DateTime): Unit {
        if (let Some(v) <- _claims.getNotBefore()) {
            if ((v.value - cfg.leeway) > now) {
                throw JwtException("token is not valid yet")
            }
        } else {
            if (cfg.notBeforeRequired) {
                throw JwtException("token is missing required claim, not found notBefore")
            }
        }
    }

    /**
     *
     *  The "iat" (issued at) claim identifies the time at which the JWT was
     *  issued.  This claim can be used to determine the age of the JWT.  Its
     *  value MUST be a number containing a NumericDate value.  Use of this
     *  claim is OPTIONAL.
     *
     * @throws JwtException if validate failed
     */
    private func validateIssuedAt(cfg: ParserConfig, now: DateTime): Unit {
        if (let Some(v) <- _claims.getIssuedAt()) {
            if ((v.value - cfg.leeway) > now) {
                throw JwtException("token used before issued")
            }
        } else {
            if (cfg.issueAtRequired) {
                throw JwtException("token is missing required claim, not found issuedAt")
            }
        }
    }

    /**
     * @throws JwtException
     */
    private func validateAudience(cfg: ParserConfig): Unit {
        let aud = _claims.getAudience()
        if (!cfg.expectedAud.isEmpty()) {
            if (aud.isNone()) {
                throw JwtException("token is missing required claim, not found audience")
            }
        } else {
            return
        }

        let auds = aud.getOrThrow().claims
        if (cfg.expectedAllAud) {
            for (a in cfg.expectedAud) {
                if (!auds.contains(a)) {
                    throw JwtException("token has invalid audience")
                }
            }
        } else {
            if (cfg.expectedAud.isEmpty()) {
                return
            }
            var found = false
            for (a in auds) {
                if (cfg.expectedAud.contains(a)) {
                    found = true
                    break
                }
            }
            if (!found) {
                throw JwtException("token has invalid audience")
            }
        }
    }

    private func validateIssuer(cfg: ParserConfig): Unit {
        if (!cfg.expectedIss.isEmpty()) {
            let iss = _claims.getIssuer()
            if (iss.isNone() || iss.getOrThrow() != cfg.expectedIss) {
                throw JwtException("token has invalid issuer")
            }
        }
    }

    private func validateSubject(cfg: ParserConfig): Unit {
        if (!cfg.expectedSub.isEmpty()) {
            let sub = _claims.getSubject()
            if (sub.isNone() || sub.getOrThrow() != cfg.expectedSub) {
                throw JwtException("token has invalid subject")
            }
        }
    }

    private func encodeSegment(seg: Array<Byte>): String {
        rawBase64URLEncode(seg)
    }

    private func signingString(): String {
        let h = JsonTool.toJsonBytes(_headers)
        let c = JsonTool.toJsonBytes(_claims)
        encodeSegment(h) + "." + encodeSegment(c)
    }

    /**
     * @throws JwtException
     */
    private func parseToken(token: String): Unit {
        if (token.isEmpty()) {
            throw JwtException("token is malformed, token is empty")
        }

        let segs = token.split(".")
        if (segs.size != 3) {
            throw JwtException("token is malformed, token contains an invalid number of segments")
        }
        let (header, claims, signature) = (segs[0], segs[1], segs[2])

        var bs: Array<Byte> = decodeSegemnt(header)
        try {
            _headers = (JsonTool.fromJsonToSerializable(bs) as MapHeaders).getOrThrow()
        } catch (ex: Exception) {
            throw JwtException("token is malformed, could not JSON decode header")
        }

        bs = decodeSegemnt(claims)
        try {
            _claims = (JsonTool.fromJsonToSerializable(bs) as MapClaims).getOrThrow()
        } catch (ex: Exception) {
            throw JwtException("token is malformed, could not JSON decode claim")
        }

        let alg = _headers
            .getString("alg")
            .getOrThrow({=> JwtException("token is unverifiable, signing method (alg) is unspecified")})
        _method = SigningMethods.getMethod(alg)
        if (_method.isNone()) {
            throw JwtException("token is unverifiable, signing method (alg) is unavailable")
        }

        _signature = signature
        _text = String.join([header, claims], delimiter: ".")
    }

    private func decodeSegemnt(seg: String): Array<Byte> {
        rawBase64URLDecode(seg).getOrThrow({=> JwtException("token is malformed, could not base64 decode")})
    }
}

/**
 * JWT (JSON Web Token) 解析器配置
 */
public struct ParserConfig {
    public ParserConfig(
        // 如果设置，则只有这些方法将被视为有效
        let validMethods!: Array<String> = Array(),
        // 在令牌解析期间跳过声明验证
        let skipClaimsValidation!: Bool = false,
        // 指定容差窗口
        let leeway!: Duration = Duration.second * 0,
        // 主要用例是测试。如果要考虑时钟偏移，应使用指定 leeway 的方式
        let timeFunc!: ?() -> DateTime = None,
        // 要求 `iat` 声明
        let issueAtRequired!: Bool = false,
        // 要求 `exp` 声明
        let expirationRequired!: Bool = false,
        // 要求 `nbf` 声明
        let notBeforeRequired!: Bool = false,
        // 要求在 `aud` 声明中包含任意一个指定的受众。如果令牌中未列出受众或缺少 `aud` 声明，则验证失败
        let expectedAud!: Array<String> = [],
        // 要求所有指定的受众
        let expectedAllAud!: Bool = false,
        // 预期的签发者
        let expectedIss!: String = "",
        // 预期的主题
        let expectedSub!: String = "") {
    }
}
