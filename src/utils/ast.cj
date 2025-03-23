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

protected func parseKVAttr(attr: Tokens, marcroName: String, cb: (ident: Token, value: Token) -> Unit): Unit {
    if ((attr.size + 1) % 4 != 0) {
        diagReport(DiagReportLevel.ERROR, attr, "${marcroName} attriable should link 'attrname= value'", "")
        throw Exception("${marcroName} attriable should link 'attrname= value'")
    }

    for (idx in 0..attr.size : 4) {
        let ident = attr.get(idx)
        if (ident.kind != TokenKind.IDENTIFIER) {
            diagReport(DiagReportLevel.ERROR, attr,
                "${marcroName} attriable name should be a identitier, but is ${ident.kind}", "")
            throw Exception("${marcroName} attriable name should be a identitier")
        }
        let assign = attr.get(idx + 1)
        if (assign.kind != TokenKind.ASSIGN) {
            diagReport(DiagReportLevel.ERROR, attr, "${marcroName} attriable name should be =, but is ${ident.kind}", ""
            )
            throw Exception("${marcroName} attriable name should be =")
        }

        let value = attr.get(idx + 2)
        cb(ident, value)
    }
}

protected class TypeNodeInfo {
    // the type of decl param
    protected var vtype: Token = Token()

    // the type of Array<T>
    protected var genericType: Token = Token()
    protected var genericIsPrimitive: Bool = false

    protected var isPrimitive: Bool = false

    private let supportTypes: String

    public init(supportTypes: String) {
        this.supportTypes = supportTypes
    }

    protected func parse(input: Tokens, varType: TypeNode): Unit {
        match (varType) {
            case x: PrimitiveType =>
                vtype = x.keyword
                isPrimitive = true
            case x: PrefixType =>
                vtype = Token(TokenKind.IDENTIFIER, "Option")
                let gType = x.baseType
                if (gType is RefType) {
                    genericType = (gType as RefType).getOrThrow().identifier
                    if (genericType.value == "Int" || genericType.value == "UInt") {
                        genericIsPrimitive = true
                    }
                } else if (gType is PrimitiveType) {
                    genericType = (gType as PrimitiveType).getOrThrow().keyword
                    genericIsPrimitive = true
                } else {
                    diagReport(DiagReportLevel.ERROR, input, "unsuported type", "param ref type must be ${supportTypes}"
                    )
                    throw Exception("unsuported type")
                }
            case x: RefType =>
                if (x.typeArguments.size != 1 && x.typeArguments.size != 0) {
                    diagReport(DiagReportLevel.ERROR, input, "unsuported type", "param ref type must be ${supportTypes}"
                    )
                    throw Exception("unsuported type")
                }

                vtype = x.identifier
                if (vtype.value == "Int" || vtype.value == "UInt") {
                    isPrimitive = true
                    return
                }

                if (x.typeArguments.size == 1) {
                    let gType = x.typeArguments[0]
                    if (gType is RefType) {
                        genericType = (gType as RefType).getOrThrow().identifier
                        if (genericType.value == "Int" || genericType.value == "UInt") {
                            genericIsPrimitive = true
                        }
                    } else if (gType is PrimitiveType) {
                        genericType = (gType as PrimitiveType).getOrThrow().keyword
                        genericIsPrimitive = true
                    } else {
                        diagReport(DiagReportLevel.ERROR, input, "unsuported type",
                            "param ref type must be ${supportTypes}")
                        throw Exception("unsuported type")
                    }
                }
            case _ =>
                diagReport(DiagReportLevel.ERROR, input, "unsuported type", "param ref type must be ${supportTypes}")
                throw Exception("unsuported type")
        }
    }

    protected func isOptionStringType(): Bool {
        vtype.value == "Option" && genericType.value == "String"
    }

    protected func isStringType(): Bool {
        vtype.value == "String" && genericType.value == ""
    }
}

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

protected func joinTokens(tokensList: ArrayList<Tokens>, separator: Token): Tokens {
    if (tokensList.isEmpty()) {
        Tokens()
    } else if (tokensList.size == 1) {
        tokensList[0]
    } else {
        var ret = tokensList[0]
        for (i in 1..tokensList.size) {
            ret = ret + separator + tokensList[i]
        }
        ret
    }
}

protected func getDefValueOfType(varDecl: VarDecl): Option<Tokens> {
    try {
        let expr = varDecl.expr
        return expr.toTokens()
    } catch (_: ASTException) {
        if (let Some(x) <- getDefValueOfType(varDecl.declType)) {
            x
        } else {
            None
        }
    }
}

protected func getDefValueOfType(typeNode: TypeNode): Option<Tokens> {
    match (typeNode) {
        case varType: RefType => return match (varType.identifier.value) {
            case "Option" => quote(None)
            case "Array" => quote([])
            case "Int" | "UInt" => quote(0)
            case "ArrayList" => quote(ArrayList())
            case "String" => quote("")
            case _ => Option.None
        }
        case varType: PrefixType => return quote(None)
        case varType: PrimitiveType =>
            if (varType.keyword.value.startsWith("Int")) {
                return quote(0)
            } else if (varType.keyword.value.startsWith("UInt")) {
                return quote(0)
            } else if (varType.keyword.value.startsWith("Float")) {
                return quote(0.0)
            } else if (varType.keyword.value.startsWith("Bool")) {
                return quote(false)
            } else if (varType.keyword.value.startsWith("Rune")) {
                return quote(Rune(b'\0'))
            } else {
                return None
            }
        case _ => return None
    }
}

protected func getGenericTypeParamsTokens(decl: Decl): Tokens {
    try {
        let generic = decl.genericParam
        return generic.toTokens()
    } catch (_: ASTException) {
        return Tokens()
    }
}

protected func getGenericConstraintsTokens(decl: Decl): Tokens {
    let tokens = Tokens()
    for (c in decl.genericConstraint) {
        tokens.append(c.toTokens())
    }
    return tokens
}
