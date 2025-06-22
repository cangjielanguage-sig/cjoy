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

import stdx.encoding.base64.toBase64String
import cjoy.*
import cjoy.mcp.*
import cjoy.mcp.common.McpClient
import cjoy.mcp.client.createMcpSseClient

@Tool[description = "query"]
public func query(): String {
    "query1"
}

@Tool[name = "query2", description = "query"]
public func query(ctx: JoyContext): String {
    "query2"
}

@Tool[name = "add1", description = "add two number"]
public func add(@ToolParam[description = "number a"] a: Int, @ToolParam[description = "number b"] b: Int): Int {
    a + b
}

@Tool[name = "add2", description = "add three number"]
public func add(@ToolParam[description = "number a"] a: Int, @ToolParam[description = "number b"] b: Int, c: ?Int): Int {
    a + b + (c ?? 0)
}

@Tool[description = "nultiply two number"]
public func multiply(a: Int, b: Int): Int {
    a * b
}

@Json
public class McpAddParam {
    public var a: Int = 0
    public var b: Int = 0
}

@Tool[name = "add3", description = "add two number"]
public func add(param: McpAddParam): Int {
    param.a + param.b
}

@Tool[name = "add4", description = "add two number"]
public func add(param: ?McpAddParam): Int {
    (param?.a ?? 0) + (param?.b ?? 0)
}

@Tool[description = "image"]
public func image(): Image {
    Image(data: [1, 2, 3], format: "png")
}

@Tool[description = "audio"]
public func audio(): Audio {
    Audio(data: [1, 2, 3], format: "avi")
}

@Resource[uri = "data://secret"]
public func secretData(): String {
    "secret data"
}

@Resource[uri = "data://config"]
public func config(): HashMap<String, Int> {
    HashMap<String, Int>([("version", 1)])
}

@Resource[uri = "resource://system-status"]
public func systemStatus(ctx: JoyContext): HashMap<String, String> {
    HashMap<String, String>([("status", "ok")])
}

@Resource[uri = "resource://{name}/detail"]
public func systemStatus(ctx: JoyContext, name: String): HashMap<String, String> {
    HashMap<String, String>([("name", name)])
}

@Resource[uri = "file:///app/data/important_log", mimeType = "text/plain"]
public func readLog(): String {
    "this is an important log"
}

@Resource[uri = "resource://stream-data"]
public func readData(): Array<Byte> {
    "stream".toArray()
}

@Test
public class McpServerTestCaseSuit {
    var _instance: ?Joy = None

    @BeforeAll
    func setup(): Unit {
        spawn {
            let joy = Joy.default()
            _instance = joy
            McpServer.registerSseTo(joy)
            joy.run("127.0.0.1", 18881)
        }
        sleep(2 * Duration.second)
    }

    @AfterAll
    func tearDown(): Unit {
        _instance?.shutdown()
    }

    @TestCase
    public func testTools(): Unit {
        try (client = createMcpSseClient("http://127.0.0.1:18881/sse")) {
            let _ = client.initialize()

            let listResult = client.listTools()
            @Assert(listResult.tools.size, 9)

            let check = {
                result: CallToolResult, value: String =>
                @Assert(result.content.size, 1)
                @Assert((result.content[0] as TextContent).getOrThrow().text, value)
            }

            // tool query
            var callResult = client.callTool(CallToolRequest(name: "query", arguments: HashMap<String, String>()))
            check(callResult, "query1")
            // tool query2
            callResult = client.callTool(CallToolRequest(name: "query2", arguments: HashMap<String, String>()))
            check(callResult, "query2")
            // tool add1
            callResult = client.callTool(
                CallToolRequest(name: "add1", arguments: HashMap<String, Int64>([("a", 1), ("b", 2)])))
            check(callResult, "3")
            // tool add2
            callResult = client.callTool(
                CallToolRequest(name: "add2", arguments: HashMap<String, Int64>([("a", 3), ("b", 2), ("c", 1)])))
            check(callResult, "6")
            // tool add2
            callResult = client.callTool(
                CallToolRequest(name: "add2", arguments: HashMap<String, Int64>([("a", 3), ("b", 2)])))
            check(callResult, "5")
            // tool multiply
            callResult = client.callTool(
                CallToolRequest(name: "multiply", arguments: HashMap<String, Int64>([("a", 3), ("b", 2)])))
            check(callResult, "6")
            // tool add3
            callResult = client.callTool(
                CallToolRequest(name: "add3", arguments: HashMap<String, Int64>([("a", 5), ("b", 6)])))
            check(callResult, "11")
            // tool add4
            callResult = client.callTool(
                CallToolRequest(name: "add4", arguments: HashMap<String, Int64>([("a", 7), ("b", 8)])))
            check(callResult, "15")
            // tool add4
            callResult = client.callTool(CallToolRequest(name: "add4", arguments: HashMap<String, Int64>()))
            check(callResult, "0")
            // tool image
            callResult = client.callTool(CallToolRequest(name: "image", arguments: HashMap<String, String>()))
            @Assert(callResult.content.size, 1)
            let image = (callResult.content[0] as ImageContent).getOrThrow();
            @Assert(image.mimeType, "image/png")
            @Assert(image.data, toBase64String([1, 2, 3]))
            // tool audio
            callResult = client.callTool(CallToolRequest(name: "audio", arguments: HashMap<String, String>()))
            @Assert(callResult.content.size, 1)
            let audio = (callResult.content[0] as AudioContent).getOrThrow();
            @Assert(audio.mimeType, "audio/avi")
            @Assert(audio.data, toBase64String([1, 2, 3]))
        }
    }
}
