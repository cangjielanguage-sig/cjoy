/*
 * Copyright (c) lanlingx 2025-present. All rights resvered.
 */

package cjoy.macros.generate

import std.ast.*
import std.collection.*
import cjoy.*

class MiddlewareInfo {
    let marcroName = "Middleware"

    let decl: FuncDecl

    var groups: String = ""

    init(decl: FuncDecl) {
        this.decl = decl
    }

    func getGroups(): Array<String> {
        if (groups == "") {
            return ["/"]
        }
        groups.split(",", removeEmpty:true)
    }

    func parseAttr(attr: Tokens): Unit {
        parseKVAttr(attr, marcroName,
            {
                ident: Token, value: Token => match (ident.value) {
                    case "groups" => this.groups = value.value
                    case _ => throw Exception("${marcroName} attriable should be groups")
                }
            })
    }

    func genCodes(): Tokens {
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

public func parseMiddlewareFunc(attr: ?Tokens, input: Tokens): Tokens {
    let decl = parseDecl(input)
    if (!(decl is FuncDecl)) {
        throw Exception("Middleware macro only using for func")
    }

    let funcInfo = MiddlewareInfo((decl as FuncDecl).getOrThrow())
    if (let Some(a) <- attr) {
        funcInfo.parseAttr(a)
    }
    funcInfo.genCodes()
}