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

class ResoureFuncInfo <: FuncInfo {
    var uri: String = ""
    var mimeType: String = ""
    var isTemplate: Bool = false

    init(macroName: String, decl: FuncDecl) {
        super(macroName, decl)
    }

    protected func parseAttr(attr: Tokens): Unit {
        let map: MapToString = parserAttrs(attr, validKeys: ["name", "description", "uri", "mimeType", "template"],
            macroName: macroName)
        this.name = map.getString("name") ?? decl.identifier.value
        this.description = map.getString("description") ?? ""
        this.uri = map.getString("uri") ?? ""
        this.mimeType = map.getString("mimeType") ?? ""
        this.isTemplate = map.getBool("template") ?? false
        if (this.uri.indexOf("://").isNone()) {
            throw Exception("${uri} is invalid, should like resource://path, data://path")
        }
    }

    private func declVars(): (Tokens, Tokens) {
        var vars = Tokens()
        var params = Tokens()
        for (fp in decl.funcParams) {
            let pid = fp.identifier
            let piOpt = ParamInfoCache.findByParamName<ResourceParamInfo>(pid.value)
            let paramInfo = match (piOpt) {
                case Some(val) => val
                case _ =>
                    let val = ResourceParamInfo("ResourceParam")
                    val.parseFuncParam(fp)
                    val
            }

            vars += paramInfo.genBindVarTokens()
            if (params.size == 0) {
                params += quote($(pid))
            } else {
                params += quote(, $(pid))
            }
        }

        (vars, params)
    }

    private func genFuncsBody(): Tokens {
        let initFunc = quote(
            private init() {
                let resource = McpResource(uri: $uri, name: $name, description: $description, mimeType: $mimeType)
                McpServer.resources.addResource(resource)
                McpServer.resources.addReadResourceHandler($uri, this)
            }
        )
        let (vars, params) = declVars()
        let callfunc = callFunc(params)
        let ctxParams = if (mimeType != "") {
            quote(ctx.addParam("mimeType", $mimeType)
            )
        } else {
            Tokens()
        }
        let handleFunc = quote(
            public func readResource(ctx: JoyContext): Any {
                $ctxParams
                $vars
                $callfunc
            }
        )
        initFunc + handleFunc
    }

    protected func genTokens(): Tokens {
        let handlerName = Token(TokenKind.IDENTIFIER, decl.identifier.value.toAsciiTitle() + "Handler" + randStr(3))
        let funcsBody = genFuncsBody()
        quote(
            public class $(handlerName) <: McpReadResourceHandler {
                public static let INSTANCE = $(handlerName)()
                $funcsBody
            }   
       )
    }
}
