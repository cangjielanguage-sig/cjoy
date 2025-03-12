/*
 * Copyright (c) lanlingx 2025-present. All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.bind.generate

import std.ast.*
import std.collection.ArrayList
import cjoy.utils.ClassVarDeclVisitor

public class BindClassInfo {
    let classId: Token
    let fields: ArrayList<BindFieldGenerator>
    let macroName: String

    init(macroName: String, classId: Token, vars: Array<VarDecl>) {
        this.macroName = macroName
        this.classId = classId
        this.fields = ArrayList<BindFieldGenerator>()
        for (vd in vars) {
            this.fields.add(BindInfoCache.create(vd, macroName))
        }
    }

    func genVarTokens(): Tokens {
        match (macroName) {
            case "PostFormBind" => quote(let form_ = request.form
            )
            case "QueryBind" => quote(let form_ = request.url.queryForm
            )
            case "HeaderBind" => quote(let headers_ = request.headers
            )
            case _ => throw Exception("unsupport Macro ${macroName}")
        }
    }

    func genBindFunc(): Tokens {
        var bindTokens = Tokens()
        for (f in this.fields) {
            if (f.info.keyName() == "") {
                continue
            }
            bindTokens += f.genBindTokens()
        }
        quote(
            public static func bind(request: HttpRequest): $(classId) {
                var obj = $(classId)()
                $(genVarTokens())
                $(bindTokens)
                obj
            }
        )
    }

    public static func parse(marcroName: String, input: Tokens): Tokens {
        let decl: Decl = parseDecl(input)
        if (!(decl is StructDecl) && !(decl is ClassDecl)) {
            throw Exception("Bind macro only using for struct or class")
        }

        let ident = decl.identifier
        let visitor = ClassVarDeclVisitor()
        decl.traverse(visitor)
        let vars = visitor.allVarDecls()
        let classInfo = BindClassInfo(marcroName, ident, vars)

        let bindTokens = classInfo.genBindFunc()
        BindInfoCache.clear()

        quote(
            extend $(classInfo.classId) <: JoyBindable<$(classInfo.classId)> {
                $(bindTokens)
            }
        )
    }
}
