/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.test

import cjoy.*
import cjoy.mcp.*
import cjoy.mcp.schema.*
import cjoy.mcp.common.McpClient
import cjoy.mcp.client.createMcpSseClient

@Tool[description = "query"]
public func query(): String {
    ""
}

@Tool[description = "query"]
public func query(ctx: JoyContext): String {
    ""
}

@Tool[description = "add two number"]
public func add(@ToolParam[description = "number a"] a: Int, @ToolParam[description = "number b"] b: Int): Int {
    a + b
}

@Tool[description = "add three number"]
public func add(@ToolParam[description = "number a"] a: Int, @ToolParam[description = "number b"] b: Int, c: ?Int): Int {
    a + b + (c ?? 0)
}

@Tool[description = "nultiply two number"]
public func multiply(a: Int, b: Int): Int {
    a * b
}

@Test
public class McpServerTestCaseSuit {
    var _instance: ?Joy = None

    @BeforeAll
    func setup(): Unit {
        spawn {
            var cfg = JoyConfig()
            cfg.enableDebugLog = true
            let joy = Joy.create(cfg)
            _instance = joy
            McpServer.registerSseTo(joy)
            joy.run("127.0.0.1", 18881)
        }
        sleep(Duration.second)
    }

    @AfterAll
    func tearDown(): Unit {
        _instance?.shutdown()
    }

    @TestCase
    @Skip
    public func testInit(): Unit {
        try (client = createMcpSseClient("http://127.0.0.1:18881/sse")) {
            let _ = client.initialize()
            let _ = client.listTools()
            let _ = client.callTool(CallToolRequest(name: "add", arguments: HashMap<String, Int64>([("a", 1), ("b", 2)])
            ))
        }
    }
}
