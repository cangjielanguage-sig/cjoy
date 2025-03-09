/*
 * Copyright (c) lanlingx 2025-present. All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.bind.generate

import std.ast.*
import std.collection.HashMap

class BindInfoCache {
    static let FIELD_INFOS: HashMap<String, BindFieldInfo> = HashMap()

    public static func clear(): Unit {
        FIELD_INFOS.clear()
    }

    public static func addCache(vid: String, info: BindFieldInfo): Unit {
        FIELD_INFOS.add(vid, info)
    }

    public static func create(vd: VarDecl, mtype: String): BindFieldGenerator {
        let fieldInfo = FIELD_INFOS.get(vd.identifier.value).getOrDefault({=> BindFieldInfo(vd)})
        match (mtype) {
            case "QueryBind" => FormBindFieldGenerator(vd.identifier, fieldInfo)
            case "PostFormBind" => FormBindFieldGenerator(vd.identifier, fieldInfo)
            case "HeaderBind" => HeaderBindFieldGenerator(vd.identifier, fieldInfo)
            case _ => BindFieldGenerator(vd.identifier, fieldInfo)
        }
    }
}