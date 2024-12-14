package cjoy.json.generate

import std.ast.*
import std.collection.HashMap

class JsonInfoCache {
    static let FIELD_INFOS: HashMap<String, JsonFieldInfo> = HashMap()

    public static func clear(): Unit{
        FIELD_INFOS.clear()
    }

    public static func addCache(vid: String, info: JsonFieldInfo): Unit {
        FIELD_INFOS.put(vid, info)
    }

    public static func create(vd: VarDecl) : JsonFieldGenerator {
        let vtypeTokens = vd.declType.toTokens()
        let vtypeName = vtypeTokens[0].value
        let fieldInfo = FIELD_INFOS.get(vd.identifier.value).getOrDefault({=> JsonFieldInfo(vd.identifier.value)})
        match (vtypeName) {
            case "String" => StringJsonFieldGenerator(vd, fieldInfo)
            case "Option" => OptionJsonFieldGenerator(vd, fieldInfo)
            case "Rune" => RuneJsonFieldGenerator(vd, fieldInfo)
            case "DateTime" => DateTimeJsonFieldGenerator(vd, fieldInfo)
            case _ => JsonFieldGenerator(vd, fieldInfo)
        }
    }
}