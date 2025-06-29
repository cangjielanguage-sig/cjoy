/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 */

package cjoy.examples.mcpserver

import cjoy.*
import cjoy.mcp.*
import cjoy.middleware.ExceptionHandler

@Tool[description = "add two number"]
public func add(@ToolParam[description = "number a"] a: Int, @ToolParam[description = "number b"] b: Int): Int {
    a + b
}

@Tool[description = "nultiply two number"]
public func multiply(a: Int, b: Int): Int {
    a * b
}

@Tool[description = "nultiply two number"]
public func search(query: String, ctx: JoyContext): String {
    "search result"
}

// ----in param is complex----
@Json
public class Params {
    @JsonField[description = "number a"]
    public var a: Int
    @JsonField[description = "number b"]
    public var b: Int
}

@Tool[description = "add two number"]
public func add2(param: Params): Int {
    param.a + param.b
}

@Tool[description = "add two number"]
public func add3(param: Params, ctx: JoyContext): Int {
    param.a + param.b
}

//--- resources -----
@Resource[uri = "data://secret"]
public func secretData(): String {
    "secret data"
}

@Resource[uri = "data://config"]
public func config(): HashMap<String, Int> {
    HashMap<String, Int>([("version", 1)])
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

// --- prompts -----
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

main(): Int64 {
    var cfg = JoyConfig()
    cfg.enableDebugLog = true
    // 创建joy实例
    let joy = Joy.create(cfg)
    joy.router.use(ExceptionHandler())
    // 注册生成的handlers
    McpServer.registerSseTo(joy)
    joy.run("127.0.0.1", 18881)
    return 0
}
