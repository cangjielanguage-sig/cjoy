/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.jsonrpc.api

import cjoy.json.*
import cjoy.json.macros.*

public abstract class BaseMessage <: ToString & JsonSerializable {
    public func toString(): String {
        JsonTool.toJson(this)
    }
}

public abstract class JSONRPCMessage <: BaseMessage {}

@Json
public class JSONRPCRequest <: JSONRPCMessage {
    public var jsonrpc: String = JSONRPCConsts.JSON_RPC_VERSION
    public var id: Any = Option<Any>.None
    public var method: String = ""
    @JsonField[raw = true]
    public var params: Any = Option<Any>.None
}

@Json
public class JSONRPCError <: BaseMessage {
    public var code: Int = 0
    public var message: ?String = None
    public var data: Any = Option<Any>.None
}

@Json
public class JSONRPCResponse <: JSONRPCMessage {
    public var jsonrpc: String = JSONRPCConsts.JSON_RPC_VERSION
    public var id: Any = Option<Any>.None
    @JsonField[raw = true]
    public var result: Any = Option<Any>.None
    public var error: ?JSONRPCError = None
}

@Json
public class JSONRPCNotification <: JSONRPCMessage {
    public var jsonrpc: String = JSONRPCConsts.JSON_RPC_VERSION
    public var method: String = ""
    @JsonField[raw = true]
    public var params: Any = Option<Any>.None
}

public class JSONRPCException <: Exception {
    public let error: JSONRPCError

    public init(error: JSONRPCError) {
        super(error.message ?? "")
        this.error = error
    }
}

public struct JSONRPCConsts {
    public static const JSON_RPC_VERSION: String = "2.0"

    // error code
    public static const ERR_PARSE_ERROR: Int = -32700
    public static const ERR_INVALID_REQUEST: Int = -32600
    public static const ERR_METHOD_NOT_FOUND: Int = -32601
    public static const ERR_INVALID_PARAMS: Int = -32602
    public static const ERR_INTERNAL_ERROR: Int = -32603
}
