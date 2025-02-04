/*
 * Copyright (c) lanlingx 2024-present. All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.json.generate

import std.ast.*
import std.collection.Map

class DateTimeJsonFieldGenerator <: JsonFieldGenerator {
    init(vd: VarDecl, info: JsonFieldInfo) {
        super(vd, info)
    }

    public override func genSerializeTokens(): Tokens {
        if (info.timeformat != "") {
            return quote(
                writer.writeName($(info.jsonKeyName())).writeValue($(varId).toString(DateTimeFormat.of($(info.timeformat))))
         )
        }
        quote(writer.writeName($(info.jsonKeyName())).writeValue($(varId).toString())
      )
    }

    public override func genDeserializeTokens(): Tokens {
        if (info.timeformat != "") {
            return quote(
                case $(info.jsonKeyName()) => obj.$(varId) = DateTime.parse(reader.readValue<String>(), $(info.timeformat))
         )
        }
        quote(case $(info.jsonKeyName()) => obj.$(varId) = DateTime.parse(reader.readValue<String>())
      )
    }
}
