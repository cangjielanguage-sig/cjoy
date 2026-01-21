/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

macro package cjoy.validation.macros

import std.ast.*
import std.collection.{ArrayList, map, collectArrayList}
import cjoy.utils.ast.{ClassGenentor, joinTokens}

class ValidClassInfo {
    let classId: Token
    let fields: ArrayList<FieldInfo>

    init(classId: Token, vars: ArrayList<VarDecl>) {
        this.classId = classId
        this.fields = ArrayList<FieldInfo>()
        for (vd in vars) {
            let name = vd.identifier.value
            this.fields.add(FieldInfoCache.findByName(name) ?? FieldInfo(vd.identifier, false))
        }
    }

    func genVaidateFunc(): Tokens {
        let arr = fields |> map {f => f.genValidateTokens()} |> collectArrayList
        let tokens = joinTokens(arr, Token(TokenKind.NL))
        quote(
            public func validate(field: String, nestedValid: Bool, constraints: Array<JoyConstraint>): Unit {
                $(tokens)
            }
        )
    }

    public static func parse(input: Tokens): Tokens {
        let decl: Decl = parseDecl(input)
        let classGen = ClassGenentor("Valid", decl)
        if (!(decl is StructDecl) && !(decl is ClassDecl)) {
            diagReport(DiagReportLevel.ERROR, input, "@Valid macro only using for struct or class", "")
            return Tokens()
        }

        let ident = decl.identifier
        let classInfo = ValidClassInfo(ident, classGen.variables)

        let validTokens = classInfo.genVaidateFunc()
        FieldInfoCache.clear()

        quote(
            extend $(classInfo.classId) <: JoyValidatable {
                $(validTokens)
            }
        )
    }
}
