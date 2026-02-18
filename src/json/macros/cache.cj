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

class JsonInfoCache {
    static let FIELD_INFOS: HashMap<String, JsonFieldInfo> = HashMap()

    /**
     * 清除所有缓存的字段信息
     */
    public static func clear(): Unit {
        FIELD_INFOS.clear()
    }

    /**
     * 添加字段信息到缓存
     *
     * @param vid: 变量标识符
     * @param info: 字段信息
     */
    public static func addCache(vid: String, info: JsonFieldInfo): Unit {
        FIELD_INFOS.add(vid, info)
    }

    /**
     * 从变量声明创建 json 字段生成器
     *
     * @param vd: 变量声明
     * @return: json 字段生成器
     */
    public static func create(vd: VarDecl): JsonFieldGenerator {
        let vtypeTokens = vd.declType.toTokens()
        let vtypeName = vtypeTokens[0].value
        let fieldInfo = FIELD_INFOS.get(vd.identifier.value) ?? JsonFieldInfo(vd.identifier.value)
        match (vtypeName) {
            case "String" => StringJsonFieldGenerator(vd, fieldInfo)
            case "Option" | "?" => OptionJsonFieldGenerator(vd, fieldInfo)
            case "Rune" => RuneJsonFieldGenerator(vd, fieldInfo)
            case "DateTime" => DateTimeJsonFieldGenerator(vd, fieldInfo)
            case "Any" => AnyJsonFieldGenerator(vd, fieldInfo)
            case _ => JsonFieldGenerator(vd, fieldInfo)
        }
    }
}
