/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 */

package cjoy.examples.mcpserver

import cjoy.*
import cjoy.mcp.*
import cjoy.middleware.ExceptionHandler

@Tool[description = "add two number"]
public func add(@ToolParam[description="number a"] a: Int, @ToolParam[description="number b"] b: Int): Int {
    a + b
}

@Tool[description = "nultiply two number"]
public func multiply(a: Int, b: Int): Int {
    a * b
}

main(): Int64 {
    var cfg = JoyConfig()
    cfg.enableDebugLog = true
    // 创建joy实例
    let joy = Joy.create(cfg)
    // 注册生成的handlers
    joy.router.use(ExceptionHandler())
    McpServer.registerSseTo(joy)
    joy.run("127.0.0.1", 18881)
    return 0
}
