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

/**
 * 用于解析声明参数类型的类型节点信息解析器
 * 用于宏参数类型验证和内省
 *
 * @param supportTypes: 用于错误消息的描述支持类型的字符串
 */
protected class TypeNodeInfo {
    // the type of decl param
    protected var vtype: Token = Token()

    // the type of Array<T>
    protected var genericType: Token = Token()
    protected var genericIsPrimitive: Bool = false

    protected var isPrimitive: Bool = false

    private let supportTypes: String

    /**
     * 创建新的 TypeNodeInfo
     *
     * @param supportTypes: 用于错误消息的描述支持类型的字符串
     */
    public init(supportTypes: String) {
        this.supportTypes = supportTypes
    }

    /**
     * 解析类型节点并提取类型信息
     *
     * @param input: 用于错误报告的令牌
     * @param varType: 要解析的类型节点
     */
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
