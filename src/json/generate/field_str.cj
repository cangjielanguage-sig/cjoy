package cjoy.json.generate

import std.ast.*
import std.collection.Map

class StringJsonFieldGenerator <: JsonFieldGenerator {
   init(vd: VarDecl, fieldInfos: Map<String, JsonFieldInfo>) { 
      super(vd, fieldInfos)
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