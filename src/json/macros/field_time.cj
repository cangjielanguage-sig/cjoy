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

class DateTimeJsonFieldGenerator <: JsonFieldGenerator {
    init(vd: VarDecl, info: JsonFieldInfo) {
        super(vd, info)
    }

    public override func genSerializeTokens(): Tokens {
        // ISO8601 不是仓颉 DateTime 格式串，使用默认的 ISO 序列化/反序列化
        if (info.timeformat != "" && info.timeformat != "ISO8601") {
            return quote(
                writer.writeName($(info.jsonKeyName())).writeValue($(varId).format($(info.timeformat)))
         )
        }
        quote(writer.writeName($(info.jsonKeyName())).writeValue($(varId).toString())
      )
    }

    public override func genDeserializeTokens(): Tokens {
        if (info.timeformat != "" && info.timeformat != "ISO8601") {
            return quote(case $(info.jsonKeyName()) => obj.$(varId) = DateTime.parse(reader.readValue<String>(), $(info.timeformat))
            )
        }
        quote(case $(info.jsonKeyName()) => obj.$(varId) = DateTime.parse(reader.readValue<String>())
        )
    }
}
