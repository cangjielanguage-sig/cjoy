/*
 * Copyright (c) lanlingx 2025-present. All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.mcp.schema

import std.collection.{HashMap, ArrayList}
import cjoy.json.*

@Json
public class Implementation {
    public var name: String = ""
    public var version: String = ""
}

@Json
public class ClientCapabilities {
    public var experimental: Any = Option<Any>.None
}

@Json
public class ToolCapability {
    public var listChanged: Bool = false
}

@Json
public class ServerCapabilities {
    public var tools: ?ToolCapability = None
}

@Json
public class InitializeRequest {
    public var protocolVersion: String = McpConsts.LASTEST_PROTOCOL_VERSION
    public var capabilities: ?ClientCapabilities = None
    public var clientInfo: ?Implementation = None
}

@Json
public class InitializeResult {
    public var protocolVersion: String = McpConsts.LASTEST_PROTOCOL_VERSION
    public var capabilities: ?ServerCapabilities = None
    public var serverInfo: ?Implementation = None
    public var instructions: ?String = None
}
