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
import cjoy.utils.{parserAttrs, MapToString, MapListGetFunc, randStr}

class PromptFuncInfo <: FuncInfo {
    init(macroName: String, decl: FuncDecl) {
        super(macroName, decl)
    }

    protected func parseAttr(attr: Tokens): Unit {
        let map: MapToString = parserAttrs(attr, validKeys: ["name", "description"], macroName: macroName)
        this.name = map.getString("name") ?? decl.identifier.value
        this.description = map.getString("description") ?? ""
    }

    private func declVars(): (Tokens, Tokens, Tokens) {
        var vars = Tokens()
        var params = Tokens()
        var args = Tokens()
        for (fp in decl.funcParams) {
            let pid = fp.identifier
            let piOpt = ParamInfoCache.findByParamName<PromptParamInfo>(pid.value)
            let paramInfo = match (piOpt) {
                case Some(val) => val
                case _ =>
                    let val = PromptParamInfo("PromptParam")
                    val.parseFuncParam(fp)
                    val
            }

            vars += paramInfo.genBindVarTokens()
            if (params.size == 0) {
                params += quote($(pid))
            } else {
                params += quote(, $(pid))
            }

            let arg = paramInfo.genPromptArgTokens()
            if (arg.size != 0) {
                if (args.size == 0) {
                    args += arg
                } else {
                    args += Token(TokenKind.COMMA)
                    args += arg
                }
            }
        }

        (vars, params, args)
    }

    private func genFuncsBody(): Tokens {
        let (vars, params, args) = declVars()
        let initFunc = quote(
            private init() {
                let arguments = ArrayList<PromptArgument>([$args])
                let prompt = McpPrompt(name: $name, description: $description, arguments: arguments)
                McpServer.prompts.addPrompt(prompt)
                McpServer.prompts.addGetPromptHandler($name, this)
            }
        )
        let callfunc = callFunc(params)
        let handleFunc = quote(
            public func getPrompt(ctx: JoyContext, arguments: HashMap<String, String>): Any {
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
            public class $(handlerName) <: McpGetPromptHandler {
                public static let INSTANCE = $(handlerName)()
                $funcsBody
            }
       )
    }
}
