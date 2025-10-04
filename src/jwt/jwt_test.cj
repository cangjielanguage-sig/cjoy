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
import stdx.crypto.keys.{RSAPrivateKey, RSAPublicKey}

@Test
public class JwtTestCaseSuit {
    @TestCase
    public func testSignHS256() {
        let key = "abcd".toArray()
        let jwt = createJwt("HS256")
        let token = jwt.signWith(key)
        let jwt2 = Jwt.pasrse(token).verifyWith(key)
        assertJwt(jwt2)
    }

    @TestCase
    public func testSignHS384() {
        let key = "abcd".toArray()
        let jwt = createJwt("HS384")
        let token = jwt.signWith(key)
        let jwt2 = Jwt.pasrse(token).verifyWith(key)
        assertJwt(jwt2)
    }

    @TestCase
    public func testSignHS512() {
        let key = "abcd".toArray()
        let jwt = createJwt("HS512")
        let token = jwt.signWith(key)
        let jwt2 = Jwt.pasrse(token).verifyWith(key)
        assertJwt(jwt2)
    }

    @TestCase
    public func testParseValidateSkipClaimsValidation() {
        // issue at is invalid but skip claims validate
        let key = "abcd".toArray()
        let jwt = Jwt.create()
        jwt.alg("HS256")
        jwt
            .claims
            .issuer("cjoy")
            .audience("aud")
            .issuedAt(DateTime.now().addDays(1))
            .expirationTime(DateTime.now().addDays(1))
            .notBefore(DateTime.now().addSeconds(5))
            .subject("sub")
        let token = jwt.signWith(key)
        try {
            Jwt.pasrse(token, config: ParserConfig(skipClaimsValidation: true)).verifyWith(key)
        } catch (ex: JwtException) {
            @Fail(ex.message)
        }
    }

    @TestCase
    public func testParseValidateFailIssuedAt() {
        let key = "abcd".toArray()
        let jwt = Jwt.create()
        jwt.alg("HS256")
        jwt
            .claims
            .issuer("cjoy")
            .audience("aud")
            .issuedAt(DateTime.now().addDays(1))
            .expirationTime(DateTime.now().addDays(1))
            .notBefore(DateTime.now().addSeconds(5))
            .subject("sub")
        let token = jwt.signWith(key)
        try {
            Jwt.pasrse(token, config: ParserConfig()).verifyWith(key)
            @Fail("should throw jwt exception")
        } catch (ex: JwtException) {
            @Assert(ex.message.contains("before issued"))
        }
    }

    @TestCase
    public func testParseValidateFailIssuedAt2() {
        let key = "abcd".toArray()
        let jwt = Jwt.create()
        jwt.alg("HS256")
        jwt
            .claims
            .issuer("cjoy")
            .audience("aud")
            .expirationTime(DateTime.now().addDays(1))
            .notBefore(DateTime.now().addSeconds(5))
            .subject("sub")
        let token = jwt.signWith(key)
        try {
            Jwt.pasrse(token, config: ParserConfig(issueAtRequired: true)).verifyWith(key)
            @Fail("should throw jwt exception")
        } catch (ex: JwtException) {
            @Assert(ex.message.contains("missing required claim"))
        }
    }

    @TestCase
    public func testParseValidateFailExpire1() {
        let key = "abcd".toArray()
        let jwt = Jwt.create()
        jwt.alg("HS256")
        jwt
            .claims
            .issuer("cjoy")
            .audience("aud")
            .issuedAt(DateTime.now().addSeconds(-5))
            .expirationTime(DateTime.now().addSeconds(-1))
            .notBefore(DateTime.now().addSeconds(5))
            .subject("sub")
        let token = jwt.signWith(key)
        try {
            Jwt.pasrse(token, config: ParserConfig()).verifyWith(key)
            @Fail("should throw jwt exception")
        } catch (ex: JwtException) {
            @Assert(ex.message.contains("token is expired"))
        }
    }

    @TestCase
    public func testParseValidateFailExpire2() {
        let key = "abcd".toArray()
        let jwt = Jwt.create()
        jwt.alg("HS256")
        jwt
            .claims
            .issuer("cjoy")
            .audience("aud")
            .issuedAt(DateTime.now().addSeconds(-5))
            .notBefore(DateTime.now().addSeconds(5))
            .subject("sub")
        let token = jwt.signWith(key)
        try {
            Jwt.pasrse(token, config: ParserConfig(expirationRequired: true)).verifyWith(key)
            @Fail("should throw jwt exception")
        } catch (ex: JwtException) {
            @Assert(ex.message.contains("missing required claim"))
        }
    }

    @TestCase
    public func testParseValidateFailNotBefore1() {
        let key = "abcd".toArray()
        let jwt = Jwt.create()
        jwt.alg("HS256")
        jwt
            .claims
            .issuer("cjoy")
            .audience("aud")
            .issuedAt(DateTime.now().addSeconds(-5))
            .expirationTime(DateTime.now().addSeconds(100))
            .notBefore(DateTime.now().addSeconds(-1))
            .subject("sub")
        let token = jwt.signWith(key)
        try {
            Jwt.pasrse(token, config: ParserConfig()).verifyWith(key)
            @Fail("should throw jwt exception")
        } catch (ex: JwtException) {
            @Assert(ex.message.contains("token is not valid yet"))
        }
    }

    @TestCase
    public func testParseValidateFailNotBefore2() {
        let key = "abcd".toArray()
        let jwt = Jwt.create()
        jwt.alg("HS256")
        jwt
            .claims
            .issuer("cjoy")
            .audience("aud")
            .issuedAt(DateTime.now().addSeconds(-5))
            .expirationTime(DateTime.now().addSeconds(100))
            .subject("sub")
        let token = jwt.signWith(key)
        try {
            Jwt.pasrse(token, config: ParserConfig(notBeforeRequired: true)).verifyWith(key)
            @Fail("should throw jwt exception")
        } catch (ex: JwtException) {
            @Assert(ex.message.contains("missing required claim"))
        }
    }

    @TestCase
    public func testParseValidateSuccessAud1() {
        let key = "abcd".toArray()
        let jwt = createJwt("HS256")
        let token = jwt.signWith(key)
        try {
            Jwt.pasrse(token, config: ParserConfig(expectedAud: ["aud", "aud1"])).verifyWith(key)
        } catch (ex: JwtException) {
            @Fail(ex.message)
        }
    }
    @TestCase
    public func testParseValidateSuccessAud2() {
        let key = "abcd".toArray()
        let jwt = createJwt("HS256")
        let token = jwt.signWith(key)
        try {
            Jwt.pasrse(token, config: ParserConfig(expectedAud: ["aud"], expectedAllAud: true)).verifyWith(key)
        } catch (ex: JwtException) {
            @Fail(ex.message)
        }
    }

    @TestCase
    public func testParseValidateSuccessAud3() {
        let key = "abcd".toArray()
        let jwt = Jwt.create()
        jwt.alg("HS256")
        jwt
            .claims
            .issuer("cjoy")
            .audiences(["aud1", "aud2"])
            .issuedAt(DateTime.now().addSeconds(-5))
            .expirationTime(DateTime.now().addSeconds(100))
            .notBefore(DateTime.now().addSeconds(5))
            .subject("sub")
        let token = jwt.signWith(key)
        try {
            Jwt.pasrse(token, config: ParserConfig(expectedAud: ["aud1", "aud2"], expectedAllAud: true)).verifyWith(key)
        } catch (ex: JwtException) {
            @Fail(ex.message)
        }
    }

    @TestCase
    public func testParseValidateFailAud1() {
        let key = "abcd".toArray()
        let jwt = createJwt("HS256")
        let token = jwt.signWith(key)
        try {
            Jwt.pasrse(token, config: ParserConfig(expectedAud: ["aud1"])).verifyWith(key)
            @Fail("should throw jwt exception")
        } catch (ex: JwtException) {
            @Assert(ex.message.contains("token has invalid audience"))
        }
    }

    @TestCase
    public func testParseValidateFailAud2() {
        let key = "abcd".toArray()
        let jwt = Jwt.create()
        jwt.alg("HS256")
        jwt
            .claims
            .issuer("cjoy")
            .audiences(["aud1", "aud2"])
            .issuedAt(DateTime.now().addSeconds(-5))
            .expirationTime(DateTime.now().addSeconds(100))
            .notBefore(DateTime.now().addSeconds(5))
            .subject("sub")
        let token = jwt.signWith(key)
        try {
            Jwt
                .pasrse(token, config: ParserConfig(expectedAud: ["aud1", "aud2", "aud3"], expectedAllAud: true))
                .verifyWith(key)
            @Fail("should throw jwt exception")
        } catch (ex: JwtException) {
            @Assert(ex.message.contains("token has invalid audience"))
        }
    }

    @TestCase
    public func testParseValidateMethodSuccess() {
        let key = "abcd".toArray()
        let jwt = createJwt("HS256")
        let token = jwt.signWith(key)
        try {
            Jwt.pasrse(token, config: ParserConfig(validMethods: ["HS256", "HS384"])).verifyWith(key)
        } catch (ex: JwtException) {
            @Fail(ex.message)
        }
    }

    @TestCase
    public func testParseValidateMethodFail() {
        let key = "abcd".toArray()
        let jwt = createJwt("HS256")
        let token = jwt.signWith(key)
        try {
            Jwt.pasrse(token, config: ParserConfig(validMethods: ["HS384", "HS512"])).verifyWith(key)
            @Fail("should throw jwt exception")
        } catch (ex: JwtException) {
            @Assert(ex.message.contains("token signature is invalid"))
        }
    }

    private func createJwt(alg: String): Jwt {
        let jwt = Jwt.create()
        jwt.alg(alg)
        jwt.headers.header("h1", "v1")
        jwt
            .claims
            .issuer("cjoy")
            .audience("aud")
            .issuedAt(DateTime.now().addSeconds(-30))
            .expirationTime(DateTime.now().addDays(1))
            .notBefore(DateTime.now().addSeconds(5))
            .subject("sub")
            .claim("c1", "v1")
        jwt
    }

    private func assertJwt(jwt: Jwt): Unit {
        @Assert(jwt.headers.getString("h1").getOrThrow() == "v1")
        @Assert(jwt.claims.getIssuer().getOrThrow() == "cjoy")
        @Assert(jwt.claims.getSubject().getOrThrow() == "sub")
        @Assert(jwt.claims.getAudience().getOrThrow().getFirstValue() == "aud")
        @Assert(jwt.claims.getExpirationTime().isSome())
        @Assert(jwt.claims.getNotBefore().isSome())
        @Assert(jwt.claims.getIssuedAt().isSome())
    }

    @TestCase
    public func testSignRS256() {
        let priv = RSAPrivateKey(2048)
        let pub = RSAPublicKey(priv)
        let jwt = createJwt("RS256")
        let token = jwt.signWith(priv)
        let jwt2 = Jwt.pasrse(token).verifyWith(pub)
        assertJwt(jwt2)
    }

    @TestCase
    public func testSignRS256FromFile() {
        let priv = loadRSAPrivateKey("./testdata/rsa_private.pem")
        let pub = loadRSAPublicKey("./testdata/rsa_public.pem")
        let jwt = createJwt("RS256")
        let token = jwt.signWith(priv)
        let jwt2 = Jwt.pasrse(token).verifyWith(pub)
        assertJwt(jwt2)
    }

    @TestCase
    public func testSignPS256() {
        let priv = RSAPrivateKey(2048)
        let pub = RSAPublicKey(priv)
        let jwt = createJwt("PS256")
        let token = jwt.signWith(priv)
        let jwt2 = Jwt.pasrse(token).verifyWith(pub)
        assertJwt(jwt2)
    }
}
