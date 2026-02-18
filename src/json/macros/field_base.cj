/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

macro package cjoy.json.macros

import std.ast.*
import std.collection.HashMap
import std.io.ByteBuffer
import stdx.encoding.json.stream.{JsonSerializable, JsonWriter}
import cjoy.utils.{MapToString, MapListGetFunc, converterMap}
import cjoy.utils.ast.parserAttrs

/**
 * 宏处理的 JSON 字段元数据
 * - originName: 原始字段名
 * - newName: 自定义 JSON 键名
 * - ignore: 是否跳过此字段
 * - omitempty: 是否省略空值
 * - timeformat: 日期时间格式字符串
 * - raw: 作为原始字节反序列化
 * - description: schema 的字段描述
 * - required: schema 中字段是否必需
 * - schema: 自定义 schema 字符串
 */
class JsonFieldInfo {
    let originName: String
    var newName: String = ""
    var ignore: Bool = false
    var omitempty: Bool = false
    var timeformat: String = ""
    var raw: Bool = false

    // 
    var description: String = ""
    var required: Bool = true
    var schema: String = ""

    init(name: String) {
        this.originName = name
    }

    func jsonKeyName(): String {
        if (ignore) {
            return ""
        }
        if (newName != "") {
            return newName
        }
        return originName
    }

    func parseAttr(attr: Tokens): Unit {
        let map: MapToString = parserAttrs(attr,
            validKeys: ["name", "ignore", "omitempty", "timeformat", "raw", "description", "required", "schema"],
            macroName: "JsonField")
        this.newName = map.getString("name") ?? ""
        this.ignore = map.getBool("ignore") ?? false
        this.omitempty = map.getBool("omitempty") ?? false
        this.raw = map.getBool("raw") ?? false
        this.timeformat = map.getString("timeformat") ?? ""

        this.description = map.getString("description") ?? ""
        this.required = map.getBool("required") ?? true
        /* the schama like 
        {
            "type": "interger",
            "description": "description"
        }
         */
        this.schema = match (map.getMap("schema")) {
            case Some(val) =>
                let stream = ByteBuffer()
                let writer = JsonWriter(stream)
                let x: HashMap<String, JsonSerializable> = converterMap(val);
                writer.writeValue(x)
                writer.flush()
                String.fromUtf8(stream.bytes())
            case _ => ""
        }
    }

    public static func parse(attr: Tokens, input: Tokens): Unit {
        assertParentContext("Json")
        let varDecl: Decl = parseDecl(input)
        if (!(varDecl is VarDecl)) {
            diagReport(DiagReportLevel.ERROR, input, "JsonField macro only using for the var field of struct or class",
                "")
            throw Exception("JsonField macro only using for the var field of struct or class")
        }
        let varId: String = varDecl.identifier.value

        let info = JsonFieldInfo(varId)
        info.parseAttr(attr)
        JsonInfoCache.addCache(varId, info)
    }
}

/**
 * 为字段生成 JSON 序列化/反序列化令牌的基础类
 *
 * - varId: 字段标识符令牌
 * - varType: 字段类型节点
 * - info: JSON 字段元数据
 * - isOption: 字段类型是否为 Option
 * - notSchema: 字段类型是否没有 schema（Any, HashMap）
 */
open class JsonFieldGenerator {
    protected let varId: Token
    protected let varType: TypeNode
    protected let info: JsonFieldInfo
    private let isOption: Bool
    private let notSchema: Bool

    init(vd: VarDecl, info: JsonFieldInfo) {
        this.varId = vd.identifier
        this.varType = vd.declType
        this.info = info

        let vtypeTokens = varType.toTokens()
        let vtypeName = vtypeTokens[0].value
        this.isOption = vtypeName == "Option" || vtypeName == "?"
        this.notSchema = vtypeName == "Any" || vtypeName == "HashMap"
    }

    public open func genSerializeTokens(): Tokens {
        quote(writer.writeName($(info.jsonKeyName())).writeValue($(varId))
        )
    }

    public open func genDeserializeTokens(): Tokens {
        quote(case $(info.jsonKeyName()) => obj.$(varId) = reader.readValue<$(varType)>()
        )
    }

    public func genSchemaTokens(): Tokens {
        if (info.schema != "") {
            return quote(JsonSchemaInfo($(info.jsonKeyName()), schema: $(info.schema)))
        }

        if (notSchema) {
            return Tokens()
        }

        let required = !isOption && info.required
        quote(JsonSchemaInfo($(info.jsonKeyName()), schemaType:JsonTool.getSchema<$(varType)>(), description:$(info.description), required: $required))
    }
}
