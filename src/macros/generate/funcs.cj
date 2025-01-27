/*
 * Copyright (c) lanlingx 2025-present. All rights resvered.
 */

package cjoy.macros.generate

import std.ast.*
import std.collection.*
import cjoy.*

public enum MethodCatgory {
    MC_POST | MC_GET | MC_DELETE | MC_PUT | MC_PATCH | MC_HEAD | MC_METHODS
}

class FuncInfo {
    let marcroName: String
    let catgory: MethodCatgory

    let decl: FuncDecl

    var path: String = ""
    var provider: String = ""

    init(marcroName: String, catgory: MethodCatgory, decl: FuncDecl) {
        this.marcroName = marcroName
        this.catgory = catgory
        this.decl = decl
    }

    func parseAttr(attr: Tokens): Unit {
        parseKVAttr(attr, marcroName,
            {
                ident: Token, value: Token => match (ident.value) {
                    case "path" => this.path = value.value
                    case "provider" => this.provider = value.value
                    case _ => throw Exception("${marcroName} attriable should be name, consumer, provider")
                }
            })
    }

    private func declVars(): (Tokens, Tokens) {
        var vars = Tokens()
        var params = Tokens()
        for (fp in decl.funcParams) {
            let pid = fp.identifier
            let pname = pid.value
            let piOpt = ParamInfoCache.findByParamName(pname)
            let paramInfo = match (piOpt) {
                case Some(val) => val
                case _ =>
                    let val = ParamInfo("", PC_NONE)
                    val.parse(fp.toTokens())
                    val
            }

            vars += paramInfo.getDeclVarTokens()
            if (params.size == 0) {
                params += quote($(pid))
            } else {
                params += quote(, $(pid))
            }
        }

        (vars, params)
    }

    private func callFunc(params: Tokens): Tokens {
        var ret = Tokens()
        let funcName = decl.identifier
        let delType = try {
            decl.declType
        } catch (ex: Exception) {
            ret += quote(
                $(funcName)($(params))
                ctx.ok()
            )
            return ret
        }

        if (delType is TupleType) {
            let tt = (delType as TupleType).getOrThrow()
            if (tt.types.size != 2) {
                diagReport(DiagReportLevel.ERROR, decl.toTokens(),
                    "return type must is tuple with 2 element, first is Unit16, second is String or JsonSerializable",
                    "(status, body)")
                throw Exception(
                    "return must is tuple with 2 element, first is Unit16, second is String or JsonSerializable")
            }
            ret += quote(
                let (status, body) = $(funcName)($(params))
            )
            if (provider == "json") {
                ret += quote(
                    ctx.json(status, body) 
                )
            } else {
                ret += quote(
                    ctx.string(status, body.toString()) 
                )
            }
        } else if (delType.toTokens()[0].value != "Unit") {
            ret += quote(let body = $(funcName)($(params)))
            if (provider == "json") {
                ret += quote(
                    ctx.json(body) 
                )
            } else {
                ret += quote(
                    ctx.string(body.toString()) 
                )
            }
        } else {
            ret += quote(
                $(funcName)($(params))
                ctx.ok()
            )
        }
        ret
    }

    func genCodes(): Tokens {
        let handlerName = Token(TokenKind.IDENTIFIER, decl.identifier.value.toAsciiTitle() + "Handler")

        let (vars, params) = declVars()
        let callfunc = callFunc(params)
        quote(
            class $(handlerName) <: JoyRequestHandler {
                public func handle(ctx: JoyContext): Unit {
                    $(vars)
                    $(callfunc)
                }
            }   
       )
    }
}

public func parseFunc(marcroName: String, catgory: MethodCatgory, attr: Tokens, input: Tokens): Tokens {
    let decl = parseDecl(input)
    if (!(decl is FuncDecl)) {
        throw Exception("${marcroName} macro only using for func")
    }

    let funcInfo = FuncInfo(marcroName, catgory, (decl as FuncDecl).getOrThrow())
    funcInfo.parseAttr(attr)
    let tokens = funcInfo.genCodes()
    ParamInfoCache.clear()
    tokens
}
