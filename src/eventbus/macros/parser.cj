/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

macro package cjoy.eventbus.macros

import std.ast.*
import std.collection.*
import cjoy.utils.{parserAttrs, MapToString, MapListGetFunc, randStr}

class FuncInfo {
    let macroName: String

    let decl: FuncDecl

    var name: String = ""
    var pattern: String = ""
    var priority: Int = 0

    init(macroName: String, decl: FuncDecl) {
        this.macroName = macroName
        this.decl = decl
    }

    func parseAttr(attr: Tokens): Unit {
        let map: MapToString = parserAttrs(attr, validKeys: ["name", "pattern", "priority"], macroName: macroName)
        this.name = map.getString("name") ?? ""
        this.pattern = map.getString("pattern") ?? ""
        this.priority = map.getInt("priority") ?? 0
    }

    func getName(): String {
        if (name.isEmpty()) {
            return decl.identifier.value
        }
        name
    }

    func genTokens(): Tokens {
        quote(
            let _: Unit = LocalEventBus.INSTANCE.onEvent($pattern, $(getName()), $(decl.identifier), $priority)
        )
    }

    func sendMessage(): Tokens {
        setItem("eventbus.name", getName())
        setItem("eventbus.pattern", pattern)
        setItem("eventbus.priority", priority)
        setItem("eventbus.funcName", decl.identifier.toTokens())
        Tokens()
    }
}

/**
 * throws Exception
 */
func parseFunc(macroName: String, attr: Tokens, input: Tokens): Tokens {
    let decl = parseDecl(input)
    if (!(decl is FuncDecl)) {
        throw Exception("${macroName} macro only using for func")
    }

    let funcInfo = FuncInfo(macroName, (decl as FuncDecl).getOrThrow())
    funcInfo.parseAttr(attr)
    let tokens = if (insideParentContext("Controller") || insideParentContext("Component")) {
        funcInfo.sendMessage()
    } else {
        funcInfo.genTokens()
    }
    tokens
}
