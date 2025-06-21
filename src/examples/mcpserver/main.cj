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
