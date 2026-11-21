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
import stdx.crypto.keys.{RSAPrivateKey, RSAPublicKey}

@Test
public class JwtTestCaseSuit {
    /**
     * 测试 HS256 签名算法 - 使用 HS256 算法签名并验证 JWT
     */
    @TestCase
    public func testSignHS256() {
        let key = "abcd".toArray()
        let jwt = createJwt("HS256")
        let token = jwt.signWith(key)
        let jwt2 = Jwt.parse(token).verifyWith(key)
        assertJwt(jwt2)
    }

    /**
     * 测试 HS384 签名算法 - 使用 HS384 算法签名并验证 JWT
     */
    @TestCase
    public func testSignHS384() {
        let key = "abcd".toArray()
        let jwt = createJwt("HS384")
        let token = jwt.signWith(key)
        let jwt2 = Jwt.parse(token).verifyWith(key)
        assertJwt(jwt2)
    }

    /**
     * 测试 HS512 签名算法 - 使用 HS512 算法签名并验证 JWT
     */
    @TestCase
    public func testSignHS512() {
        let key = "abcd".toArray()
        let jwt = createJwt("HS512")
        let token = jwt.signWith(key)
        let jwt2 = Jwt.parse(token).verifyWith(key)
        assertJwt(jwt2)
    }

    /**
     * 测试跳过声明验证 - 当设置 skipClaimsValidation 为 true 时，即使声明无效也会通过验证
     */
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
            .notBefore(DateTime.now().addSeconds(-5))
            .subject("sub")
        let token = jwt.signWith(key)
        try {
            Jwt.parse(token, config: ParserConfig(skipClaimsValidation: true)).verifyWith(key)
        } catch (ex: JwtException) {
            @Fail(ex.message)
        }
    }

    /**
     * 测试 issuedAt 声明验证失败 - 当 issuedAt 是未来时间时验证失败
     */
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
            .notBefore(DateTime.now().addSeconds(-5))
            .subject("sub")
        let token = jwt.signWith(key)
        try {
            Jwt.parse(token, config: ParserConfig()).verifyWith(key)
            @Fail("should throw jwt exception")
        } catch (ex: JwtException) {
            @Assert(ex.message.contains("before issued"))
        }
    }

    /**
     * 测试缺少 issuedAt 声明验证失败 - 当设置 issueAtRequired 为 true 但缺少该声明时验证失败
     */
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
            .notBefore(DateTime.now().addSeconds(-3))
            .subject("sub")
        let token = jwt.signWith(key)
        try {
            Jwt.parse(token, config: ParserConfig(issueAtRequired: true)).verifyWith(key)
            @Fail("should throw jwt exception")
        } catch (ex: JwtException) {
            @Assert(ex.message.contains("missing required claim"))
        }
    }

    /**
     * 测试过期时间验证失败 - 当 token 已过期时验证失败
     */
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
            .notBefore(DateTime.now().addSeconds(-3))
            .subject("sub")
        let token = jwt.signWith(key)
        try {
            Jwt.parse(token, config: ParserConfig()).verifyWith(key)
            @Fail("should throw jwt exception")
        } catch (ex: JwtException) {
            @Assert(ex.message.contains("token is expired"))
        }
    }

    /**
     * 测试缺少过期时间验证失败 - 当设置 expirationRequired 为 true 但缺少该声明时验证失败
     */
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
            .notBefore(DateTime.now().addSeconds(-3))
            .subject("sub")
        let token = jwt.signWith(key)
        try {
            Jwt.parse(token, config: ParserConfig(expirationRequired: true)).verifyWith(key)
            @Fail("should throw jwt exception")
        } catch (ex: JwtException) {
            @Assert(ex.message.contains("missing required claim"))
        }
    }

    /**
     * 测试 notBefore 声明验证失败 - 当 token 尚未到生效时间时验证失败
     */
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
            .notBefore(DateTime.now().addSeconds(1))
            .subject("sub")
        let token = jwt.signWith(key)
        try {
            Jwt.parse(token, config: ParserConfig()).verifyWith(key)
            @Fail("should throw jwt exception")
        } catch (ex: JwtException) {
            @Assert(ex.message.contains("token is not valid yet"))
        }
    }

    /**
     * 测试缺少 notBefore 声明验证失败 - 当设置 notBeforeRequired 为 true 但缺少该声明时验证失败
     */
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
            Jwt.parse(token, config: ParserConfig(notBeforeRequired: true)).verifyWith(key)
            @Fail("should throw jwt exception")
        } catch (ex: JwtException) {
            @Assert(ex.message.contains("missing required claim"))
        }
    }

    /**
     * 测试受众验证成功 - 当 token 受众包含在预期受众列表中时验证成功
     */
    @TestCase
    public func testParseValidateSuccessAud1() {
        let key = "abcd".toArray()
        let jwt = createJwt("HS256")
        let token = jwt.signWith(key)
        try {
            Jwt.parse(token, config: ParserConfig(expectedAud: ["aud", "aud1"])).verifyWith(key)
        } catch (ex: JwtException) {
            @Fail(ex.message)
        }
    }
    /**
     * 测试受众验证成功 - 当 token 受众与预期受众完全匹配时验证成功
     */
    @TestCase
    public func testParseValidateSuccessAud2() {
        let key = "abcd".toArray()
        let jwt = createJwt("HS256")
        let token = jwt.signWith(key)
        try {
            Jwt.parse(token, config: ParserConfig(expectedAud: ["aud"], expectedAllAud: true)).verifyWith(key)
        } catch (ex: JwtException) {
            @Fail(ex.message)
        }
    }

    /**
     * 测试多受众验证成功 - 当 token 包含多个受众且与预期受众完全匹配时验证成功
     */
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
            .notBefore(DateTime.now().addSeconds(-3))
            .subject("sub")
        let token = jwt.signWith(key)
        try {
            Jwt.parse(token, config: ParserConfig(expectedAud: ["aud1", "aud2"], expectedAllAud: true)).verifyWith(key)
        } catch (ex: JwtException) {
            @Fail(ex.message)
        }
    }

    /**
     * 测试受众验证失败 - 当 token 受众不在预期受众列表中时验证失败
     */
    @TestCase
    public func testParseValidateFailAud1() {
        let key = "abcd".toArray()
        let jwt = createJwt("HS256")
        let token = jwt.signWith(key)
        try {
            Jwt.parse(token, config: ParserConfig(expectedAud: ["aud1"])).verifyWith(key)
            @Fail("should throw jwt exception")
        } catch (ex: JwtException) {
            @Assert(ex.message.contains("token has invalid audience"))
        }
    }

    /**
     * 测试多受众验证失败 - 当 token 受众与预期受众不完全匹配时验证失败
     */
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
            .notBefore(DateTime.now().addSeconds(-3))
            .subject("sub")
        let token = jwt.signWith(key)
        try {
            Jwt
                .parse(token, config: ParserConfig(expectedAud: ["aud1", "aud2", "aud3"], expectedAllAud: true))
                .verifyWith(key)
            @Fail("should throw jwt exception")
        } catch (ex: JwtException) {
            @Assert(ex.message.contains("token has invalid audience"))
        }
    }

    /**
     * 测试签名方法验证成功 - 当 token 签名方法在允许的方法列表中时验证成功
     */
    @TestCase
    public func testParseValidateMethodSuccess() {
        let key = "abcd".toArray()
        let jwt = createJwt("HS256")
        let token = jwt.signWith(key)
        try {
            Jwt.parse(token, config: ParserConfig(validMethods: ["HS256", "HS384"])).verifyWith(key)
        } catch (ex: JwtException) {
            @Fail(ex.message)
        }
    }

    /**
     * 测试签名方法验证失败 - 当 token 签名方法不在允许的方法列表中时验证失败
     */
    @TestCase
    public func testParseValidateMethodFail() {
        let key = "abcd".toArray()
        let jwt = createJwt("HS256")
        let token = jwt.signWith(key)
        try {
            Jwt.parse(token, config: ParserConfig(validMethods: ["HS384", "HS512"])).verifyWith(key)
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
            .notBefore(DateTime.now().addSeconds(-3))
            .subject("sub")
            .claim("c1", "v1")
            .claim("c2", ["v2_1", "v2_2"])
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
        @Assert(jwt.claims.getClaimString("c1").getOrThrow() == "v1")
        @Assert(jwt.claims.getClaimStrings("c2").getOrThrow().claims == ["v2_1", "v2_2"])
    }

    /**
     * 测试 RS256 签名算法 - 使用 RS256 算法签名并验证 JWT
     */
    @TestCase
    public func testSignRS256() {
        let priv = RSAPrivateKey(2048)
        let pub = RSAPublicKey(priv)
        let jwt = createJwt("RS256")
        let token = jwt.signWith(priv)
        let jwt2 = Jwt.parse(token).verifyWith(pub)
        assertJwt(jwt2)
    }

    /**
     * 测试 RS256 签名算法 - 从文件加载 RSA 密钥并使用 RS256 算法签名验证 JWT
     */
    @TestCase
    public func testSignRS256FromFile() {
        let priv = loadRSAPrivateKey("./testdata/rsa_private.pem")
        let pub = loadRSAPublicKey("./testdata/rsa_public.pem")
        let jwt = createJwt("RS256")
        let token = jwt.signWith(priv)
        let jwt2 = Jwt.parse(token).verifyWith(pub)
        assertJwt(jwt2)
    }

    /**
     * 测试 PS256 签名算法 - 使用 PS256 算法签名并验证 JWT
     */
    @TestCase
    public func testSignPS256() {
        let priv = RSAPrivateKey(2048)
        let pub = RSAPublicKey(priv)
        let jwt = createJwt("PS256")
        let token = jwt.signWith(priv)
        let jwt2 = Jwt.parse(token).verifyWith(pub)
        assertJwt(jwt2)
    }

    /**
     * 测试 RS384 签名算法 - 使用 RS384 算法签名并验证 JWT
     */
    @TestCase
    public func testSignRS384() {
        let priv = RSAPrivateKey(2048)
        let pub = RSAPublicKey(priv)
        let jwt = createJwt("RS384")
        let token = jwt.signWith(priv)
        let jwt2 = Jwt.parse(token).verifyWith(pub)
        assertJwt(jwt2)
    }

    /**
     * 测试 RS512 签名算法 - 使用 RS512 算法签名并验证 JWT
     */
    @TestCase
    public func testSignRS512() {
        let priv = RSAPrivateKey(2048)
        let pub = RSAPublicKey(priv)
        let jwt = createJwt("RS512")
        let token = jwt.signWith(priv)
        let jwt2 = Jwt.parse(token).verifyWith(pub)
        assertJwt(jwt2)
    }

    /**
     * 测试 PS384 签名算法 - 使用 PS384 算法签名并验证 JWT
     */
    @TestCase
    public func testSignPS384() {
        let priv = RSAPrivateKey(2048)
        let pub = RSAPublicKey(priv)
        let jwt = createJwt("PS384")
        let token = jwt.signWith(priv)
        let jwt2 = Jwt.parse(token).verifyWith(pub)
        assertJwt(jwt2)
    }

    /**
     * 测试 PS512 签名算法 - 使用 PS512 算法签名并验证 JWT
     */
    @TestCase
    public func testSignPS512() {
        let priv = RSAPrivateKey(2048)
        let pub = RSAPublicKey(priv)
        let jwt = createJwt("PS512")
        let token = jwt.signWith(priv)
        let jwt2 = Jwt.parse(token).verifyWith(pub)
        assertJwt(jwt2)
    }

    /**
     * 测试解析无效格式的 token - 当 token 格式不符合 JWT 标准时抛出异常
     */
    @TestCase
    public func testParseInvalidTokenFormat() {
        try {
            Jwt.parse("invalid.token.format")
            @Fail("should throw jwt exception for invalid token format")
        } catch (ex: JwtException) {
            @Assert(ex.message.contains("token is malformed"))
        }
    }

    /**
     * 测试解析无效 Base64 编码的 token - 当 token 包含无效的 Base64 编码时抛出异常
     */
    @TestCase
    public func testParseInvalidBase64() {
        try {
            Jwt.parse("invalidbase64.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.invalidbase64")
            @Fail("should throw jwt exception for invalid base64")
        } catch (ex: JwtException) {
            @Assert(ex.message.contains("could not base64 decode"))
        }

        try {
            Jwt.parse("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.bm90IGpzb24.invalidbase64")
            @Fail("should throw jwt exception for invalid json")
        } catch (ex: JwtException) {
            @Assert(ex.message.contains("could not JSON decode"))
        }
    }

    /**
     * 测试解析包含未知算法的 token - 当 token 包含不支持的签名算法时抛出异常
     */
    @TestCase
    public func testParseUnknownAlgorithm() {
        // 直接创建一个包含未知算法的 token 字符串，而不使用 Jwt 类的方法
        // 这样可以避免调用 signWith() 时的 alg 检查
        let token = "eyJhbGciOiJVTktOT1dOIiwidHlwIjoiSldUIn0.eyJpc3MiOiJjYW5nZSIsImF1ZCI6ImF1ZCIsImlhdCI6MTczNjk5ODAwMCwiZXhwIjoxNzM3MDg0NDAwLCJuYmYiOjE3MzY5OTc5OTcsInN1YiI6InN1YiJ9.invalid signature"
        try {
            Jwt.parse(token)
            @Fail("should throw jwt exception for unknown algorithm")
        } catch (ex: JwtException) {
            @Assert(ex.message.contains("signing method (alg) is unavailable"))
        }
    }

    /**
     * 测试过期时间宽容期 - 当 token 过期时间在宽容期内时验证成功
     */
    @TestCase
    public func testLeewayExpiration() {
        let key = "abcd".toArray()
        let jwt = Jwt.create()
        jwt.alg("HS256")
        jwt
            .claims
            .issuer("cjoy")
            .audience("aud")
            .issuedAt(DateTime.now().addSeconds(-5))
            .expirationTime(DateTime.now().addSeconds(-1))
            .notBefore(DateTime.now().addSeconds(-3))
            .subject("sub")
        let token = jwt.signWith(key)
        try {
            Jwt.parse(token, config: ParserConfig(leeway: Duration.second * 2)).verifyWith(key)
        } catch (ex: JwtException) {
            @Fail(ex.message)
        }
    }

    /**
     * 测试生效时间宽容期 - 当 token 生效时间在宽容期内时验证成功
     */
    @TestCase
    public func testLeewayNotBefore() {
        let key = "abcd".toArray()
        let jwt = Jwt.create()
        jwt.alg("HS256")
        jwt
            .claims
            .issuer("cjoy")
            .audience("aud")
            .issuedAt(DateTime.now().addSeconds(-5))
            .expirationTime(DateTime.now().addSeconds(100))
            .notBefore(DateTime.now().addSeconds(1))
            .subject("sub")
        let token = jwt.signWith(key)
        try {
            Jwt.parse(token, config: ParserConfig(leeway: Duration.second * 2)).verifyWith(key)
        } catch (ex: JwtException) {
            @Fail(ex.message)
        }
    }

    /**
     * 测试签发时间宽容期 - 当 token 签发时间在宽容期内时验证成功
     */
    @TestCase
    public func testLeewayIssuedAt() {
        let key = "abcd".toArray()
        let jwt = Jwt.create()
        jwt.alg("HS256")
        jwt
            .claims
            .issuer("cjoy")
            .audience("aud")
            .issuedAt(DateTime.now().addSeconds(1))
            .expirationTime(DateTime.now().addDays(1))
            .notBefore(DateTime.now().addSeconds(-3))
            .subject("sub")
        let token = jwt.signWith(key)
        try {
            Jwt.parse(token, config: ParserConfig(leeway: Duration.second * 2)).verifyWith(key)
        } catch (ex: JwtException) {
            @Fail(ex.message)
        }
    }

    /**
     * 测试自定义时间函数 - 使用自定义时间函数验证 token 的过期状态
     */
    @TestCase
    public func testCustomTimeFunc() {
        let key = "abcd".toArray()
        let jwt = Jwt.create()
        jwt.alg("HS256")
        jwt
            .claims
            .issuer("cjoy")
            .audience("aud")
            .issuedAt(DateTime.now().addSeconds(-30))
            .expirationTime(DateTime.now().addDays(1))
            .notBefore(DateTime.now().addSeconds(-3))
            .subject("sub")
        let token = jwt.signWith(key)

        let customTime = DateTime.now().addDays(2)
        try {
            Jwt.parse(token, config: ParserConfig(timeFunc: {=> customTime})).verifyWith(key)
            @Fail("should throw jwt exception for expired token with custom time")
        } catch (ex: JwtException) {
            @Assert(ex.message.contains("token is expired"))
        }
    }

    /**
     * 测试签发者验证成功 - 当 token 签发者与预期值匹配时验证成功
     */
    @TestCase
    public func testParseValidateSuccessIssuer() {
        let key = "abcd".toArray()
        let jwt = createJwt("HS256")
        let token = jwt.signWith(key)
        try {
            Jwt.parse(token, config: ParserConfig(expectedIss: "cjoy")).verifyWith(key)
        } catch (ex: JwtException) {
            @Fail(ex.message)
        }
    }

    /**
     * 测试签发者验证失败 - 当 token 签发者与预期值不匹配时验证失败
     */
    @TestCase
    public func testParseValidateFailIssuer() {
        let key = "abcd".toArray()
        let jwt = createJwt("HS256")
        let token = jwt.signWith(key)
        try {
            Jwt.parse(token, config: ParserConfig(expectedIss: "invalid")).verifyWith(key)
            @Fail("should throw jwt exception for invalid issuer")
        } catch (ex: JwtException) {
            @Assert(ex.message.contains("token has invalid issuer"))
        }
    }

    /**
     * 测试主题验证成功 - 当 token 主题与预期值匹配时验证成功
     */
    @TestCase
    public func testParseValidateSuccessSubject() {
        let key = "abcd".toArray()
        let jwt = createJwt("HS256")
        let token = jwt.signWith(key)
        try {
            Jwt.parse(token, config: ParserConfig(expectedSub: "sub")).verifyWith(key)
        } catch (ex: JwtException) {
            @Fail(ex.message)
        }
    }

    /**
     * 测试主题验证失败 - 当 token 主题与预期值不匹配时验证失败
     */
    @TestCase
    public func testParseValidateFailSubject() {
        let key = "abcd".toArray()
        let jwt = createJwt("HS256")
        let token = jwt.signWith(key)
        try {
            Jwt.parse(token, config: ParserConfig(expectedSub: "invalid")).verifyWith(key)
            @Fail("should throw jwt exception for invalid subject")
        } catch (ex: JwtException) {
            @Assert(ex.message.contains("token has invalid subject"))
        }
    }

    /**
     * 测试复制声明 - 验证将一个 JWT 的声明复制到另一个 JWT 的功能
     */
    @TestCase
    public func testCopyClaims() {
        let key = "abcd".toArray()
        let jwt1 = createJwt("HS256")
        let jwt2 = Jwt.create()
        jwt2.copyClaims(jwt1)

        @Assert(jwt2.claims.getIssuer().getOrThrow() == jwt1.claims.getIssuer().getOrThrow())
        @Assert(jwt2.claims.getSubject().getOrThrow() == jwt1.claims.getSubject().getOrThrow())
        @Assert(jwt2.claims.getAudience().getOrThrow().getFirstValue() == jwt1.claims.getAudience().getOrThrow().getFirstValue())
    }

    /**
     * 测试自定义头部 - 验证 JWT 自定义头部的设置和解析功能
     */
    @TestCase
    public func testCustomHeaders() {
        let key = "abcd".toArray()
        let jwt = Jwt.create()
        jwt.alg("HS256")
        jwt.headers.header("customHeader", "customValue")
        jwt.claims.issuer("cjoy")
        let token = jwt.signWith(key)

        let parsed = Jwt.parse(token).verifyWith(key)
        @Assert(parsed.headers.getString("customHeader").getOrThrow() == "customValue")
        @Assert(parsed.headers.getValue<String>("customHeader").getOrThrow() == "customValue")
    }

    /**
     * 测试 exp 边界 - 验证 now == exp 时 token 已过期
     */
    @TestCase
    public func testExpirationBoundary() {
        let key = "abcd".toArray()
        let exp = DateTime.now().addSeconds(10)
        let jwt = Jwt.create()
        jwt.alg("HS256")
        jwt.claims.expirationTime(exp)
        let token = jwt.signWith(key)

        try {
            Jwt.parse(token, config: ParserConfig(timeFunc: {=> exp})).verifyWith(key)
            @Fail("token should be expired when now equals exp")
        } catch (ex: JwtException) {
            @Assert(ex.message.contains("token is expired"))
        }
    }

    /**
     * 测试非 base64url 字符 - 验证标准 base64 的 + / 不被接受
     */
    @TestCase
    public func testRejectNonBase64UrlSegment() {
        let jwt = Jwt.create()
        jwt.alg("HS256")
        let token = jwt.signWith("abcd".toArray())
        let segs = token.split(".")
        let badToken = "+" + segs[0][1..] + "." + segs[1] + "." + segs[2]
        try {
            Jwt.parse(badToken)
            @Fail("should reject non base64url header segment")
        } catch (ex: JwtException) {
            @Assert(ex.message.contains("could not base64 decode"))
        }
    }
}
