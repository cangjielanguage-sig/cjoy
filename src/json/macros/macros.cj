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

/**
 * Json 宏用于注解类或结构体的对象可以被序列化和反序列化。
 */
public macro Json(input: Tokens): Tokens {
    JsonClassInfo.parse(None, input)
}

/**
 * Json 宏用于注解类或结构体的对象可以被序列化和反序列化。
 *
 * @attribute description: 类或结构体的描述
 */
public macro Json(attr: Tokens, input: Tokens): Tokens {
    JsonClassInfo.parse(attr, input)
}

/**
 * JsonField 宏用于注解类或结构体的字段。
 *
 * @attribute name：json 键的新名称
 * @attribute omitempty: 值为 true/false，是否忽略空字符串或 Options.None
 * @attribute ignore：值为 true/false，是否忽略该字段
 * @attribute timeformat：日期时间字段的格式
 * @attribute raw：值为 true/false，反序列化为原始字节数组
 * @attribute description: 字段的描述
 * @attribute required：值为 true/false，json schema 中是否必需
 * @attribute schema：字段的完整 schema
 */
public macro JsonField(attr: Tokens, input: Tokens): Tokens {
    JsonFieldInfo.parse(attr, input)
    input
}

/**
 * 将其转换为 JsonSerializable 对象，然后可以使用 JsonTool.toJson(obj) 将其序列化为 json 字符串
 */
public macro ToJson(input: Tokens): Tokens {
    parseTojson(input)
}