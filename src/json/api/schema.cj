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

import stdx.encoding.json.stream.{JsonSerializable, JsonWriter}
import std.collection.{HashMap, ArrayList}
import std.time.DateTime
import std.math.numeric.{BigInt, Decimal}

public class JsonSchemaInfo <: JsonSerializable {
    public JsonSchemaInfo(
        public let name: String,
        public let schemaType!: JsonSchemaType = JsonSchemaType.Str,
        public let description!: String = "",
        public let required!: Bool = true,
        public let schema!: String = ""
    ) {}

    public func toJson(writer: JsonWriter): Unit {
        if (schema != "") {
            let obj = JsonTool.fromJsonToAny(schema)
            writer.startObject()
            JsonTool.write(writer, obj)
            writer.endObject()
            return
        }

        //
        writer.startObject()
        schemaType.toJson(writer)
        if (this.description != "") {
            writer.writeName("description").writeValue(description)
        }
        writer.endObject()
    }
}

public enum JsonSchemaType <: JsonSerializable {
    | Str
    | Int
    | Number
    | Boolean
    | Arr(JsonSchemaType)
    | Obj(Array<JsonSchemaInfo>)

    public func toJson(writer: JsonWriter): Unit {
        match (this) {
            case Str => writer.writeName("type").writeValue("string")
            case Int => writer.writeName("type").writeValue("integer")
            case Number => writer.writeName("type").writeValue("number")
            case Boolean => writer.writeName("type").writeValue("boolean")
            case Arr(item) =>
                writer.startObject()
                writer.writeName("type").writeValue("array")
                writer.writeName("arrayItem").writeValue(item)
                writer.endObject()
            case Obj(fields) =>
                writer.startObject()
                writer.writeName("type").writeValue("object")
                let properties = HashMap<String, JsonSerializable>()
                let required = ArrayList<JsonSerializable>()
                for (f in fields) {
                    properties.add(f.name, f)
                    if (f.required) {
                        required.add(f.name)
                    }
                }
                writer.writeName("properties").writeValue(properties)
                writer.writeName("required").writeValue(required)
                writer.endObject()
        }
    }
}

public interface ToJsonSchema {
    static func toSchema(): JsonSchemaType

    static func toJsonSchema(): String {
        JsonTool.toJson(toSchema())
    }
}

extend String <: ToJsonSchema {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Str
    }
}

extend Rune <: ToJsonSchema {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Str
    }
}

extend Int8 <: ToJsonSchema {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Int
    }
}

extend Int16 <: ToJsonSchema {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Int
    }
}

extend Int32 <: ToJsonSchema {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Int
    }
}

extend Int64 <: ToJsonSchema {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Int
    }
}

extend UInt8 <: ToJsonSchema {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Int
    }
}

extend UInt16 <: ToJsonSchema {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Int
    }
}

extend UInt32 <: ToJsonSchema {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Int
    }
}

extend UInt64 <: ToJsonSchema {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Int
    }
}

extend Float16 <: ToJsonSchema {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Number
    }
}

extend Float32 <: ToJsonSchema {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Number
    }
}

extend Float64 <: ToJsonSchema {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Number
    }
}

extend Bool <: ToJsonSchema {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Boolean
    }
}

extend<T> Option<T> <: ToJsonSchema where T <: ToJsonSchema {
    public static func toSchema(): JsonSchemaType {
        T.toSchema()
    }
}

extend<T> Array<T> <: ToJsonSchema where T <: ToJsonSchema {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Arr(T.toSchema())
    }
}

extend<T> ArrayList<T> <: ToJsonSchema where T <: ToJsonSchema {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Arr(T.toSchema())
    }
}

extend<T> HashMap<String, T> <: ToJsonSchema where T <: ToJsonSchema {
    public static func toSchema(): JsonSchemaType {
        // JsonSchemaType.Obj(Array<JsonSchemaInfo>(..))
        throw Exception("HashMap has no schema")
    }
}

extend DateTime <: ToJsonSchema {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Str
    }
}

extend BigInt <: ToJsonSchema {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Str
    }
}

extend Decimal <: ToJsonSchema {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Str
    }
}
