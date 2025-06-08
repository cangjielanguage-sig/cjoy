/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
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

public struct McpConsts {
    // protocol
    public static const JSON_RPC_VERSION = "2.0"
    public static const LASTEST_PROTOCOL_VERSION = "2024-11-05"

    // role 
    public static const ROLE_USER = "user"
    public static const ROLE_ASSISTANT = "assistant"

    // error code
    public static const ERR_PARSE_ERROR = -32700
    public static const ERR_INVALID_REQUEST = -32600
    public static const ERR_METHOD_NOT_FOUND = -32601
    public static const ERR_INVALID_PARAMS = -32602
    public static const ERR_INTERNAL_ERROR = -32603

    // methods
    public static const METHOD_INITIALIZE = "initialize";
    public static const METHOD_NOTIFICATION_INITIALIZED = "notifications/initialized";
    public static const METHOD_PING = "ping";
    public static const METHOD_TOOLS_LIST = "tools/list";
    public static const METHOD_TOOLS_CALL = "tools/call";
    public static const METHOD_NOTIFICATION_TOOLS_LIST_CHANGED = "notifications/tools/list_changed";
}

public interface JSONRPCMessage {}

@Json
public class JSONRPCRequest <: JSONRPCMessage {
    public var jsonrpc: String = McpConsts.JSON_RPC_VERSION
    public var id: String = ""
    public var method: String = ""
    @JsonField[raw = true]
    public var params: Any = Option<Any>.None
}

@Json
public class JSONRPCError {
    public var code: Int = 0
    public var message: ?String = None
    public var Data: Any = Option<Any>.None
}

@Json
public class JSONRPCResponse <: JSONRPCMessage {
    public var jsonrpc: String = McpConsts.JSON_RPC_VERSION
    public var id: String = ""
    @JsonField[raw = true]
    public var result: Any = Option<Any>.None
    public var error: ?JSONRPCError = None
}

@Json
public class JSONRPCNotification <: JSONRPCMessage {
    public var jsonrpc: String = McpConsts.JSON_RPC_VERSION
    public var method: String = ""
    @JsonField[raw = true]
    public var params: Any = Option<Any>.None
}

public type Role = String

@Json
public class PaginatedRequest {
    @JsonField[omitempty = true]
    public var cursor: ?String = None
}

@Json
public class PaginatedResult {
    public var nextCursor: String = ""
}

@Json
public class JsonSchema {
    @JsonField[name = "type"]
    public var type_: String = ""
    public var properties: Any = HashMap<String, Any>()
    public var required: ArrayList<String> = ArrayList()
    public var additionalProperties: Bool = false
    @JsonField[name = "$defs"]
    public var defs: Any = HashMap<String, Any>()
    public var definitions: Any = HashMap<String, Any>()
}
