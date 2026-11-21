/*
 * Copyright (c) 2026 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.fs

import std.collection.ArrayList
import std.unittest.testmacro.*

class RangeTest {
    RangeTest(let start: Int, let length: Int) {}
}

@Test
public class RangeTestCaseSuit {
    /**
     * 测试解析无效的 HTTP 范围请求 - 验证无效的范围字符串会抛出 IllegalArgumentException
     */
    @TestCase
    public func testParseRangeInvalidCases() {
        // Test cases that should throw IllegalArgumentException or return empty
        let invalidCases: Array<(String, Int)> = [
            ("", 0),
            ("", 1000),
            ("foo", 0),
            ("foo", 10),
            ("bytes=", 0),
            ("bytes=7", 10),
            ("bytes= 7 ", 10),
            ("bytes=1-", 0),
            ("bytes=5-4", 10),
            ("bytes=0-2,5-4", 10),
            ("bytes=2-5,4-3", 10),
            ("bytes=--5,4--3", 10),
            ("bytes=A-", 10),
            ("bytes=A- ", 10),
            ("bytes=A-Z", 10),
            ("bytes= -Z", 10),
            ("bytes=5-Z", 10),
            ("bytes=Ran-dom, garbage", 10),
            ("bytes=0x01-0x02", 10),
            ("bytes=         ", 10),
            ("bytes= , , ,   ", 10),
            ("bytes=-0", 10),
            ("bytes=10-", 10),
            ("bytes=0-", 0)
        ]

        for ((s, length) in invalidCases) {
            let result = try {
                JoyHttpRange.parse(s, length)
                false
            } catch (_: IllegalArgumentException) {
                true
            }
            if (!result) {
                @Fail("parseRange(${s}) should throw IllegalArgumentException")
            }
        }
    }

    /**
     * 测试解析有效的 HTTP 范围请求 - 验证有效范围字符串能正确解析为预期的范围对象
     */
    @TestCase
    public func testParseRangeValidCases() {
        // Test cases with expected results
        // (rangeString, size, expectedRanges)
        let validCases: Array<(String, Int, Array<RangeTest>)> = [
            ("bytes=0-9", 10, [RangeTest(0, 10)]),
            ("bytes=0-", 10, [RangeTest(0, 10)]),
            ("bytes=5-", 10, [RangeTest(5, 5)]),
            ("bytes=0-20", 10, [RangeTest(0, 10)]),
            ("bytes=15-,0-5", 10, [RangeTest(0, 6)]),
            ("bytes=1-2,5-", 10, [RangeTest(1, 2), RangeTest(5, 5)]),
            ("bytes=-2 , 7-", 11, [RangeTest(9, 2), RangeTest(7, 4)]),
            ("bytes=0-0 ,2-2, 7-", 11, [RangeTest(0, 1), RangeTest(2, 1), RangeTest(7, 4)]),
            ("bytes=-5", 10, [RangeTest(5, 5)]),
            ("bytes=-15", 10, [RangeTest(0, 10)]),
            ("bytes=0-499", 10000, [RangeTest(0, 500)]),
            ("bytes=500-999", 10000, [RangeTest(500, 500)]),
            ("bytes=-500", 10000, [RangeTest(9500, 500)]),
            ("bytes=9500-", 10000, [RangeTest(9500, 500)]),
            ("bytes=0-0,-1", 10000, [RangeTest(0, 1), RangeTest(9999, 1)]),
            ("bytes=500-600,601-999", 10000, [RangeTest(500, 101), RangeTest(601, 399)]),
            ("bytes=500-700,601-999", 10000, [RangeTest(500, 201), RangeTest(601, 399)]),
            ("bytes=   1 -2   ,  4- 5, 7 - 8 , ,,", 11, [RangeTest(1, 2), RangeTest(4, 2), RangeTest(7, 2)])
        ]

        for ((s, size, expected) in validCases) {
            let ranges = try {
                JoyHttpRange.parse(s, size)
            } catch (e: IllegalArgumentException) {
                @Fail("parseRange(${s}) should not throw error: ${e.message}")
            }

            if (ranges.size != expected.size) {
                @Fail("len(parseRange(${s})) = ${ranges.size}, want ${expected.size}")
            }

            for (i in 0..(expected.size)) {
                if (ranges[i].start != expected[i].start) {
                    @Fail("parseRange(${s})[${i}].start = ${ranges[i].start}, want ${expected[i].start}")
                }
                if (ranges[i].length != expected[i].length) {
                    @Fail("parseRange(${s})[${i}].length = ${ranges[i].length}, want ${expected[i].length}")
                }
            }
        }
    }

    /**
     * 测试 Content-Range 头部生成 - 验证范围对象能正确生成 Content-Range 字符串
     */
    @TestCase
    public func testContentRange() {
        let r = JoyHttpRange(start: 0, length: 10)
        let expected = "bytes 0-9/100"
        let result = r.contentRange(100)
        if (result != expected) {
            @Fail("contentRange() = ${result}, want ${expected}")
        }
    }

    /**
     * 测试范围总和计算 - 验证多个范围对象的总长度计算正确
     */
    @TestCase
    public func testSumSize() {
        let ranges: JoyHttpRangs = JoyHttpRangs()
        ranges.add(JoyHttpRange(start: 0, length: 10))
        ranges.add(JoyHttpRange(start: 10, length: 5))
        ranges.add(JoyHttpRange(start: 15, length: 3))

        let expected = 18
        let result = ranges.sumSize()
        if (result != expected) {
            @Fail("sumSize() = ${result}, want ${expected}")
        }
    }
}
