/*
 * Copyright (c) lanlingx 2024-present. All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

macro package cjoy.json

import std.ast.Tokens
import cjoy.json.generate.{JsonClassInfo, JsonFieldInfo}

// reimport the dependent
public import cjoy.json.utils.*
public import std.time.{DateTime, DateTimeFormat}
public import std.io.ByteBuffer
public import encoding.json.stream.*

/**
 * Json macro is used for annotation the object of class or struct can be serialized and deserialized.
 */
public macro Json(input: Tokens): Tokens {
    JsonClassInfo.parse(input)
}

/**
 * JsonField macro is used for annotation the field of class or struct.
 *
 * @attribute name：the key new name of json
 * @attribute omitempty: vaule is true/false, whether to ignore empty strings or Options.None
 * @attribute ignore：vaule is true/false, whether to ignore the field
 * @attribute timeformat：the format for Datetime field
 */
public macro JsonField(attr: Tokens, input: Tokens): Tokens {
    JsonFieldInfo.parse(attr, input)
}
