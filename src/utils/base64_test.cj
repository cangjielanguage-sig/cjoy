/*
 * Copyright (c) 2026 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.utils

import std.unittest.testmacro.*

@Test
public class Base64TestCaseSuit {
    /**
     * 测试原始 Base64 URL 编码功能 - 验证字符串编码和解码的正确性
     */
    @TestCase
    public func testRawBase64URLEncode() {
        // 测试普通字符串
        let testStr = "Hello, World!"
        let bs = testStr.toArray()
        let encoded = rawBase64URLEncode(bs)
        @Assert(encoded, "SGVsbG8sIFdvcmxkIQ")

        // 测试解码
        let decoded = rawBase64URLDecode(encoded)
        @Assert(decoded.isSome(), true)
        @Assert(String.fromUtf8(decoded.getOrThrow()), testStr)
    }

    /**
     * 测试原始 Base64 URL 解码功能 - 验证标准和带填充的编码字符串解码
     */
    @TestCase
    public func testRawBase64URLDecode() {
        // 测试标准 base64 URL 编码字符串
        let encoded = "SGVsbG8sIFdvcmxkIQ"
        let decoded = rawBase64URLDecode(encoded)
        @Assert(decoded.isSome(), true)
        @Assert(String.fromUtf8(decoded.getOrThrow()), "Hello, World!")

        // 测试带填充的字符串
        let encodedWithPadding = "SGVsbG8sIFdvcmxkIQ=="
        let decodedWithPadding = rawBase64URLDecode(encodedWithPadding)
        @Assert(decodedWithPadding.isSome(), true)
        @Assert(String.fromUtf8(decodedWithPadding.getOrThrow()), "Hello, World!")
    }

    /**
     * 测试解码无效的 Base64 URL 编码字符串 - 验证无效编码会正确处理
     */
    @TestCase
    @Skip
    public func testRawBase64URLDecodeInvalid() {
        // 测试无效的 base64 字符串
        let invalidEncoded = "InvalidBase64String"
        let decoded = rawBase64URLDecode(invalidEncoded)
        @Assert(decoded.isSome(), true)
        @Assert(decoded.getOrThrow().size, 0)
    }

    /**
     * 测试 Base64 URL 编码解码往返 - 验证多种类型数据的编码解码一致性
     */
    @TestCase
    public func testEncodeDecodeRoundTrip() {
        // 测试编码解码往返
        let testData = [
            "test",
            "12345",
            "!@#$%^&*()",
            "",
            "你好，世界！"
        ]

        for (data in testData) {
            let bs = data.toArray()
            let encoded = rawBase64URLEncode(bs)
            let decoded = rawBase64URLDecode(encoded)
            @Assert(decoded.isSome(), true)
            @Assert(String.fromUtf8(decoded.getOrThrow()), data)
        }
    }
}
