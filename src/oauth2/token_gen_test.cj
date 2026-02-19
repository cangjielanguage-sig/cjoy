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

import std.time.DateTime
import std.unittest.mock.*
import cjoy.framework.*

@Test
public class SecureRandTokenGenerateTestCaseSuit {
    /**
     * 测试安全随机令牌生成 - 验证生成的访问令牌和刷新令牌不为空
     */
    @TestCase
    public func testGenerate() {
        let data = GenerateBasic(
            client: ClientInfo(id: "123456", secret: "abbcdef"),
            userId: "00009527",
            createAt: DateTime.now(),
            tokenInfo: TokenInfo(),
            request: mock<JoyContext>()
        )
        let (access, refresh) = SecureRandTokenGenerate().generate(data, true)
        @Assert(access != "")
        @Assert(refresh != "")
        println(access)
        println(refresh)
    }

    /**
     * 测试不生成刷新令牌的情况 - 验证当 isGenRefresh 为 false 时不生成刷新令牌
     */
    @TestCase
    public func testGenerateWithoutRefresh() {
        let data = GenerateBasic(
            client: ClientInfo(id: "123456", secret: "abbcdef"),
            userId: "00009527",
            createAt: DateTime.now(),
            tokenInfo: TokenInfo(),
            request: mock<JoyContext>()
        )
        let (access, refresh) = SecureRandTokenGenerate().generate(data, false)
        @Assert(access != "")
        @Assert(refresh, "")
    }

    /**
     * 测试多次生成不同的令牌 - 验证每次生成的令牌都是不同的
     */
    @TestCase
    public func testGenerateDifferentTokens() {
        let data1 = GenerateBasic(
            client: ClientInfo(id: "123456", secret: "abbcdef"),
            userId: "00009527",
            createAt: DateTime.now(),
            tokenInfo: TokenInfo(),
            request: mock<JoyContext>()
        )
        let data2 = GenerateBasic(
            client: ClientInfo(id: "123456", secret: "abbcdef"),
            userId: "00009527",
            createAt: DateTime.now().addSeconds(1),  // 使用不同的时间戳
            tokenInfo: TokenInfo(),
            request: mock<JoyContext>()
        )

        let (access1, refresh1) = SecureRandTokenGenerate().generate(data1, true)
        let (access2, refresh2) = SecureRandTokenGenerate().generate(data2, true)

        @Assert(access1 != access2)
        @Assert(refresh1 != refresh2)
    }
}
