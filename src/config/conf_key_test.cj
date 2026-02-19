/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.config

@Test
public class ConfigKeyTestCaseSuit {
    /**
     * 测试键名转换1 - 验证骆驼命名法到连字符命名法的转换（abcDef → abc-def）
     */
    @TestCase
    public func testconvertKey1() {
        let key = convertKey("abcDef")
        @Assert(key, "abc-def")
    }

    /**
     * 测试键名转换2 - 验证包含多个大写字母的键名转换（abcDEf → abc-def）
     */
    @TestCase
    public func testconvertKey2() {
        let key = convertKey("abcDEf")
        @Assert(key, "abc-def")
    }

    /**
     * 测试键名转换3 - 验证更长的骆驼命名法键名转换（abcDefG → abc-def-g）
     */
    @TestCase
    public func testconvertKey3() {
        let key = convertKey("abcDefG")
        @Assert(key, "abc-def-g")
    }

    /**
     * 测试键名转换4 - 验证已包含连字符的键名不被修改
     */
    @TestCase
    public func testconvertKey4() {
        let key = convertKey("abc-def")
        @Assert(key, "abc-def")
    }

    /**
     * 测试键名转换5 - 验证混合格式的键名转换（AbcDEf-g → abc-def-g）
     */
    @TestCase
    public func testconvertKey5() {
        let key = convertKey("AbcDEf-g")
        @Assert(key, "abc-def-g")
    }
}
