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

        match (vtypeName) {
            case "String" => StringJsonFieldGenerator(vd, FIELD_INFOS)
            case "Option" => OptionJsonFieldGenerator(vd, FIELD_INFOS)
            case "Rune" => RuneJsonFieldGenerator(vd, FIELD_INFOS)
            case "DateTime" => DateTimeJsonFieldGenerator(vd, FIELD_INFOS)
            case _ => JsonFieldGenerator(vd, FIELD_INFOS)
        }
    }
}