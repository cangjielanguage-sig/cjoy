/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.utils.ast

import std.ast.*
import std.unittest.testmacro.*
import cjoy.utils.{ListToString, MapListGetFunc, MapToString}

@Test
public class TokenParserTestCaseSuit {
    /**
     * 测试属性解析 - 验证基本属性字符串的解析
     */
    @TestCase
    public func testAttr() {
        let tokens = quote( a:1 , b: xyz , c: true )
        let visitor = TokenStrValueVisitor()
        let parser = TokenParser(visitor, tokens)
        let resust = (parser.parse() as MapToString).getOrThrow()
        println(resust)
        @Assert(resust.getInt("a").getOrThrow(), 1)
        @Assert(resust.getString("b").getOrThrow(), "xyz")
        @Assert(resust.getBool("c").getOrThrow(), true)
    }

    /**
     * 测试属性解析（紧凑格式）- 验证无空格的属性字符串解析
     */
    @TestCase
    public func testAttr2() {
        let tokens = quote(a:1,b:xyz,c:true)
        let visitor = TokenStrValueVisitor()
        let parser = TokenParser(visitor, tokens)
        let resust = (parser.parse() as MapToString).getOrThrow()
        println(resust)
        @Assert(resust.getInt("a").getOrThrow(), 1)
        @Assert(resust.getString("b").getOrThrow(), "xyz")
        @Assert(resust.getBool("c").getOrThrow(), true)
    }

    /**
     * 测试属性解析（多行格式）- 验证换行分隔的属性字符串解析
     */
    @TestCase
    public func testAttr3() {
        let tokens = quote(
            a:1,
            b:xyz,
            c:true
        )
        let visitor = TokenStrValueVisitor()
        let parser = TokenParser(visitor, tokens)
        let resust = (parser.parse() as MapToString).getOrThrow()
        println(resust)
        @Assert(resust.getInt("a").getOrThrow(), 1)
        @Assert(resust.getString("b").getOrThrow(), "xyz")
        @Assert(resust.getBool("c").getOrThrow(), true)
    }

    /**
     * 测试数组解析 - 验证基本数组的解析
     */
    @TestCase
    public func testArray1() {
        let tokens = quote([a, b, c])
        let visitor = TokenStrValueVisitor()
        let parser = TokenParser(visitor, tokens)
        let resust = (parser.parse() as ListToString).getOrThrow()
        println(resust)
        @Assert(resust.getString(0).getOrThrow(), "a")
        @Assert(resust.getString(1).getOrThrow(), "b")
        @Assert(resust.getString(2).getOrThrow(), "c")
    }

    /**
     * 测试数字数组解析 - 验证包含整数的数组解析
     */
    @TestCase
    public func testArray2() {
        let tokens = quote([1, 2, 3])
        let visitor = TokenStrValueVisitor()
        let parser = TokenParser(visitor, tokens)
        let resust = (parser.parse() as ListToString).getOrThrow()
        println(resust)
        @Assert(resust.getInt(0).getOrThrow(), 1)
        @Assert(resust.getInt(1).getOrThrow(), 2)
        @Assert(resust.getInt(2).getOrThrow(), 3)
    }

    /**
     * 测试字符串数组解析 - 验证包含字符串的数组解析
     */
    @TestCase
    public func testArray3() {
        let tokens = quote(["a", "b", "c"])
        let visitor = TokenStrValueVisitor()
        let parser = TokenParser(visitor, tokens)
        let resust = (parser.parse() as ListToString).getOrThrow()
        println(resust)
        @Assert(resust.getString(0).getOrThrow(), "a")
        @Assert(resust.getString(1).getOrThrow(), "b")
        @Assert(resust.getString(2).getOrThrow(), "c")
    }

    /**
     * 测试映射解析 - 验证基本映射结构的解析
     */
    @TestCase
    public func testMap1() {
        let tokens = quote({a:1,b:xyz,c:true})
        let visitor = TokenStrValueVisitor()
        let parser = TokenParser(visitor, tokens)
        let resust = (parser.parse() as MapToString).getOrThrow()
        println(resust)
        @Assert(resust.getInt("a").getOrThrow(), 1)
        @Assert(resust.getString("b").getOrThrow(), "xyz")
        @Assert(resust.getBool("c").getOrThrow(), true)
    }

    /**
     * 测试引号字符串映射解析 - 验证包含引号字符串的映射解析
     */
    @TestCase
    public func testMap2() {
        let tokens = quote({"a":1,"b":"xyz","c":true})
        let visitor = TokenStrValueVisitor()
        let parser = TokenParser(visitor, tokens)
        let resust = (parser.parse() as MapToString).getOrThrow()
        println(resust)
        @Assert(resust.getInt("a").getOrThrow(), 1)
        @Assert(resust.getString("b").getOrThrow(), "xyz")
        @Assert(resust.getBool("c").getOrThrow(), true)
    }

    /**
     * 测试复杂结构解析1 - 验证包含嵌套映射的复杂结构解析
     */
    @TestCase
    public func testComplex1() {
        let tokens = quote(
        a:{
            a1:1,
            a2:{
                a3a:1
            }
        }
        )
        println(tokens.toString())
        let visitor = TokenStrValueVisitor()
        let parser = TokenParser(visitor, tokens)
        let resust = (parser.parse() as MapToString).getOrThrow()
        println(resust)
        @Assert(resust.getMap("a")?.getInt("a1").getOrThrow(), 1)
        @Assert(resust.getMap("a")?.getMap("a2")?.getInt("a3a").getOrThrow(), 1)
    }

    /**
     * 测试复杂结构解析2 - 验证包含嵌套数组的复杂结构解析
     */
    @TestCase
    public func testComplex2() {
        let tokens = quote(
        a:[
            [1, 2],
            [3, 4]
        ]
        )
        println(tokens.toString())
        let visitor = TokenStrValueVisitor()
        let parser = TokenParser(visitor, tokens)
        let resust = (parser.parse() as MapToString).getOrThrow()
        println(resust)
        @Assert(resust.getList("a")?.getList(0)?.getInt(0).getOrThrow(), 1)
        @Assert(resust.getList("a")?.getList(1)?.getInt(0).getOrThrow(), 3)
    }

    /**
     * 测试复杂结构解析3 - 验证顶层数组的复杂结构解析
     */
    @TestCase
    public func testComplex3() {
        let tokens = quote(
        [
            [1, 2],
            [3, 4]
        ])
        println(tokens.toString())
        let visitor = TokenStrValueVisitor()
        let parser = TokenParser(visitor, tokens)
        let resust = (parser.parse() as ListToString).getOrThrow()
        println(resust)
        @Assert(resust.getList(0)?.getInt(0).getOrThrow(), 1)
        @Assert(resust.getList(1)?.getInt(0).getOrThrow(), 3)
    }

    /**
     * 测试复杂结构解析4 - 验证包含多种嵌套结构的复杂结构解析
     */
    @TestCase
    public func testComplex4() {
        let tokens = quote(
        a:{
            a1:1,
            a2:xyz,
            a3:{
                a3a:1,
                a3b:xyz,
                a3c:true
            },
            a4:[1,2]
        },
        b:[1,2],
        c:true
        )
        println(tokens.toString())
        let visitor = TokenStrValueVisitor()
        let parser = TokenParser(visitor, tokens)
        let resust = (parser.parse() as MapToString).getOrThrow()
        println(resust)
        @Assert(resust.getMap("a")?.getInt("a1").getOrThrow(), 1)
        @Assert(resust.getMap("a")?.getList("a4")?.getInt(0).getOrThrow(), 1)
        @Assert(resust.getList("b")?.getInt(0).getOrThrow(), 1)
    }

    /**
     * 测试复杂结构解析5 - 验证包含完整语法的复杂结构解析
     */
    @TestCase
    public func testComplex5() {
        let tokens = quote(
        {
            a:{
                a1:1,
                a2:xyz,
                a3:{
                    a3a:1,
                    a3b:xyz,
                    a3c:true
                },
                a4:[1,2]
            },
            b:[1,2],
            c:true
        })
        println(tokens.toString())
        let visitor = TokenStrValueVisitor()
        let parser = TokenParser(visitor, tokens)
        let resust = (parser.parse() as MapToString).getOrThrow()
        println(resust)
        @Assert(resust.getMap("a")?.getInt("a1").getOrThrow(), 1)
        @Assert(resust.getMap("a")?.getList("a4")?.getInt(0).getOrThrow(), 1)
        @Assert(resust.getList("b")?.getInt(0).getOrThrow(), 1)
    }
}
