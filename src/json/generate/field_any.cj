/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.json.generate

import std.ast.*

class AnyJsonFieldGenerator <: JsonFieldGenerator {
    init(vd: VarDecl, info: JsonFieldInfo) {
        super(vd, info)
    }

    public override func genSerializeTokens(): Tokens {
        quote(match ($(varId)) {
            case obj: JsonSerializable => writer.writeName($(info.jsonKeyName())).writeValue(obj)
            case _ => ()
        }
        )
    }

    public override func genDeserializeTokens(): Tokens {
        if (info.raw) {
            quote(case $(info.jsonKeyName()) => obj.$(varId) = reader.readValueBytes()
            )
        } else {
            quote(case $(info.jsonKeyName()) => obj.$(varId) = JsonTool.fromJsonToAny(reader)
            )
        }
    }
}