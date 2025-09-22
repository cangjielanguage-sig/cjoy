/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

macro package cjoy.schedule.macros

import std.ast.*
import std.collection.*
import cjoy.utils.{parserAttrs, MapToString, MapListGetFunc, randStr}

class FuncInfo {
    let macroName: String

    let decl: FuncDecl

    var name: String = ""
    var cron: String = ""

    init(macroName: String, decl: FuncDecl) {
        this.macroName = macroName
        this.decl = decl
    }

    func parseAttr(attr: Tokens): Unit {
        let map: MapToString = parserAttrs(attr, validKeys: ["name", "cron"], macroName: macroName)
        this.name = map.getString("name") ?? ""
        this.cron = map.getString("cron") ?? ""
    }

    func getName(): String {
        if (name.isEmpty()) {
            return decl.identifier.value
        }
        name
    }

    func genTokens(): Tokens {
        quote(
            let _: Unit = Crontab.INSTANCE.addJob($(getName()), $cron, $(decl.identifier))
        )
    }
}

func parseFunc(macroName: String, attr: Tokens, input: Tokens): Tokens {
    let decl = parseDecl(input)
    if (!(decl is FuncDecl)) {
        throw Exception("${macroName} macro only using for func")
    }

    let funcInfo = FuncInfo(macroName, (decl as FuncDecl).getOrThrow())
    funcInfo.parseAttr(attr)
    let tokens = funcInfo.genTokens()
    tokens
}