/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

macro package cjoy.ioc.macros

import std.ast.*
import cjoy.utils.ast.TypeNodeInfo

func parseValue(attr: Tokens, input: Tokens): Tokens {
    if (!insideParentContext("Controller") && !insideParentContext("Component")) {
        diagReport(DiagReportLevel.ERROR, attr, "@Value macro must be wrappered by @Controller or @Component", "")
        return Tokens()
    }

    let (decl, pos) = parseDeclFragment(input)
    let tokens = match (decl) {
        case vd: VarDecl => processVarDecl(vd, attr, input)
        case _ =>
            diagReport(DiagReportLevel.ERROR, attr, "@Value macro only using for the var field of struct or class", "")
            Tokens()
    }
    tokens + input[pos..]
}

private func processVarDecl(vd: VarDecl, attr: Tokens, input: Tokens): Tokens {
    if (attr.size == 0) {
        diagReport(DiagReportLevel.ERROR, attr, "@Value macro should container one string attribute",
            ##"should like @Value[#"${configName:defaultValue}"#]"##)
        return Tokens()
    }

    let supportTypes = "String, PrimitiveType, Opition<String>, Opition<PrimitiveType>"
    let typeNode = TypeNodeInfo(supportTypes)
    typeNode.parse(input, vd.declType)
    if (typeNode.genericType != Token()) {
        if (typeNode.vtype.value != "Option" && !(typeNode.genericIsPrimitive || typeNode.genericType.value == "String")) {
            diagReport(DiagReportLevel.ERROR, input, "@Value macro only suport types ${supportTypes}", "")
            return Tokens()
        }
    } else {
        if (!(typeNode.isPrimitive || typeNode.vtype.value == "String")) {
            diagReport(DiagReportLevel.ERROR, input, "@Value macro only suport types ${supportTypes}", "")
            return Tokens()
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
