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
    @TestCase
    public func testconvertKey1() {
        let key = convertKey("abcDef")
        @Assert(key, "abc-def")
    }

    @TestCase
    public func testconvertKey2() {
        let key = convertKey("abcDEf")
        @Assert(key, "abc-def")
    }

    @TestCase
    public func testconvertKey3() {
        let key = convertKey("abcDefG")
        @Assert(key, "abc-def-g")
    }

    @TestCase
    public func testconvertKey4() {
        let key = convertKey("abc-def")
        @Assert(key, "abc-def")
    }

    @TestCase
    public func testconvertKey5() {
        let key = convertKey("AbcDEf-g")
        @Assert(key, "abc-def-g")
    }
}
