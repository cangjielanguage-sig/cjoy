/*
 * Copyright (c) lanlingx 2024-2024. All rights resvered.
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
