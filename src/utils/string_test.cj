/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
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
public class StringTestCaseSuit {
    /**
     * 测试字符串切割功能 - 验证 cut 方法在各种边界条件下的行为
     */
    @TestCase
    public func testCut() {
        // 测试正常切割
        let str = "Hello,World!"
        let (left, right, found) = str.cut(b',')
        @Assert(left, "Hello")
        @Assert(right, "World!")
        @Assert(found, true)

        // 测试未找到分隔符
        let (left2, right2, found2) = str.cut(b';')
        @Assert(left2, str)
        @Assert(right2, "")
        @Assert(found2, false)

        // 测试分隔符在开头
        let str2 = ",HelloWorld"
        let (left3, right3, found3) = str2.cut(b',')
        @Assert(left3, "")
        @Assert(right3, "HelloWorld")
        @Assert(found3, true)

        // 测试分隔符在结尾
        let str3 = "HelloWorld,"
        let (left4, right4, found4) = str3.cut(b',')
        @Assert(left4, "HelloWorld")
        @Assert(right4, "")
        @Assert(found4, true)
    }

    /**
     * 测试字符串索引查找功能 - 验证 indexFunc 方法根据条件查找字符位置
     */
    @TestCase
    public func testIndexFunc() {
        let str = "Hello,World!"

        // 测试查找数字
        let digitIndex = str.indexFunc({b => b >= b'0' && b <= b'9'})
        @Assert(digitIndex, -1)

        // 测试查找大写字母
        let upperIndex = str.indexFunc({b => b >= b'A' && b <= b'Z'})
        @Assert(upperIndex, 0)

        // 测试查找小写字母
        let lowerIndex = str.indexFunc({b => b >= b'a' && b <= b'z'})
        @Assert(lowerIndex, 1)

        // 测试查找逗号
        let commaIndex = str.indexFunc({b => b == b','})
        @Assert(commaIndex, 5)
    }

    /**
     * 测试字符是否为十六进制字符 - 验证 ishex 方法的正确性
     */
    @TestCase
    public func testIsHex() {
        // 测试数字
        for (c in b'0'..b'9') {
            @Assert(ishex(c), true)
        }

        // 测试小写字母
        for (c in b'a'..b'f') {
            @Assert(ishex(c), true)
        }

        // 测试大写字母
        for (c in b'A'..b'F') {
            @Assert(ishex(c), true)
        }

        // 测试无效字符
        @Assert(ishex(b'g'), false)
        @Assert(ishex(b'G'), false)
        @Assert(ishex(b' '), false)
        @Assert(ishex(b'\t'), false)
    }

    /**
     * 测试十六进制字符转换为整数 - 验证 unhex 方法的转换功能
     */
    @TestCase
    public func testUnhex() {
        @Assert(unhex(b'0'), 0)
        @Assert(unhex(b'9'), 9)
        @Assert(unhex(b'a'), 10)
        @Assert(unhex(b'f'), 15)
        @Assert(unhex(b'A'), 10)
        @Assert(unhex(b'F'), 15)
        @Assert(unhex(b'g'), 0)
        @Assert(unhex(b'G'), 0)
    }

    /**
     * 测试驼峰式命名转换为蛇形命名 - 验证 snakeCase 方法的转换功能
     */
    @TestCase
    public func testSnakeCase() {
        @Assert(snakeCase("HelloWorld"), "hello-world")
        @Assert(snakeCase("helloWOrld"), "hello-world")
        @Assert(snakeCase("HelloWorldTest"), "hello-world-test")
        @Assert(snakeCase("HELLoWorld"), "hello-world")
        @Assert(snakeCase("Hello"), "hello")
        @Assert(snakeCase("aB"), "a-b")
        @Assert(snakeCase(""), "")
    }

    /**
     * 测试字符是否为 ASCII 空格 - 验证 isASCIISpace 方法的判断
     */
    @TestCase
    public func testIsASCIISpace() {
        @Assert(isASCIISpace(b' '), true)
        @Assert(isASCIISpace(b'\t'), true)
        @Assert(isASCIISpace(b'\n'), true)
        @Assert(isASCIISpace(b'\r'), true)
        @Assert(isASCIISpace(b'a'), false)
        @Assert(isASCIISpace(b'0'), false)
        @Assert(isASCIISpace(b'\0'), false)
    }

    /**
     * 测试字符是否为 ASCII 字母 - 验证 isASCIILetter 方法的判断
     */
    @TestCase
    public func testIsASCIILetter() {
        // 测试小写字母
        for (c in b'a'..b'z') {
            @Assert(isASCIILetter(c), true)
        }

        // 测试大写字母
        for (c in b'A'..b'Z') {
            @Assert(isASCIILetter(c), true)
        }

        // 测试其他字符
        @Assert(isASCIILetter(b'0'), false)
        @Assert(isASCIILetter(b' '), false)
        @Assert(isASCIILetter(b'\t'), false)
        @Assert(isASCIILetter(b'!'), false)
    }

    /**
     * 测试字节数组修剪功能 - 验证 trimBytes 方法去除首尾空白字符
     */
    @TestCase
    public func testTrimBytes() {
        let bs1 = "  Hello World!  ".toArray()
        let trimmed1 = trimBytes(bs1)
        @Assert(String.fromUtf8(trimmed1), "Hello World!")

        let bs2 = "\t\nHello\tWorld\n\r".toArray()
        let trimmed2 = trimBytes(bs2)
        @Assert(String.fromUtf8(trimmed2), "Hello\tWorld")

        let bs3 = "HelloWorld".toArray()
        let trimmed3 = trimBytes(bs3)
        @Assert(String.fromUtf8(trimmed3), "HelloWorld")

        let bs4 = "   ".toArray()
        let trimmed4 = trimBytes(bs4)
        @Assert(trimmed4.size, 0)

        let bs5 = "".toArray()
        let trimmed5 = trimBytes(bs5)
        @Assert(trimmed5.size, 0)
    }

    /**
     * 测试字符串修剪功能 - 验证 trimString 方法去除首尾空白字符
     */
    @TestCase
    public func testTrimString() {
        @Assert(trimString("  Hello World!  "), "Hello World!")
        @Assert(trimString("\t\nHello\tWorld\n\r"), "Hello\tWorld")
        @Assert(trimString("HelloWorld"), "HelloWorld")
        @Assert(trimString("   "), "")
        @Assert(trimString(""), "")
    }
}
