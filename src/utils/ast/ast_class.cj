/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.utils.ast

import std.ast.*
import std.collection.{ArrayList, map, any, collectArrayList}

/**
 * class/struct generator for macro code generation
 * extracts and analyzes class/struct member information
 */
protected class ClassGenentor {
    public let typeDecl: Decl
    public let superTypes: ArrayList<TypeNode>
    public let body: Body
    public let isClass: Bool
    public let isOpen: Bool
    public let variables: ArrayList<VarDecl>
    public let constructors: ArrayList<FuncDecl>
    public let funcs: ArrayList<FuncDecl>

    /**
     * creates a new ClassGenentor from a class/struct declaration
     *
     * @param macroName: name of the macro using this generator
     * @param typeDecl: the class or struct declaration
     * @throws if typeDecl is not a ClassDecl or StructDecl
     */
    public init(macroName: String, typeDecl: Decl) {
        this.typeDecl = typeDecl
        this.isOpen = typeDecl.modifiers |> any {t => t.keyword.value == "open"}
        match (typeDecl) {
            case vd: ClassDecl =>
                isClass = true
                superTypes = vd.superTypes
                body = vd.body
                this.variables = getMemberVariables(vd.body)
                this.funcs = getMemberFuncs(vd.body)
                this.constructors = getConstructors(typeDecl.identifier.value, body)
            case vd: StructDecl =>
                isClass = false
                superTypes = vd.superTypes
                body = vd.body
                this.variables = getMemberVariables(vd.body)
                this.funcs = getMemberFuncs(vd.body)
                this.constructors = getConstructors(typeDecl.identifier.value, body)
            case _ =>
                diagReport(DiagReportLevel.ERROR, typeDecl.toTokens(),
                    "@${macroName} macro only using for struct or class", "")
                throw Exception("${macroName} macro only using for struct or class")
        }
    }

    /**
     * extracts non-static member variables from body
     *
     * @param body: the class/struct body
     * @return: list of non-static variable declarations
     */
    private static func getMemberVariables(body: Body): ArrayList<VarDecl> {
        let result = ArrayList<VarDecl>()
        for (decl in body.decls) {
            match (decl) {
                case vd: VarDecl =>
                    let isStatic = decl.modifiers |> any {t => t.keyword.kind == TokenKind.STATIC}
                    if (!isStatic) {
                        result.add(vd)
                    }
                case _ => ()
            }
        }
        return result
    }

    /**
     * extracts constructor functions from body
     *
     * @param typeName: name of the class/struct
     * @param body: the class/struct body
     * @return: list of constructor declarations (init or type-named)
     */
    private static func getConstructors(typeName: String, body: Body): ArrayList<FuncDecl> {
        let result = ArrayList<FuncDecl>()
        for (decl in body.decls) {
            match (decl) {
                case vd: FuncDecl =>
                    let isStatic = decl.modifiers |> any {t => t.keyword.kind == TokenKind.STATIC}
                    if (!isStatic && (vd.identifier.value == "init" || vd.identifier.value == typeName)) {
                        result.add(vd)
                    }
                case _ => ()
            }
        }
        return result
    }

    /**
     * extracts non-static member functions from body
     *
     * @param body: the class/struct body
     * @return: list of non-static function declarations
     */
    private static func getMemberFuncs(body: Body): ArrayList<FuncDecl> {
        let result = ArrayList<FuncDecl>()
        for (decl in body.decls) {
            match (decl) {
                case vd: FuncDecl =>
                    let isStatic = decl.modifiers |> any {t => t.keyword.kind == TokenKind.STATIC}
                    if (!isStatic) {
                        result.add(vd)
                    }
                case _ => ()
            }
        }
        return result
    }

    /**
     * builds constructor function tokens from member variables
     *
     * @return: constructor function tokens
     */
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

        let ctorBody: Tokens = joinTokens(
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
                $ctorBody
            }
        )
    }

    /**
     * generates class/struct declaration tokens
     *
     * @param newSupper: additional supertype tokens to add
     * @param funcs: function tokens to add to body
     * @param createCtor: if true, auto-generate constructor from member variables
     * @return: complete class/struct declaration tokens
     */
    public func genTokens(newSupper: Tokens, funcs: Tokens, createCtor!: Bool = true): Tokens {
        let ctor = if (createCtor) {
            buildCtorFunc()
        } else {
            Tokens()
        }
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
            quote($(superTypes.toTokens()) & $(newSupper.toTokens()))
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
