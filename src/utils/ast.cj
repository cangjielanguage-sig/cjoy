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

protected class ClassVarDeclVisitor <: Visitor {
    private let varDecls: ArrayList<VarDecl> = ArrayList<VarDecl>()

    public func allVarDecls(): Array<VarDecl> {
        return varDecls.toArray()
    }

    public override func visit(varDecl: VarDecl) {
        varDecls.add(varDecl)
    }

    public override func visit(_: FuncDecl) {
        breakTraverse()
    }
}

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

    protected func isArrayStringType(): Bool {
        vtype.value == "Array" && genericType.value == "String"
    }

    protected func isArrayListStringType(): Bool {
        vtype.value == "ArrayList" && genericType.value == "String"
    }

    protected func isDateTimeType(): Bool {
        vtype.value == "DateTime" && genericType.value == ""
    }

    protected func isOptionDateTimeType(): Bool {
        vtype.value == "Option" && genericType.value == "DateTime"
    }

    protected func isOptionPrimitiveType(): Bool {
        vtype.value == "Option" && genericIsPrimitive
    }
}
