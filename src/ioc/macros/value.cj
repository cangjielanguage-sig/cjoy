/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

macro package cjoy.ioc.macros

import std.ast.*
import cjoy.utils.{MapToString, MapListGetFunc}
import cjoy.utils.ast.TypeNodeInfo

/**
 * @throws Exception
 */
func parseVaue(attr: Tokens, input: Tokens): Tokens {
    if (!insideParentContext("Controller") && !insideParentContext("Component")) {
        throw Exception("@Value macro must in @Controller or @Component")
    }

    let (decl, pos) = parseDeclFragment(input)
    let tokens = match (decl) {
        case vd: VarDecl => processVarDecl(vd, attr, input)
        case _ =>
            diagReport(DiagReportLevel.ERROR, input, "@Value macro only using for the var field of struct or class", "")
            throw Exception("@Value macro only using for the var field of struct or class")
    }
    tokens + input[pos..]
}

/**
 * @throws Exception
 */
private func processVarDecl(vd: VarDecl, attr: Tokens, input: Tokens): Tokens {
    if (attr.size == 0) {
        throw Exception("@Value macro should container one string attribute")
    }

    let supportTypes = "String, PrimitiveType, Opition<String>, Opition<PrimitiveType>"
    let typeNode = TypeNodeInfo(supportTypes)
    typeNode.parse(input, vd.declType)
    if (typeNode.genericType != Token()) {
        if (typeNode.vtype.value != "Option" && !(typeNode.genericIsPrimitive || typeNode.genericType.value == "String")) {
            throw Exception("@Value macro only suport types ${supportTypes} ")
        }
    } else {
        if (!(typeNode.isPrimitive || typeNode.vtype.value == "String")) {
            throw Exception("@Value macro only suport types ${supportTypes} ")
        }
    }

    let cfgExpr = attr[0]
    let tokens = if (typeNode.genericIsPrimitive) {
        quote($(typeNode.genericType).tryParse(ConfigManager.INSTANCE.resolve($cfgExpr)))
    } else if (typeNode.isPrimitive) {
        quote($(typeNode.vtype).parse(ConfigManager.INSTANCE.resolve($cfgExpr)))
    } else {
        quote(ConfigManager.INSTANCE.resolve($cfgExpr))
    }
    vd.assign = Token(TokenKind.ASSIGN)
    vd.expr = parseExpr(tokens)
    vd.toTokens()
}
