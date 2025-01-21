/*
 * Copyright (c) lanlingx 2024-present. All rights resvered.
 */

package cjoy.json.generate

import std.ast.*
import std.collection.Map

class StringJsonFieldGenerator <: JsonFieldGenerator {
    init(vd: VarDecl, info: JsonFieldInfo) {
        super(vd, info)
    }

    public override func genSerializeTokens(): Tokens {
        if (info.omitempty) {
            return quote(
            if ($(varId) != "") {
               writer.writeName($(info.jsonKeyName())).writeValue($(varId))
            }
         )
        }
        super.genSerializeTokens()
    }
}
