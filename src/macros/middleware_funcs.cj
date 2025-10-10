/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

macro package cjoy.macros

import std.ast.*
import cjoy.utils.{MapToString, MapListGetFunc}
import cjoy.utils.ast.parserAttrs

class MiddlewareInfo {
    let macroName = "Middleware"

    let decl: FuncDecl

    var groups: String = ""

    init(decl: FuncDecl) {
        this.decl = decl
    }

    func getGroups(): Array<String> {
        if (groups == "") {
            return ["/"]
        }
        groups.split(",", removeEmpty: true)
    }

    func parseAttr(attr: Tokens): Unit {
        let map: MapToString = parserAttrs(attr, validKeys: ["groups"], macroName: macroName)
        this.groups = map.getString("groups") ?? ""
    }

    func genTokens(): Tokens {
        let handlerName = Token(TokenKind.IDENTIFIER, decl.identifier.value.toAsciiTitle() + "Middleware")
        let funcName = decl.identifier
        quote(
            public class $(handlerName) <: JoyMiddlewareHandler {
                public static let INSTANCE = $(handlerName)()
                
                init() {
                    JoyMiddlewares.addHandler($(getGroups()), this)
                }

                public func handle(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
                    $(funcName)(ctx, chain)
                }
            }   
       )
    }
}

/**
 * @throws Exception
 */
func parseMiddlewareFunc(attr: ?Tokens, input: Tokens): Tokens {
    let decl = parseDecl(input)
    if (!(decl is FuncDecl)) {
        throw Exception("Middleware macro only using for func")
    }

    let funcInfo = MiddlewareInfo((decl as FuncDecl).getOrThrow())
    if (let Some(a) <- attr) {
        funcInfo.parseAttr(a)
    }
    funcInfo.genTokens()
}
