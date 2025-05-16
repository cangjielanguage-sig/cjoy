/*
 * Copyright (c) lanlingx 2025-present. All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.validation.generate

import std.ast.*

public func parseNestedValid(input: Tokens): Unit {
    try {
        let varDecl: Decl = parseDecl(input)
        assertParentContext("Valid")
        match (varDecl) {
            case vd: VarDecl => FieldInfoCache.setNestedValid(vd.identifier, false)
            case _ =>
                diagReport(DiagReportLevel.ERROR, input,
                    "NestedValid macro only using for the var field of struct or class", "")
                throw Exception("NestedValid macro only using for the var field of struct or class")
        }
    } catch (_: Exception) {
        try {
            let funcParam = FuncParam(input)
            FieldInfoCache.setNestedValid(funcParam.identifier, true)
        } catch (ex: Exception) {
            diagReport(DiagReportLevel.ERROR, input, "NestedValid macro only using for the func paramter", ex.message)
            throw Exception("NestedValid macro only using for the func paramter")
        }
    }
}
