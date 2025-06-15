/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.mcp.generate

import std.ast.*
import std.collection.*
import cjoy.utils.{parserAttrs, MapToString, MapListGetFunc, randStr}

open class FuncInfo {
    let macroName: String 
    let decl: FuncDecl

    var name: String = ""
    var description: String = ""

    init(macroName: String ,decl: FuncDecl) {
        this.macroName = macroName
        this.decl = decl
    }

    func parseAttr(attr: Tokens): Unit {
        let map: MapToString = parserAttrs(attr, validKeys: ["name", "description"], macroName: macroName)
        this.name = map.getString("name") ?? decl.identifier.value
        this.description = map.getString("description") ?? ""
    }
}

class ToolFuncInfo <: FuncInfo {
    init(macroName: String, decl: FuncDecl) {
        super(macroName, decl)
    }

    private func declVars(): (Tokens, Tokens, Tokens, Tokens) {
        var vars = Tokens()
        var params = Tokens()
        var rjson = Tokens()
        var schame = Tokens()
        for (fp in decl.funcParams) {
            let pid = fp.identifier
            let pname = pid.value
            let paramInfo = match (ParamInfoCache.findByParamName(pname)) {
                case Some(val) => val
                case _ =>
                    let val = ParamInfo("ToolParam")
                    val.parseFuncParam(fp)
                    val
            }

            vars += paramInfo.genVarTokens()
            rjson += paramInfo.genReadJsonTokens()
            schame += paramInfo.genSchemTokens()
            if (params.size > 0) {
                 params += Token(TokenKind.COMMA)
            } 
            if (paramInfo.isJoyContext()) {
                params += quote($(pid))
            } else {
                params += quote($(pid).getOrThrow())
            }
        }

        (vars, rjson, params, schame)
    }

    private func callFunc(params: Tokens): Tokens {
        var ret = Tokens()
        let funcName = decl.identifier

        // not return type
        let delType = try {
            decl.declType
        } catch (_: Exception) {
            ret += quote(
                $(funcName)($(params))
                ""
            )
            return ret
        }

        // check the return type
        ret += quote(
            let res = $(funcName)($(params))
            match(res) {
                case x: ToString => x.toString()
                case x: JsonSerializable => JsonTool.toJson(x)
                case _ => ""
            }
        )
        ret
    }

    func genTokens(): Tokens {
        let handlerName = Token(TokenKind.IDENTIFIER, decl.identifier.value.toAsciiTitle() + "Handler" + randStr(3))

        let (vars, rjson, params, schame) = declVars()
        let callfunc = callFunc(params)
        quote(
            public class $(handlerName) <: McpCallToolHandler {
                public static let INSTANCE = $(handlerName)()
                
                private init() {
                    McpServer.addMcpCallToolHandler($(name), this)
                    let inputSchema = HashMap<String, JsonSerializable>()
                    let properties = HashMap<String, JsonSerializable>()
                    let required = ArrayList<String>()

                    $schame

                    inputSchema.add("type", "object")
                    inputSchema.add("properties", properties)
                    inputSchema.add("required", required)

                    let tool = McpTool(name: $name, description: $description, inputSchema: inputSchema)
                    McpServer.addTool(tool)
                }

                public func handle(ctx: JoyContext, arguments_: Array<Byte>): String {
                    let buffer_ = ByteBuffer()
                    buffer_.write(arguments_)
                    let reader_ = JsonReader(buffer_)

                    $(vars)

                    while (let Some(v) <- reader_.peek()) {
                        match (v) {
                            case BeginObject =>
                                reader_.startObject()
                                while (reader_.peek() != EndObject) {
                                    let name = reader_.readName()
                                    match (name) {
                                        $(rjson)
                                        case _ => reader_.skip()
                                    }
                                }
                                reader_.endObject()
                                break
                            case _ => throw McpException(
                                JSONRPCError(code: McpConsts.ERR_PARSE_ERROR, message: "not start json object"))
                        }
                    }

                    $(callfunc)
                }
            }   
       )
    }
}


public func parseFunc(macroName: String, attr: Tokens, input: Tokens): Tokens {
    let decl = parseDecl(input)
    if (!(decl is FuncDecl)) {
        throw Exception("${macroName} macro only using for func")
    }

    let funcInfo = ToolFuncInfo(macroName, (decl as FuncDecl).getOrThrow())
    funcInfo.parseAttr(attr)
    let tokens = funcInfo.genTokens()
    ParamInfoCache.clear()
    tokens
}
