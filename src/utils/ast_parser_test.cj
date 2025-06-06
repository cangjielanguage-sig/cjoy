/*
 * Copyright (c) lanlingx 2025-present. All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.utils

import std.ast.*
import std.collection.*
import stdx.encoding.json.stream.JsonSerializable
import std.unittest.*
import std.unittest.testmacro.*

@Test
public class TokenParserTestCaseSuit {
    @TestCase
    public func testAttr() {
        let tokens = quote(a:1,b:xyz,c:true)
        let visitor = TokenStrValueVisitor()
        let parser = TokenParser(visitor, tokens)
        let resust = (parser.parse() as HashMap<String, ToString>).getOrThrow()
        @Assert((resust.get("a") as Int64).getOrThrow(), 1)
        @Assert((resust.get("b") as String).getOrThrow(), "xyz")
        @Assert((resust.get("c") as Bool).getOrThrow(), true)
    }

    @TestCase
    public func testArray1() {
        let tokens = quote([a, b, c])
        let visitor = TokenStrValueVisitor()
        let parser = TokenParser(visitor, tokens)
        let resust = (parser.parse() as ArrayList<ToString>).getOrThrow()
        @Assert((resust[0] as String).getOrThrow(), "a")
        @Assert((resust[1] as String).getOrThrow(), "b")
        @Assert((resust[2] as String).getOrThrow(), "c")
    }

    @TestCase
    public func testArray2() {
        let tokens = quote([1, 2, 3])
        let visitor = TokenStrValueVisitor()
        let parser = TokenParser(visitor, tokens)
        let resust = (parser.parse() as ArrayList<ToString>).getOrThrow()
        @Assert((resust[0] as Int64).getOrThrow(), 1)
        @Assert((resust[1] as Int64).getOrThrow(), 2)
        @Assert((resust[2] as Int64).getOrThrow(), 3)
    }
}
