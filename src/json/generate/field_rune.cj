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
}