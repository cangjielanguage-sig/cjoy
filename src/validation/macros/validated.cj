/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

macro package cjoy.validation.macros

import std.ast.*
import std.collection.ArrayList

class FuncInfo {
    let decl: FuncDecl

    init(decl: FuncDecl) {
        this.decl = decl
    }

    func addFuncBody(): Unit {
        var exprs = Tokens()
        for (fp in decl.funcParams) {
            let name = fp.identifier.value
            let fieldInfo = FieldInfoCache.findByName(name)
            if (let Some(fi) <- fieldInfo) {
                exprs += fi.genValidateTokens()
            }
        }
        let expr = DoWhileExpr(quote(do {
            $exprs
        } while (false)
        ))
        decl.block.nodes.add(expr, at: 0)
    }
}

func parseValidated(input: Tokens): Tokens {
    let (decl, pos) = parseDeclFragment(input)
    if (!(decl is FuncDecl)) {
        throw Exception("Validated macro only using for func")
    }

    let funcInfo = FuncInfo((decl as FuncDecl).getOrThrow())
    funcInfo.addFuncBody()
    FieldInfoCache.clear()
    funcInfo.decl.toTokens() + Token(TokenKind.NL) + input[pos..]
}
