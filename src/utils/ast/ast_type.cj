/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.utils.ast

import std.ast.*

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
            case x: PrefixType => parsePrefixType(input, x)
            case x: RefType => parseRefType(input, x)
            case _ => diagReport(DiagReportLevel.ERROR, input, "unsuported type",
                "param ref type must be ${supportTypes}")
        }
    }

    private func parsePrefixType(input: Tokens, x: PrefixType): Unit {
        // Option类型
        vtype = Token(TokenKind.IDENTIFIER, "Option")
        parseBaseType(input, x.baseType)
    }

    private func parseBaseType(input: Tokens, gType: TypeNode): Unit {
        match (gType) {
            case t: RefType =>
                genericType = t.identifier
                if (genericType.value == "Int" || genericType.value == "UInt") {
                    genericIsPrimitive = true
                }
            case t: PrimitiveType =>
                genericType = t.keyword
                genericIsPrimitive = true
            case _ => diagReport(DiagReportLevel.ERROR, input, "unsuported type",
                "param ref type must be ${supportTypes}")
        }
    }

    private func parseRefType(input: Tokens, x: RefType): Unit {
        if (x.typeArguments.size != 1 && x.typeArguments.size != 0) {
            diagReport(DiagReportLevel.ERROR, input, "unsuported type", "param ref type must be ${supportTypes}")
            return
        }

        vtype = x.identifier
        if (vtype.value == "Int" || vtype.value == "UInt") {
            isPrimitive = true
            return
        }

        if (x.typeArguments.size == 1) {
            parseBaseType(input, x.typeArguments[0])
        }
    }

    protected func isOptionStringType(): Bool {
        vtype.value == "Option" && genericType.value == "String"
    }

    protected func isStringType(): Bool {
        vtype.value == "String" && genericType.value == ""
    }
}
