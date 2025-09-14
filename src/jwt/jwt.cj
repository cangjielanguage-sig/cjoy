/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.jwt

import std.time.DateTime
import stdx.encoding.base64.{toBase64String, fromBase64String}
import stdx.encoding.json.stream.{JsonDeserializable, JsonSerializable}
import cjoy.json.JsonTool
import cjoy.utils.StrFunc

public class Jwt {
    private var _headers: MapHeaders = MapHeaders()
    private var _claims: MapClaims = MapClaims()
    private var _method: ?SigningMethod = None

    private var _valid: Bool = true
    private var _signature: String = ""
    private var _text: String = ""
    private var _parseConfig: ?ParserConfig = None

    private init() {
        _headers.header("typ", "JWT")
    }

    /**
     * create a JWT and sign to token string
     */
    public static func create(): Jwt {
        Jwt()
    }

    public prop headers: Headers {
        get() {
            _headers
        }
    }

    public prop claims: Claims {
        get() {
            _claims
        }
    }

    public func alg(alg: String): Jwt {
        _method = SigningMethods.getMethod(alg)
        if (_method.isNone()) {
            throw JwtException("not found signing methods for ${alg}")
        }
        _headers.header("alg", alg)
        this
    }

    public func signWith(key: Any): String {
        if (_method.isNone()) {
            throw JwtException("must invoke alg(str) firstly.")
        }

        let sstr = signingString()
        let sig = _method?.sign(sstr, key) ?? Array<Byte>()
        sstr + "." + encodeSegemnt(sig)
    }

    /**
     * pasrse the string token to JWT
     */
    public static func pasrse(token: String, config!: ParserConfig = ParserConfig()): Jwt {
        let jwt = Jwt()
        jwt._parseConfig = config
        jwt.parseToken(token)
        jwt
    }

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

        _valid = true
        this
    }

    private func validateMethod(cfg: ParserConfig): Unit {
        if (!cfg.validMethods.isEmpty()) {
            let alg = _method?.alg ?? ""
            if (!cfg.validMethods.contains(alg)) {
                throw JwtException("token signature is invalid, signing method ${alg} is invalid")
            }
        }
    }

    private func validateExpirationTime(cfg: ParserConfig, now: DateTime): Unit {
        if (let Some(v) <- _claims.getExpirationTime()) {
            if (v.value.addNanoseconds(cfg.leeway.toNanoseconds()) > now) {
                throw JwtException("token is expired")
            }
        } else {
            if (cfg.expirationRequired) {
                throw JwtException("token is missing required claim, not found expireTime")
            }
        }
    }

    private func validateNotBefore(cfg: ParserConfig, now: DateTime): Unit {
        if (let Some(v) <- _claims.getNotBefore()) {
            if (v.value.addNanoseconds(-cfg.leeway.toNanoseconds()) < now) {
                throw JwtException("token is not valid yet")
            }
        } else {
            if (cfg.notBeforeRequired) {
                throw JwtException("token is missing required claim, not found notBefore")
            }
        }
    }

    private func validateIssuedAt(cfg: ParserConfig, now: DateTime): Unit {
        if (let Some(v) <- _claims.getIssuedAt()) {
            if (v.value.addNanoseconds(-cfg.leeway.toNanoseconds()) < now) {
                throw JwtException("token used before issued")
            }
        } else {
            if (cfg.issueAtRequired) {
                throw JwtException("token is missing required claim, not found issuedAt")
            }
        }
    }

    private func validateAudience(cfg: ParserConfig): Unit {
        let aud = _claims.getAudience()
        if (!cfg.expectedAud.isEmpty()) {
            if (aud.isNone()) {
                throw JwtException("token is missing required claim, not found audience")
            }
        }

        let auds = aud.getOrThrow().claims
        if (cfg.expectedAllAud) {
            for (a in cfg.expectedAud) {
                if (!auds.contains(a)) {
                    throw JwtException("token has invalid audience")
                }
            }
        } else {
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

    private func encodeSegemnt(seg: Array<Byte>): String {
        var res: String = toBase64String(seg)
        res = res.trimEnd("=")
        res = res.replace("+", "_")
        res = res.replace("/", "_")
        res
    }

    private func signingString(): String {
        let h = JsonTool.toJsonBytes(_headers)
        let c = JsonTool.toJsonBytes(_claims)
        encodeSegemnt(h) + "." + encodeSegemnt(c)
    }

    private func parseToken(token: String): Unit {
        let segs = token.split(".")
        if (segs.size != 3) {
            throw JwtException("token is malformed, token contains an invalid number of segments")
        }
        let (header, claims, signature) = (segs[0], segs[1], segs[2])

        var bs: Array<Byte> = decodeSegemnt(header)
        try {
            _headers = (JsonTool.fromJsonToAny(bs) as MapHeaders).getOrThrow()
        } catch (ex: Exception) {
            throw JwtException("token is malformed, could not JSON decode header")
        }

        bs = decodeSegemnt(claims)
        try {
            _claims = (JsonTool.fromJsonToAny(bs) as MapClaims).getOrThrow()
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
        var v = seg
        let len = seg.size % 4
        if (len > 0) {
            v += String.repeat("=", 4 - len)
        }
        v = v.replace("-", "+")
        v = v.replace("_", "/")
        fromBase64String(v).getOrThrow({=> JwtException("token is malformed, could not base64 decode")})
    }
}

public struct ParserConfig {
    public ParserConfig(let validMethods!: Array<String> = Array(), let skipClaimsValidation!: Bool = false,
        let leeway!: Duration = Duration.second * 0, let timeFunc!: ?() -> DateTime = None,
        let issueAtRequired!: Bool = false, let expirationRequired!: Bool = false, let notBeforeRequired!: Bool = false,
        let expectedAud!: Array<String> = [], let expectedAllAud!: Bool = false) {
    }
}
