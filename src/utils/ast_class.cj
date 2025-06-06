/*
 * Copyright (c) lanlingx 2025-present. All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.utils

import std.ast.*
import std.collection.{ArrayList, map, collectArrayList}

protected class ClassGenentor {
    public let typeDecl: Decl
    public let superTypes: ArrayList<TypeNode>
    public let body: Body
    public let isClass: Bool
    public let variables: ArrayList<VarDecl>

    public init(macroName: String, typeDecl: Decl) {
        this.typeDecl = typeDecl
        match (typeDecl) {
            case vd: ClassDecl =>
                isClass = true
                superTypes = vd.superTypes
                body = vd.body
                this.variables = getMemberVariables(vd.body)
            case vd: StructDecl =>
                isClass = false
                superTypes = vd.superTypes
                body = vd.body
                this.variables = getMemberVariables(vd.body)
            case _ => throw Exception("${macroName} macro only using for struct or class")
        }
    }

    private static func getMemberVariables(body: Body): ArrayList<VarDecl> {
        let result = ArrayList<VarDecl>()
        for (decl in body.decls) {
            match (decl) {
                case vd: VarDecl => result.add(vd)
                case _ => ()
            }
        }
        return result
    }

    func buildCtorFunc(): Tokens {
        let params = ArrayList<Tokens>()
        let paramsWithDefVal = ArrayList<Tokens>()

        for (varDecl in variables) {
            let v = Token(TokenKind.IDENTIFIER, varDecl.identifier.value)
            let type_ = varDecl.declType.toTokens()
            try {
                let expr = varDecl.expr
                paramsWithDefVal.add(quote($v!: $type_ = $expr))
            } catch (_: ASTException) {
                if (let Some(x) <- getDefValueOfType(varDecl.declType)) {
                    paramsWithDefVal.add(quote($v!: $type_ = $x))
                } else {
                    params.add(quote($v!: $type_))
                }
            }
        }

        params.add(all: paramsWithDefVal)
        let comma = Token(TokenKind.COMMA)

        let body: Tokens = joinTokens(
            variables |>
                map {
                varDecl: VarDecl =>
                let id = Token(TokenKind.IDENTIFIER, varDecl.identifier.value)
                return quote(this.$id = $id)
            } |> collectArrayList,
            Token(TokenKind.NL)
        )
        return quote(
            public init($(joinTokens(params, comma))) {
                $body
            }
        )
    }

    public func genTokens(newSupper: Tokens, funcs: Tokens): Tokens {
        let ctor = buildCtorFunc()
        let genericTypeParam = getGenericTypeParamsTokens(typeDecl)
        let genericConstraint = getGenericConstraintsTokens(typeDecl)

        let classOrStruct = if (isClass) {
            Token(TokenKind.CLASS)
        } else {
            Token(TokenKind.STRUCT)
        }

        let allSuperTypes = if (superTypes.isEmpty()) {
            newSupper
        } else {
            quote($(newSupper.toTokens()) & $(superTypes.toTokens()))
        }

        return quote(
            $(typeDecl.modifiers) $classOrStruct $(typeDecl.identifier) $genericTypeParam <: $allSuperTypes $genericConstraint {
                $(body.decls)
                $ctor
                $funcs
            }
        )
    }
}