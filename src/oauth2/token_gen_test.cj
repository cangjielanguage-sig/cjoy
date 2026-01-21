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
}
