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
import std.collection.HashSet

@Test
public class RandTestCaseSuit {
    @TestCase
    public func testRandStrLength() {
        // 测试生成指定长度的随机字符串
        let lengths = [1, 5, 10, 20, 100]
        for (len in lengths) {
            let str = randStr(Int32(len))
            @Assert(str.size, len * 2) // 每个字节转换为2个十六进制字符
        }
    }

    @TestCase
    public func testSecureRandStrLength() {
        // 测试生成指定长度的安全随机字符串
        let lengths = [1, 5, 10, 20, 100]
        for (len in lengths) {
            let str = secureRandStr(Int32(len))
            @Assert(str.size, len * 2) // 每个字节转换为2个十六进制字符
        }
    }

    @TestCase
    public func testRandStrUniqueness() {
        // 测试生成的随机字符串是否唯一
        let seen = HashSet<String>()
        let count = 1000
        let length = 10

        for (_ in 1..count) {
            let str = randStr(Int32(length))
            @Assert(seen.contains(str), false)
            seen.add(str)
        }
    }

    @TestCase
    public func testSecureRandStrUniqueness() {
        // 测试生成的安全随机字符串是否唯一
        let seen = HashSet<String>()
        let count = 1000
        let length = 10

        for (_ in 1..count) {
            let str = secureRandStr(Int32(length))
            @Assert(seen.contains(str), false)
            seen.add(str)
        }
    }

    @TestCase
    public func testRandStrFormat() {
        // 测试生成的字符串是否只包含十六进制字符
        let length: Int32 = 20
        let str = randStr(length)

        for (c in str.toArray()) {
            let lowerC = c.toAsciiLowerCase()
            let isHex = (lowerC >= b'0' && lowerC <= b'9') || (lowerC >= b'a' && lowerC <= b'f')
            @Assert(isHex, true)
        }
    }

    @TestCase
    public func testSecureRandStrFormat() {
        // 测试生成的安全随机字符串是否只包含十六进制字符
        let length: Int32 = 20
        let str = secureRandStr(length)

        for (c in str.toArray()) {
            let lowerC = c.toAsciiLowerCase()
            let isHex = (lowerC >= b'0' && lowerC <= b'9') || (lowerC >= b'a' && lowerC <= b'f')
            @Assert(isHex, true)
        }
    }
}
