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

@Test
public class JwtTestCaseSuit {
    @TestCase
    public func testSignHS256() {
        let jwt = Jwt.create()
        jwt.alg("HS256")
        jwt.headers.header("h1", "v1")
        jwt.claims
            .issuer("cjoy")
            .audience("aud")
            .issuedAt(DateTime.now())
            .expirationTime(DateTime.now().addDays(1))
            .notBefore(DateTime.now())
            .subject("sub")
            .claim("c1", "v1")
        let token = jwt.signWith("abcd".toArray())
        let jwt2 = Jwt.pasrse(token).verifyWith("abcd".toArray())
        @Assert(jwt2.headers.getString("h1").getOrThrow() == "v1")
        @Assert(jwt2.claims.getIssuer().getOrThrow() == "cjoy")
        @Assert(jwt2.claims.getSubject().getOrThrow() == "sub")
        @Assert(jwt2.claims.getAudience().getOrThrow().getFirstValue() == "aud")
        @Assert(jwt2.claims.getExpirationTime().isSome())
        @Assert(jwt2.claims.getNotBefore().isSome())
        @Assert(jwt2.claims.getIssuedAt().isSome())
    }
}
