/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 */
package cjoy.examples.mcpclient

import std.collection.HashMap
import cjoy.json.*
import cjoy.mcp.common.*
import cjoy.mcp.schema.*
import cjoy.mcp.client.*

main(): Int64 {
    try(client = createMcpSseClient("http://127.0.0.1:18881/sse")) {
        let _ = client.initialize()
        let _ = client.listTools()
        let _ = client.callTool(CallToolRequest(name: "add", arguments: HashMap<String, Int64>([("a", 1), ("b", 2)])))
        let _ = client.callTool(CallToolRequest(name: "multiply", arguments: HashMap<String, Int64>([("a", 2), ("b", 3)])))
    } 
    return 0
}