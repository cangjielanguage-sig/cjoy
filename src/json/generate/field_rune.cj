/*
 * Copyright (c) lanlingx 2024-2024. All rights resvered.
 */

package cjoy.json.generate

import std.ast.*
import std.collection.Map

class RuneJsonFieldGenerator <: JsonFieldGenerator {
    init(vd: VarDecl, info: JsonFieldInfo) {
        super(vd, info)
    }

    public override func genSerializeTokens(): Tokens {
        quote(writer.writeName($(info.jsonKeyName())).writeValue($(varId).toString())
      )
    }

    public override func genDeserializeTokens(): Tokens {
        quote(case $(info.jsonKeyName()) => obj.$(varId) = readRune(reader)
      )
    }

    public override func genAddonFuncTokens(): Tokens {
        quote(
            private static func readRune(reader: JsonReader): Rune {
                let str = reader.readValue<String>()
                if (str.toRuneArray().size != 1) {
                    throw Exception("the json value is not Rune")
                }
                Rune(str[0])
            }
        )
    }
}
