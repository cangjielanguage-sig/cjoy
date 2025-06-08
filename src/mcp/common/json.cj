/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

protected package cjoy.mcp.common

import std.io.ByteBuffer
import stdx.encoding.json.stream.{JsonDeserializable, JsonSerializable, JsonReader, JsonWriter, JsonToken}
import cjoy.mcp.schema.*

public class RPCJsonTool {
    public static func deserializJSONRPCMessage(content: Array<Byte>): JSONRPCMessage {
        var stream = ByteBuffer()
        stream.write(content)
        let reader = JsonReader(stream)

        var id: ?JsonSerializable = None
        var method: String = ""
        var params: Any = Option<Any>.None
        var result: Any = Option<Any>.None
        var error: ?JSONRPCError = None

        while (let Some(v) <- reader.peek()) {
            match (v) {
                case BeginObject =>
                    reader.startObject()
                    while (reader.peek() != EndObject) {
                        let name = reader.readName()
                        match (name) {
                            case "jsonrpc" =>
                                let jsonrpc = reader.readValue<String>()
                                if (jsonrpc != McpConsts.JSON_RPC_VERSION) {
                                    throw McpException(
                                        JSONRPCError(code: McpConsts.ERR_INVALID_PARAMS,
                                            message: "rpc version is invalid"))
                                }
                            case "id" =>
                                if (let Some(next) <- reader.peek()) {
                                    match (next) {
                                        case JsonString => id = reader.readValue<String>()
                                        case JsonNumber => id = reader.readValue<Int64>()
                                        case _ => throw McpException(
                                            JSONRPCError(code: McpConsts.ERR_INVALID_PARAMS,
                                                message: "id type is invalid"))
                                    }
                                } else {
                                    throw McpException(
                                        JSONRPCError(code: McpConsts.ERR_PARSE_ERROR, message: "id type is invalid"))
                                }
                            case "method" => reader.readValue<String>()
                            case "params" => reader.readValueBytes()
                            case "result" => reader.readValueBytes()
                            case "error" => reader.readValue<JSONRPCError>()
                            case _ => reader.skip()
                        }
                    }
                    reader.endObject()
                    break
                case _ => throw McpException(
                    JSONRPCError(code: McpConsts.ERR_PARSE_ERROR, message: "not start json object"))
            }
        }

        if (id.isSome() && method != "") {
            return JSONRPCRequest(id: id.getOrThrow(), method: method, params: params)
        } else if (id.isSome() && (result is Array<Byte>)) {
            return JSONRPCResponse(id: id.getOrThrow(), result: result, error: error)
        } else if (id.isNone() && method != "") {
            return JSONRPCNotification(method: method, params: params)
        }

        throw McpException(JSONRPCError(code: McpConsts.ERR_PARSE_ERROR, message: "invalid JSON RPC message"))
    }
}
