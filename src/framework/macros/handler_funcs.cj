/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

macro package cjoy.framework.macros

import std.ast.*
import std.collection.*
import cjoy.utils.{MapToString, MapListGetFunc, randStr}
import cjoy.utils.ast.{parserAttrs, joinTokens}

class FuncInfo {
    let macroName: String

    let decl: FuncDecl

    var path: String = ""
    var produce: String = ""
    var methods: String = ""

    init(macroName: String, decl: FuncDecl) {
        this.macroName = macroName
        this.decl = decl
    }

    func parseAttr(attr: Tokens): Unit {
        let map: MapToString = parserAttrs(attr, validKeys: ["path", "produce", "methods"], macroName: macroName)
        this.path = map.getString("path") ?? ""
        this.produce = map.getString("produce") ?? ""
        this.methods = map.getString("methods") ?? ""
    }

    func getMethods(): Array<String> {
        if (methods.isEmpty()) {
            return [macroName.toAsciiUpper()]
        }

        let array = methods.split(",", removeEmpty: true)
        array |> map {a: String => a.toAsciiUpper().trimAscii()} |> collectArray
    }

    func getMethodStr(): String {
        if (methods.isEmpty()) {
            return macroName.toAsciiUpper()
        }
        methods
    }

    private func declVars(): (Tokens, Tokens) {
        let vars = ArrayList<Tokens>()
        let params = ArrayList<Tokens>()
        for (fp in decl.funcParams) {
            let pid = fp.identifier
            let pname = pid.value
            let piOpt = ParamInfoCache.findByParamName(pname)
            let paramInfo = match (piOpt) {
                case Some(val) => val
                case _ =>
                    let val = createParamVarGenerator("")
                    val.parseFuncParam(fp)
                    val
            }

            vars.add(paramInfo.genTokens())
            params.add(quote($(pid)))
        }

        (joinTokens(vars, Token(TokenKind.NL)), joinTokens(params, Token(TokenKind.COMMA)))
    }
    /**
     * @throws Exception
     */
    private func callFunc(params: Tokens): Tokens {
        var ret = Tokens()
        let funcName = decl.identifier
        let delType = try {
            decl.declType
        } catch (_: Exception) {
            ret += quote(
                $(funcName)($(params))
            )
            return ret
        }

        let retType = delType.toTokens()[0].value
        if (delType is TupleType) {
            ret += handleTupleRet(delType, funcName, params)
        } else if (retType == "UInt16") {
            ret += quote(
                let statusCode = $(funcName)($(params))
                ctx.status(UInt16(statusCode))
            )
        } else if (retType != "Unit") {
            ret += handleSingeRet(funcName, params)
        } else {
            ret += quote(
                $(funcName)($(params))
            )
        }
        ret
    }

    /**
     * @throws Exception
     */
    private func handleTupleRet(delType: TypeNode, funcName: Token, params: Tokens): Tokens {
        let tt = (delType as TupleType).getOrThrow()
        var ret = Tokens()
        if (tt.types.size != 2) {
            diagReport(DiagReportLevel.ERROR, decl.toTokens(),
                "return type must is tuple with 2 element, first is Uint16, second is String or JsonSerializable",
                "(status, body)")
            throw Exception(
                "return must is tuple with 2 element, first is Uint16, second is String or JsonSerializable")
        }
        let tfirstType = tt.types[0]
        if (tfirstType is PrimitiveType) {
            ret += quote(
                let (statusCode, bodyRsp) = $(funcName)($(params))
            )
        } else {
            ret += quote(
                let (bodyRsp, statusCode) = $(funcName)($(params))
            )
        }
        if (produce == "json") {
            ret += quote(
                ctx.status(UInt16(statusCode)).json(bodyRsp) 
            )
        } else {
            ret += quote(
                ctx.status(UInt16(statusCode)).string(bodyRsp.toString()) 
            )
        }
        ret
    }

    private func handleSingeRet(funcName: Token, params: Tokens): Tokens {
        var ret = Tokens()
        ret += quote(let bodyRsp = $(funcName)($(params)))
        if (produce == "json") {
            ret += quote(
                ctx.json(bodyRsp) 
            )
        } else {
            ret += quote(
                ctx.string(bodyRsp.toString()) 
            )
        }
        ret
    }

    func genTokens(): Tokens {
        let handlerName = Token(TokenKind.IDENTIFIER, decl.identifier.value.toAsciiTitle() + "Handler" + randStr(3))

        let (vars, params) = declVars()
        let callfunc = callFunc(params)
        quote(
            public class $(handlerName) <: JoyRequestHandler {
                public static let INSTANCE = $(handlerName)()
                init() {
                    JoyHandlers.addHandler($(path), $(getMethods()), this)
                }
                public func handle(ctx: JoyContext): Unit {
                    $(vars)
                    $(callfunc)
                }
            }   
       )
    }

    func sendMessage(): Tokens {
        let funcName = decl.identifier.value
        let handlerName = Token(TokenKind.IDENTIFIER, funcName + "Handler" + randStr(2))

        let (vars, params) = declVars()
        let callfunc = callFunc(params)
        let funcTokens: Tokens = quote(
            public func $handlerName(ctx: JoyContext): Unit {
                $(vars)
                $(callfunc)
            }
        )

        setItem("handler.func", funcTokens)
        setItem("handler.name", handlerName.value)
        setItem("handler.path", path)
        setItem("handler.methods", getMethodStr())
        Tokens()
    }
}

/**
 * @throws Exception
 */
func parseFunc(macroName: String, attr: Tokens, input: Tokens): Tokens {
    let decl = parseDecl(input)
    if (!(decl is FuncDecl)) {
        throw Exception("${macroName} macro only using for func")
    }

    let funcInfo = FuncInfo(macroName, (decl as FuncDecl).getOrThrow())
    funcInfo.parseAttr(attr)
    if (insideParentContext("Controller")) {
        let tokens = funcInfo.sendMessage()
        ParamInfoCache.clear()
        tokens
    } else {
        let tokens = funcInfo.genTokens()
        ParamInfoCache.clear()
        tokens
    }
}
