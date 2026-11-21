/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.test

import cjoy.*
import cjoy.macros.*
import cjoy.mcp.*
import cjoy.mcp.client.createMcpSseClient
import cjoy.mcp.client.createMcpStreamableClient
import cjoy.mcp.client.McpClientFeatures
import cjoy.jsonrpc.*
import std.io.StringReader
import stdx.encoding.base64.toBase64String
import stdx.net.http.*
import std.sync.AtomicInt32

// Tool-----------

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

@Tool[name = "greet", description = "greet with default name"]
public func greet(@ToolParam[default = "world"] who: String): String {
    "hello ${who}"
}

@Tool[description = "image"]
public func image(): Image {
    Image(data: [1, 2, 3], format: "png")
}

@Tool[description = "audio"]
public func audio(): Audio {
    Audio(data: [1, 2, 3], format: "avi")
}

// Resource-----------
@Resource[uri = "data://secret"]
public func secretId(): Int {
    1
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

// Prompt-----------
@Prompt[name = askUserTopic]
public func askUserTopic(topic: String): String {
    "Can you please explain the concept of ${topic}"
}

@Prompt[name = analyze_data_request, description = "Creates a request to analyze data with specific parameters"]
public func dataAnalysisPrompt(
    @PromptParam[description = "The URI of the resource containing the data."] dataUri: String,
    @PromptParam[default = "summary", description = "Type of analysis."] analysisType: String
): String {
    "Please perform a '${analysisType}' analysis on the data found at ${dataUri}."
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

    /**
     * 测试 MCP 工具调用功能 - 验证所有工具的列出和调用功能
     */
    @TestCase
    public func testTools(): Unit {
        try (client = createMcpSseClient("http://127.0.0.1:18881/sse")) {
            let _ = client.initialize()

            let listResult = client.listTools()
            @Assert(listResult.tools.size, 10)

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

    /**
     * 测试 MCP 资源读取功能 - 验证所有资源的列出和读取功能
     */
    @TestCase
    public func testResources(): Unit {
        try (client = createMcpSseClient("http://127.0.0.1:18881/sse")) {
            let _ = client.initialize()

            let listResult = client.listResources()
            @Assert(listResult.resources.size, 5)

            let listTemplateResult = client.listResourceTemplates()
            @Assert(listTemplateResult.resourceTemplates.size, 1)

            let check = {
                result: ReadResourceResult, value: String =>
                @Assert(result.contents.size, 1)
                @Assert((result.contents[0] as TextResourceContents).getOrThrow().text, value)
            }

            let checkBlob = {
                result: ReadResourceResult, value: Array<Byte> =>
                @Assert(result.contents.size, 1)
                @Assert((result.contents[0] as BlobResourceContents).getOrThrow().blob, toBase64String(value))
            }
            
            var readResult = client.readResource(ReadResourceRequest(uri: "data://secret"))
            check(readResult, "1")
            readResult = client.readResource(ReadResourceRequest(uri: "resource://system-status"))
            check(readResult, JsonTool.toJson(HashMap<String, String>([("status", "ok")])))
            readResult = client.readResource(ReadResourceRequest(uri: "resource://xiao/detail"))
            check(readResult, JsonTool.toJson(HashMap<String, String>([("name", "xiao")])))
            readResult = client.readResource(ReadResourceRequest(uri: "file:///app/data/important_log"))
            check(readResult, "this is an important log")
            readResult = client.readResource(ReadResourceRequest(uri: "resource://stream-data"))
            checkBlob(readResult, "stream".toArray())
        }
    }

    /**
     * 测试 MCP 提示获取功能 - 验证所有提示的列出和获取功能
     */
    @TestCase
    public func testPrompts(): Unit {
        try (client = createMcpSseClient("http://127.0.0.1:18881/sse")) {
            let _ = client.initialize()

            let listResult = client.listPrompts()
            @Assert(listResult.prompts.size, 2)

            let check = {
                result: GetPromptResult, value: String =>
                @Assert(result.messages.size, 1)
                let content = result.messages[0].content.getOrThrow()
                let textContent = (content as TextContent).getOrThrow()
                @Assert(textContent.text, value)
            }

            // test askUserTopic prompt
            var callResult = client.getPrompt(GetPromptRequest(name: "askUserTopic", arguments: HashMap<String, String>([("topic", "MCP")])))
            check(callResult, "Can you please explain the concept of MCP")

            // test dataAnalysisPrompt with all parameters
            callResult = client.getPrompt(GetPromptRequest(name: "analyze_data_request", arguments: HashMap<String, String>([("dataUri", "data://test-data"), ("analysisType", "detailed")])))
            check(callResult, "Please perform a 'detailed' analysis on the data found at data://test-data.")

            // test dataAnalysisPrompt with default analysisType
            callResult = client.getPrompt(GetPromptRequest(name: "analyze_data_request", arguments: HashMap<String, String>([("dataUri", "data://test-data")])))
            check(callResult, "Please perform a 'summary' analysis on the data found at data://test-data.")
        }
    }

    /**
     * 测试工具调用失败场景 - 验证调用不存在的工具会抛出异常
     */
    @TestCase
    public func testToolCallFailure(): Unit {
        try (client = createMcpSseClient("http://127.0.0.1:18881/sse")) {
            let _ = client.initialize()

            // test calling non-existent tool
            let result = client.callTool(CallToolRequest(name: "non_existent_tool", arguments: HashMap<String, String>()))
            @Assert(result.isError, true)
            @Assert(result.content.size, 1)
            let textContent = (result.content[0] as TextContent).getOrThrow()
            @Assert(textContent.text.contains("not found tool handler"), true)
        }
    }

    /**
     * 测试资源读取失败场景 - 验证读取不存在的资源会抛出异常
     */
    @TestCase
    public func testResourceReadFailure(): Unit {
        try (client = createMcpSseClient("http://127.0.0.1:18881/sse")) {
            let _ = client.initialize()

            // test reading non-existent resource
            let ex = try {
                let _ = client.readResource(ReadResourceRequest(uri: "data://non_existent_resource"))
                None<Exception>
            } catch (e: Exception) {
                Some(e)
            }
            @Assert(ex.isSome(), true)
        }
    }

    /**
     * 测试提示获取失败场景 - 验证获取不存在的提示会抛出异常
     */
    @TestCase
    public func testPromptGetFailure(): Unit {
        try (client = createMcpSseClient("http://127.0.0.1:18881/sse")) {
            let _ = client.initialize()

            // test getting non-existent prompt
            let ex = try {
                let _ = client.getPrompt(GetPromptRequest(name: "non_existent_prompt", arguments: HashMap<String, String>()))
                None<Exception>
            } catch (e: Exception) {
                Some(e)
            }
            @Assert(ex.isSome(), true)
        }
    }

    /**
     * 测试 MCP 心跳功能 - 验证客户端和服务器之间的心跳机制
     */
    @TestCase
    public func testPing(): Unit {
        try (client = createMcpSseClient("http://127.0.0.1:18881/sse")) {
            let _ = client.initialize()

            // test ping request
            client.ping()
        }
    }

    /**
     * 测试工具参数默认值 - 验证 @ToolParam[default] 在缺少参数时生效
     */
    @TestCase
    public func testToolParamDefault(): Unit {
        try (client = createMcpSseClient("http://127.0.0.1:18881/sse")) {
            let _ = client.initialize()

            let result = client.callTool(CallToolRequest(name: "greet", arguments: HashMap<String, String>()))
            @Assert(result.content.size, 1)
            @Assert((result.content[0] as TextContent).getOrThrow().text, "hello world")
        }
    }

    /**
     * 测试提示词参数的 required 标记 - 验证必需/可选参数的区分
     */
    @TestCase
    public func testPromptArgumentRequired(): Unit {
        try (client = createMcpSseClient("http://127.0.0.1:18881/sse")) {
            let _ = client.initialize()
            let prompts = client.listPrompts().prompts

            var checkedTopic = false
            var checkedDefault = false
            for (prompt in prompts) {
                for (arg in prompt.arguments) {
                    if (prompt.name == "askUserTopic" && arg.name == "topic") {
                        @Assert(arg.required, true)
                        checkedTopic = true
                    }
                    if (prompt.name == "analyze_data_request" && arg.name == "analysisType") {
                        @Assert(arg.required, false)
                        checkedDefault = true
                    }
                }
            }
            @Assert(checkedTopic, true)
            @Assert(checkedDefault, true)
        }
    }

    /**
     * 测试仅支持旧协议版本的客户端 - 验证 InitializeRequest 使用配置的协议版本
     */
    @TestCase
    public func testProtocolNegotiationWithOlderVersion(): Unit {
        let features = McpClientFeatures()
        features.protocolVesions = ["2025-03-26"]
        try (client = createMcpSseClient("http://127.0.0.1:18881/sse", features: features)) {
            let result = client.initialize()
            @Assert(result.protocolVersion, "2025-03-26")
        }
    }

    /**
     * 测试并发请求 - 验证每个请求获得唯一的 JSON-RPC ID 与响应等待器
     */
    @TestCase
    public func testConcurrentRequests(): Unit {
        try (client = createMcpSseClient("http://127.0.0.1:18881/sse")) {
            let _ = client.initialize()
            let tools = spawn { client.listTools() }
            let prompts = spawn { client.listPrompts() }
            @Assert(tools.get().tools.size, 10)
            @Assert(prompts.get().prompts.size, 2)
        }
    }

    /**
     * 测试 MCP 协议协商功能 - 验证客户端和服务器之间的协议版本协商
     */
    @TestCase
    public func testProtocolNegotiation(): Unit {
        let features1 = McpClientFeatures()
        features1.protocolVesions = ["2025-03-26", "2025-11-25"]
        try (client = createMcpSseClient("http://127.0.0.1:18881/sse", features: features1)) {
            let result = client.initialize()
            @Assert(result.protocolVersion, "2025-11-25")
        }

        let features2 = McpClientFeatures()
        features2.protocolVesions = ["2025-11-25"]
        try (client = createMcpSseClient("http://127.0.0.1:18881/sse", features: features2)) {
            let result = client.initialize()
            @Assert(result.protocolVersion, McpConsts.LASTEST_PROTOCOL_VERSION)
        }
    }
}

/**
 * 测试 MCP Streamable HTTP 传输 - 验证会话管理与协议头校验
 */
@Test
public class McpStreamableServerTestCaseSuit {
    var _instance: ?Joy = None
    let _client = ClientBuilder().build()

    @BeforeAll
    func setup(): Unit {
        spawn {
            let joy = Joy.default()
            _instance = joy
            McpServer.registerStreamableTo(joy, path: "/mcp", isJsonResp: true)
            joy.run("127.0.0.1", 18884)
        }
        sleep(2 * Duration.second)
    }

    @AfterAll
    func tearDown(): Unit {
        _client.close()
        _instance?.shutdown()
    }

    private func post(body: Array<Byte>, sid!: ?String = None, accept!: String = "application/json, text/event-stream"): (UInt16, String, ?String) {
        let builder = HttpRequestBuilder().url("http://127.0.0.1:18884/mcp").method("POST")
            .header("Content-Type", "application/json")
            .header("Accept", accept)
            .header("Mcp-Protocol-Version", McpConsts.LASTEST_PROTOCOL_VERSION)
            .body(body)
        if (let Some(id) <- sid) {
            builder.header(McpConsts.HEADER_MCP_SESSION_ID, id)
        }
        let rsp = _client.send(builder.build())
        let status = rsp.status
        let text = StringReader(rsp.body).readToEnd()
        let sessionId = rsp.headers.getFirst(McpConsts.HEADER_MCP_SESSION_ID)
        (status, text, sessionId)
    }

    private func initBody(): Array<Byte> {
        JSONRPCTool.serialize(
            JSONRPCRequest(id: "init-1", method: McpConsts.METHOD_INITIALIZE,
                params: InitializeRequest(protocolVersion: McpConsts.LASTEST_PROTOCOL_VERSION,
                    capabilities: ClientCapabilities(), clientInfo: Implementation(name: "test", version: "1")))).bytes()
    }

    /**
     * 测试初始化、会话复用与会话终止 - 验证 mcp-session-id 生命周期
     */
    @TestCase
    public func testSessionLifecycle(): Unit {
        let (status, body, sid) = post(initBody())
        @Assert(status, 200)
        @Assert(body.contains(McpConsts.LASTEST_PROTOCOL_VERSION), true)
        @Assert(sid.isSome(), true)
        let sessionId = sid.getOrThrow()
        @Assert(sessionId != "", true)

        let toolsBody = JSONRPCTool.serialize(JSONRPCRequest(id: "tools-1", method: McpConsts.METHOD_TOOLS_LIST,
            params: PaginatedRequest())).bytes()
        let (listStatus, listBody, _) = post(toolsBody, sid: sessionId)
        @Assert(listStatus, 200)
        @Assert(listBody.contains("tools"), true)

        // 未知会话ID返回404
        let (badStatus, _, _) = post(toolsBody, sid: "unknown-session")
        @Assert(badStatus, 404)

        // DELETE 终止会话后，原 ID 不再可用
        let delReq = HttpRequestBuilder().url("http://127.0.0.1:18884/mcp").method("DELETE")
            .header(McpConsts.HEADER_MCP_SESSION_ID, sessionId).build()
        let delRsp = _client.send(delReq)
        let _ = StringReader(delRsp.body).readToEnd()
        @Assert(delRsp.status, 200)

        let (afterStatus, _, _) = post(toolsBody, sid: sessionId)
        @Assert(afterStatus, 404)
    }

    /**
     * 测试缺少会话 ID - 验证普通请求必须携带 mcp-session-id
     */
    @TestCase
    public func testMissingSessionId(): Unit {
        let body = JSONRPCTool.serialize(JSONRPCRequest(id: "tools-2", method: McpConsts.METHOD_TOOLS_LIST,
            params: PaginatedRequest())).bytes()
        let (status, _, _) = post(body)
        @Assert(status, 400)
    }

    /**
     * 测试不接受 SSE - 验证 Accept 头必须同时包含 JSON 与 event-stream
     */
    @TestCase
    public func testNotAcceptable(): Unit {
        let (status, _, _) = post(initBody(), accept: "application/json")
        @Assert(status, 406)
    }

    /**
     * 测试错误的内容类型 - 验证 POST 只接受 application/json
     */
    @TestCase
    public func testUnsupportedMediaType(): Unit {
        let builder = HttpRequestBuilder().url("http://127.0.0.1:18884/mcp").method("POST")
            .header("Content-Type", "text/plain")
            .header("Accept", "application/json, text/event-stream")
            .body("{}")
        let rsp = _client.send(builder.build())
        @Assert(rsp.status, 415)
    }
}

/**
 * 测试 MCP Streamable HTTP 客户端 - 验证内置客户端可完成完整会话流程
 */
@Test
public class McpStreamableClientTestCaseSuit {
    var _instance: ?Joy = None

    @BeforeAll
    func setup(): Unit {
        spawn {
            let joy = Joy.default()
            _instance = joy
            McpServer.registerStreamableTo(joy, path: "/mcp", isJsonResp: true)
            joy.run("127.0.0.1", 18885)
        }
        sleep(2 * Duration.second)
    }

    @AfterAll
    func tearDown(): Unit {
        _instance?.shutdown()
    }

    /**
     * 测试流模式客户端的初始化、工具列表与调用 - 验证会话 ID 在后续请求中携带
     */
    @TestCase
    public func testStreamableClient(): Unit {
        try (client = createMcpStreamableClient("http://127.0.0.1:18885/mcp")) {
            let result = client.initialize()
            @Assert(result.protocolVersion, McpConsts.LASTEST_PROTOCOL_VERSION)

            @Assert(client.listTools().tools.size, 10)
            let callResult = client.callTool(
                CallToolRequest(name: "add1", arguments: HashMap<String, Int64>([("a", 1), ("b", 2)])))
            @Assert(callResult.content.size, 1)
            @Assert((callResult.content[0] as TextContent).getOrThrow().text, "3")
            client.ping()
        }
    }

    /**
     * 测试流模式客户端处理 SSE 响应 - 验证非 JSON 模式下仍能完成请求
     */
    @TestCase
    public func testStreamableClientWithSseResponse(): Unit {
        let joy = Joy.default()
        spawn {
            McpServer.registerStreamableTo(joy, path: "/mcp", isJsonResp: false)
            joy.run("127.0.0.1", 18886)
        }
        sleep(2 * Duration.second)
        try {
            try (client = createMcpStreamableClient("http://127.0.0.1:18886/mcp")) {
                let result = client.initialize()
                @Assert(result.protocolVersion, McpConsts.LASTEST_PROTOCOL_VERSION)
                @Assert(client.listPrompts().prompts.size, 2)
            }
        } finally {
            joy.shutdown()
        }
    }
}
