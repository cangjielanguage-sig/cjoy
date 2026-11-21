/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.middleware

@Test
public class CorsTestCaseSuit {
    /**
     * 测试解析 CORS 头部 - 验证各种格式的头部字符串能正确解析
     */
    @TestCase
    public func testParseHeaders() {
        let h = parseHeaders(
            "header, second-header, THIRD-HEADER, Numb3r3d-H34d3r, Header_with_underscore Header.with.full.stop")
        let e = ["Header", "Second-Header", "Third-Header", "Numb3r3d-H34d3r", "Header_with_underscore",
            "Header.with.full.stop"]
        if (h[0] != e[0] || h[1] != e[1] || h[2] != e[2] || h[3] != e[3] || h[4] != e[4] || h[5] != e[5]) {
            @Fail("${h} != ${e}")
        }
    }

    /**
     * 测试解析空的 CORS 头部 - 验证空字符串或空白字符串会解析为空数组
     */
    @TestCase
    public func testParseHeadersEmpty() {
        if (parseHeaders("").size != 0) {
            @Fail("should be empty array")
        }
        if (parseHeaders(" , ").size != 0) {
            @Fail("should be empty array")
        }
    }

    /**
     * 测试 CORS 通配符匹配 - 验证 CorsWildcard 类的 canMatch 方法能正确匹配模式
     */
    @TestCase
    public func testWildcard() {
        var w = CorsWildcard("foo", "bar")
        if (!w.canMatch("foobar")) {
            @Fail("foo*bar should match foobar")
        }
        if (!w.canMatch("foobazbar")) {
            @Fail("foo*bar should match foobazbar")
        }
        if (w.canMatch("foobaz")) {
            @Fail("foo*bar should not match foobaz")
        }

        w = CorsWildcard("foo", "oof")
        if (w.canMatch("foof")) {
            @Fail("foo*oof should not match foof")
        }

        w = CorsWildcard("http://", ".example.com")
        if (!w.canMatch("http://sub.example.com:8080")) {
            @Fail("origin with port should match wildcard")
        }
    }
}
