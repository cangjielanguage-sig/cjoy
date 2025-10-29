/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

macro package cjoy.mcp.macros

import std.ast.*
import std.collection.*
import cjoy.utils.{MapToString, MapListGetFunc, randStr}
import cjoy.utils.ast.parserAttrs

open class FuncInfo {
    let macroName: String
    let decl: FuncDecl

    var name: String = ""
    var description: String = ""

    init(macroName: String, decl: FuncDecl) {
        this.macroName = macroName
        this.decl = decl
    }

    protected open func parseAttr(attr: Tokens): Unit {
        let map: MapToString = parserAttrs(attr, validKeys: ["name", "description"], macroName: macroName)
        this.name = map.getString("name") ?? decl.identifier.value
        this.description = map.getString("description") ?? ""
    }

    protected func callFunc(params: Tokens): Tokens {
        var ret = Tokens()
        let funcName = decl.identifier

        // not return type
        try {
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
            $(funcName)($(params))
        )
        ret
    }

    protected open func genTokens(): Tokens {
        Tokens()
    }
}

class ToolFuncInfo <: FuncInfo {
    init(macroName: String, decl: FuncDecl) {
        super(macroName, decl)
    }

    private func isOnlyOneComplex(): Bool {
        var paramInfos = ArrayList<ParamInfo>()
        for (fp in decl.funcParams) {
            let pname = fp.identifier.value
            let paramInfo = match (ParamInfoCache.findByParamName(pname)) {
                case Some(val) => val
                case _ =>
                    let val = ParamInfo("ToolParam")
                    val.parseFuncParam(fp)
                    val
            }
            if (!paramInfo.isComplexType()) {
                return false
            }
            if (!paramInfo.isJoyContext()) {
                paramInfos.add(paramInfo)
            }
        }
        return paramInfos.size == 1
    }

    private func declVars(): (Tokens, Tokens, Tokens, Tokens) {
        var vars = Tokens()
        var params = Tokens()
        var rjson = Tokens()
        var schame = Tokens()
        for (fp in decl.funcParams) {
            let pid = fp.identifier
            let paramInfo = match (ParamInfoCache.findByParamName<ToolParamInfo>(pid.value)) {
                case Some(val) => val
                case _ =>
                    let val = ToolParamInfo("ToolParam")
                    val.parseFuncParam(fp)
                    val
            }

            vars += paramInfo.genVarTokens()
            rjson += paramInfo.genReadJsonTokens()
            schame += paramInfo.genSchemaTokens()
            if (params.size > 0) {
                params += Token(TokenKind.COMMA)
            }
            if (paramInfo.isJoyContext() || paramInfo.isOption()) {
                params += quote($(pid))
            } else {
                params += quote($(pid).getOrThrow())
            }
        }

        (vars, rjson, params, schame)
    }

    private func declVarsForOneComplex(): (Tokens, Tokens, Tokens) {
        var vars = Tokens()
        var params = Tokens()
        var schame = Tokens()
        for (fp in decl.funcParams) {
            let pid = fp.identifier
            let paramInfo = match (ParamInfoCache.findByParamName<ToolParamInfo>(pid.value)) {
                case Some(val) => val
                case _ =>
                    let val = ToolParamInfo("ToolParam")
                    val.parseFuncParam(fp)
                    val
            }

            vars += paramInfo.genVarComplexTypeTokens()
            schame += paramInfo.genSchemComplexTypeTokens()
            if (params.size > 0) {
                params += Token(TokenKind.COMMA)
            }
            params += quote($(pid))
        }

        (vars, params, schame)
    }

    private func genFuncsBody(): Tokens {
        if (isOnlyOneComplex()) {
            let (vars, params, schame) = declVarsForOneComplex()
            let callfunc = callFunc(params)
            let initFunc = quote(
                private init() {
                    $schame
                    let tool = McpTool(name: $name, description: $description, inputSchema: inputSchema)
                    McpServer.tools.addTool(tool)
                    McpServer.tools.addCallToolHandler($name, this)
                }
            )
            let handleFunc = quote(
                public func handle(ctx: JoyContext, arguments_: Array<Byte>): Any {
                    $(vars)
                    $(callfunc)
                }
            )
            initFunc + handleFunc
        } else {
            let (vars, rjson, params, schame) = declVars()
            let callfunc = callFunc(params)
            let initFunc = quote(
                private init() {
                    let inputSchema = HashMap<String, JsonSerializable>()
                    let properties = HashMap<String, JsonSerializable>()
                    let required = ArrayList<String>()
                    $schame
                    inputSchema.add("type", "object")
                    inputSchema.add("properties", properties)
                    inputSchema.add("required", required)

                    let tool = McpTool(name: $name, description: $description, inputSchema: inputSchema)
                    McpServer.tools.addTool(tool)
                    McpServer.tools.addCallToolHandler($name, this)
                }
            )
            let handleFunc = quote(
                public func handle(ctx: JoyContext, arguments_: Array<Byte>): Any {
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
                            case _ => throw JSONRPCException(
                                JSONRPCError(code: JSONRPCConsts.ERR_PARSE_ERROR, message: "not start json object"))
                        }
                    }

                    $(callfunc)
                }
            )
            initFunc + handleFunc
        }
    }

    protected func genTokens(): Tokens {
        let handlerName = Token(TokenKind.IDENTIFIER, decl.identifier.value.toAsciiTitle() + "Handler" + randStr(3))
        let funcsBody = genFuncsBody()
        quote(
            public class $(handlerName) <: McpCallToolHandler {
                public static let INSTANCE = $(handlerName)()
                $funcsBody
            }   
       )
    }
}

func parseFunc(macroName: String, attr: Tokens, input: Tokens): Tokens {
    let decl = parseDecl(input)
    if (!(decl is FuncDecl)) {
        diagReport(DiagReportLevel.ERROR, attr, "@${macroName} macro only using for func", "")
        return Tokens()
    }

    let funcInfo = match (macroName) {
        case "Tool" => ToolFuncInfo(macroName, (decl as FuncDecl).getOrThrow())
        case "Resource" => ResoureFuncInfo(macroName, (decl as FuncDecl).getOrThrow())
        case "Prompt" => PromptFuncInfo(macroName, (decl as FuncDecl).getOrThrow())
        case _ => throw Exception("not support ${macroName} macro")
    }

    funcInfo.parseAttr(attr)
    let tokens = funcInfo.genTokens()
    ParamInfoCache.clear()
    tokens
}
