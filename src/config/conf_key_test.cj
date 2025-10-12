/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
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
    public func testTransferKey1() {
        let key = transferKey("abcDef")
        @Assert(key, "abc-def")
    }

    @TestCase
    public func testTransferKey2() {
        let key = transferKey("abcDEf")
        @Assert(key, "abc-def")
    }

    @TestCase
    public func testTransferKey3() {
        let key = transferKey("abcDefG")
        @Assert(key, "abc-def-g")
    }

    @TestCase
    public func testTransferKey4() {
        let key = transferKey("abc-def")
        @Assert(key, "abc-def")
    }
}
