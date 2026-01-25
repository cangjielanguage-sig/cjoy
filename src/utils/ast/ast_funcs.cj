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
import cjoy.utils.{MapToString, MapListGetFunc}

/**
 * checks attribute names against list of valid attribute names
 *
 * @param attrNames: array of attribute names to check
 * @param validAttrNames: array of valid attribute names
 * @return: tuple of (is valid, error message if invalid)
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
 * parses macro attributes with validation
 *
 * @param tokens: tokens to parse
 * @param validKeys: list of valid attribute keys
 * @param macroName: name of the macro for error messages
 * @return: parsed attribute map
 * @throws if attributes are invalid
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
 * joins multiple token lists with a separator token
 *
 * @param tokensList: list of token lists to join
 * @param separator: token to insert between lists
 * @return: joined tokens
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
 * gets default value tokens from a variable declaration
 *
 * @param varDecl: the variable declaration
 * @return: tokens representing default value, or type-based default
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
 * gets default value tokens based on type
 *
 * @param typeNode: the type node
 * @return: tokens representing default value based on type, or None
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
 * gets generic type parameter tokens from a declaration
 *
 * @param decl: the declaration
 * @return: generic type parameter tokens
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
