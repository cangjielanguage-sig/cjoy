package cjoy.json.generate

import std.ast.*
import std.collection.Map

class OptionJsonFieldGenerator <: JsonFieldGenerator {
   init(vd: VarDecl, info: JsonFieldInfo) { 
      super(vd, info)
   }

   public override func genSerializeTokens(): Tokens {
      if (info.omitempty) {
         return quote(
            if (let Some(_) <- $(varId) ) {
               writer.writeName($(info.jsonKeyName())).writeValue($(varId))
            }
         )
      }
      super.genSerializeTokens()
   }  
}