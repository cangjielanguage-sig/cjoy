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
import cjoy.utils.ast.parserAttrs

/**
 * @throws Exception
 */
func parseAutowired(attr: ?Tokens, input: Tokens): Unit {
    if (!insideParentContext("Controller") && !insideParentContext("Component")) {
        throw Exception("@Value macro must in @Controller or @Component")
    }
    try {
        let funcParam = FuncParam(input)
        let paramName = funcParam.identifier
        if (attr.isSome()) {
            let map: MapToString = parserAttrs(attr.getOrThrow(), validKeys: ["name"], macroName: "Autowired")
            setItem(paramName.value + ".name", map.getString("name") ?? "")
        }
    } catch (ex: Exception) {
        throw Exception("@Autowired macro only using for init function parameter")
    }
}
