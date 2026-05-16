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
import std.collection.{ArrayList, HashSet}
import cjoy.utils.{MapToString}

/**
 * 根据有效属性名称列表检查属性名称
 *
 * @param attrNames: 要检查的属性名称数组
 * @param validAttrNames: 有效属性名称数组
 * @return: (是否有效, 如果无效的错误消息) 的元组
 */
func checkAttr(attrNames: Array<String>, validAttrNames: Array<String>): (Bool, String) {
    let names = HashSet(attrNames)
    if (names.size != attrNames.size) {
        return (false, "duplicated attributes")
    }
    names.remove(all: validAttrNames)
    if (!names.isEmpty()) {
        return (false, "invalid attributes ${names}")
    }
    return (true, "ok")
}

/**
 * 解析带有验证的宏属性
 *
 * @param tokens: 要解析的令牌
 * @param validKeys: 有效属性键列表
 * @param macroName: 用于错误消息的宏名称
 * @return: 解析后的属性映射
 * @throws 如果属性无效
 */
protected func parserAttrs(tokens: Tokens, validKeys!: Array<String>, macroName!: String): MapToString {
    let visitor = TokenStrValueVisitor()
    let parser = TokenParser(visitor, tokens)
    let resust = (parser.parse() as MapToString).getOrThrow()
    let (status, info) = checkAttr(resust.keys().toArray(), validKeys)
    if (!status) {
        diagReport(DiagReportLevel.ERROR, tokens, "@${macroName} has invalid attributes. ${info}",
            "valid attribue list: ${validKeys}")
    }
    resust
}

/**
 * 使用分隔符令牌连接多个令牌列表
 *
 * @param tokensList: 要连接的令牌列表
 * @param separator: 在列表之间插入的令牌
 * @return: 连接的令牌
 */
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

/**
 * 从变量声明获取默认值令牌
 *
 * @param varDecl: 变量声明
 * @return: 表示默认值的令牌，或基于类型的默认值
 */
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

/**
 * 基于类型获取默认值令牌
 *
 * @param typeNode: 类型节点
 * @return: 基于类型的默认值令牌，或 None
 */
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
        case _: PrefixType => return quote(None)
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

/**
 * 从声明获取泛型类型参数令牌
 *
 * @param decl: 声明
 * @return: 泛型类型参数令牌
 */
protected func getGenericTypeParamsTokens(decl: Decl): Tokens {
    try {
        let generic = decl.genericParam
        return generic.toTokens()
    } catch (_: ASTException) {
        return Tokens()
    }
}

/**
 * gets generic constraint tokens from a declaration
 *
 * @param decl: the declaration
 * @return: concatenated generic constraint tokens
 */
protected func getGenericConstraintsTokens(decl: Decl): Tokens {
    let tokens = Tokens()
    for (c in decl.genericConstraint) {
        tokens.append(c.toTokens())
    }
    return tokens
}
