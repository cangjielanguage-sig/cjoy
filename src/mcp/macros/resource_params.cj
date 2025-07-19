/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

macro package cjoy.mcp.macros

import std.ast.*
import std.collection.*

class ResourceParamInfo <: ParamInfo {
    init(marcroName: String) {
        super(marcroName)
    }

     func genBindVarTokens(): Tokens {
        if (isJoyContext()) {
            if (pid.value == "ctx") {
                Tokens()
            } else {
                quote(let $(pid) = ctx
                )
            }
        } else {
            quote(let $(pid) = $(getType()).bind(ctx.params, $(getName()), $(getDefault())).getOrThrow()
            )
        }
    }
}
