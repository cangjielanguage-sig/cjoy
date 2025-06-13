/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

macro package cjoy.json

import std.ast.Tokens
import cjoy.json.generate.{JsonClassInfo, JsonFieldInfo, parseJsonable}

// reimport the dependent
public import cjoy.json.api.{JsonTool, JsonBox, JsonSchemaInfo, JsonSchemaType, ToJsonSchema}
public import std.time.DateTime
public import std.io.ByteBuffer
public import stdx.encoding.json.stream.{JsonDeserializable, JsonSerializable, JsonWriter, JsonReader, JsonToken}

/**
 * Json macro is used for annotation the object of class or struct can be serialized and deserialized.
 */
public macro Json(input: Tokens): Tokens {
    JsonClassInfo.parse(None, input)
}

/**
 * Json macro is used for annotation the object of class or struct can be serialized and deserialized.
 *
 * @attribute description: the description of class or struct
 */
public macro Json(attr: Tokens, input: Tokens): Tokens {
    JsonClassInfo.parse(attr, input)
}

/**
 * JsonField macro is used for annotation the field of class or struct.
 *
 * @attribute name：the key new name of json
 * @attribute omitempty: vaule is true/false, whether to ignore empty strings or Options.None
 * @attribute ignore：vaule is true/false, whether to ignore the field
 * @attribute timeformat：the format for Datetime field
 * @attribute raw：vaule is true/false, deserialize to orgin raw array bytes
 * @attribute description: the description of field
 * @attribute required：vaule is true/false, required is json schame
 * @attribute schame：the full schema of field
 */
public macro JsonField(attr: Tokens, input: Tokens): Tokens {
    JsonFieldInfo.parse(attr, input)
    input
}

/**
 * Convert it to JsonSerializable obj, then you can JsonTool.toJson(obj) serialize it to json string
 */
public macro Jsonable(input: Tokens): Tokens {
    parseJsonable(input)
}
