/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

macro package cjoy.bind.macros

import std.ast.*
import std.collection.{ArrayList, map, collectArrayList}
import cjoy.utils.ast.{ClassGenentor, joinTokens}

class BindClassInfo {
    let classId: Token
    let fields: ArrayList<BindFieldGenerator>
    let macroName: String

    init(macroName: String, classId: Token, vars: ArrayList<VarDecl>) {
        this.macroName = macroName
        this.classId = classId
        this.fields = ArrayList<BindFieldGenerator>()
        for (vd in vars) {
            this.fields.add(BindInfoCache.create(vd))
        }
    }

    func genBindFunc(): Tokens {
        let params: Tokens = joinTokens(
            fields |> map {
                f: BindFieldGenerator => f.genBindTokens()
            } |> collectArrayList,
            Token(TokenKind.COMMA)
        )

        quote(
            public static func bind(source: JoyBindSource, _: String, _: ?String, _: ?String): ?$(classId) {
                $classId($params)
            }
        )
    }

    public static func parse(marcroName: String, input: Tokens): Tokens {
        let (decl, pos) = parseDeclFragment(input)
        let classGen = ClassGenentor("Bind", decl)
        
        let ident = decl.identifier
        let classInfo = BindClassInfo(marcroName, ident, classGen.variables)
        let bindTokens = classInfo.genBindFunc()
        let supperTokens = quote(JoyBindable<$(classInfo.classId)>)
        let tokens =  classGen.genTokens(supperTokens, bindTokens)

        BindInfoCache.clear()
        tokens + Token(TokenKind.NL) + input[pos..]
    }
}
