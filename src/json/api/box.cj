/*
 * Copyright (c) lanlingx 2024-present. All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.json.api

import stdx.encoding.json.stream.{JsonDeserializable, JsonSerializable, JsonWriter, JsonReader}
import std.collection.HashMap

/**
* wrapped JsonSerializable & JsonDeserializable object
*/
public class JsonBox <: JsonSerializable & JsonDeserializable<JsonBox> {
    public var value: Any
    
    public init(v: Any) {
        this.value = v
    }

    public func toJson(writer: JsonWriter): Unit {
        match (value) {
            case obj: JsonSerializable => obj.toJson(writer)
            case _ => ()
        }
    }

    public static func fromJson(reader: JsonReader): JsonBox {
        JsonBox(JsonTool.fromJsonToAny(reader))
    }
}