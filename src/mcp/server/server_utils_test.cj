/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.mcp.server

import std.collection.ArrayList
import std.unittest.testmacro.*
import cjoy.mcp.api.PaginatedRequest

/**
 * 测试 MCP 服务器的工具函数
 */
@Test
public class McpServerUtilsTestCaseSuit {
    /**
     * 测试负数分页游标 - 验证非法游标按首页处理
     */
    @TestCase
    public func testNegativeCursor(): Unit {
        let utils = McpPaginationUtils(pageSize: 2)
        let items = ArrayList<String>(["a", "b", "c", "d", "e"])

        let (page, next) = utils.paginate(items, PaginatedRequest(cursor: "-1"))
        @Assert(page.size, 2)
        @Assert(page[0], "a")
        @Assert(page[1], "b")
        @Assert(next.getOrThrow(), "2")
    }

    /**
     * 测试回环地址判断 - 验证必须精确匹配主机名，防止 DNS 重绑定保护被绕过
     */
    @TestCase
    public func testLoopbackAddress(): Unit {
        @Assert(isLoopbackAddress("127.0.0.1"), true)
        @Assert(isLoopbackAddress("localhost:8080"), true)
        @Assert(isLoopbackAddress("[::1]:8080"), true)
        @Assert(isLoopbackAddress("notlocalhost:8080"), false)
        @Assert(isLoopbackAddress("attacker-127.0.0.1.evil.com:80"), false)
        @Assert(isLoopbackAddress("example.com"), false)
    }
}
