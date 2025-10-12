/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.json.api

import stdx.encoding.json.stream.{JsonSerializable}
import std.collection.{HashMap, ArrayList}
import std.time.DateTime
import std.math.numeric.{BigInt, Decimal}

public class JsonSchemaInfo {
    public JsonSchemaInfo(
        public let name: String,
        public let schemaType!: JsonSchemaType = JsonSchemaType.Str,
        public let description!: String = "",
        public let required!: Bool = true,
        public let schema!: String = ""
    ) {}

    public func toJson(): JsonSerializable {
        if (schema != "") {
            return JsonTool.fromJsonToSerializable(schema)
        }
        schemaType.toJson(description: description)
    }
}

public enum JsonSchemaType {
    | Str
    | Int
    | Number
    | Boolean
    | Arr(JsonSchemaType)
    | Obj(Array<JsonSchemaInfo>)

    public func toJson(description!: String = ""): JsonSerializable {
        let res: HashMap<String, JsonSerializable> = HashMap()
        let addDesc = {
            => if (description != "") {
                res.add("description", description)
            }
        }
        match (this) {
            case Str =>
                res.add("type", "string");
                addDesc()
            case Int =>
                res.add("type", "integer");
                addDesc()
            case Number =>
                res.add("type", "number");
                addDesc()
            case Boolean =>
                res.add("type", "boolean");
                addDesc()
            case Arr(item) =>
                res.add("type", "array")
                addDesc()
                res.add("items", item.toJson())
            case Obj(fields) =>
                res.add("type", "object")
                addDesc()
                let properties = HashMap<String, JsonSerializable>()
                let required = ArrayList<String>()
                for (f in fields) {
                    properties.add(f.name, f.toJson())
                    if (f.required) {
                        required.add(f.name)
                    }
                }
                res.add("properties", properties)
                res.add("required", required)
        }
        res
    }
}

public interface Jsonable {
    static func toSchema(): JsonSchemaType

    static func toJsonSchema(): JsonSerializable {
        toSchema().toJson()
    }

    static func toJsonSchema(description: String): JsonSerializable {
        toSchema().toJson(description: description)
    }
}

extend String <: Jsonable {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Str
    }
}

extend Rune <: Jsonable {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Str
    }
}

extend Int8 <: Jsonable {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Int
    }
}

extend Int16 <: Jsonable {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Int
    }
}

extend Int32 <: Jsonable {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Int
    }
}

extend Int64 <: Jsonable {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Int
    }
}

extend UInt8 <: Jsonable {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Int
    }
}

extend UInt16 <: Jsonable {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Int
    }
}

extend UInt32 <: Jsonable {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Int
    }
}

extend UInt64 <: Jsonable {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Int
    }
}

extend Float16 <: Jsonable {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Number
    }
}

extend Float32 <: Jsonable {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Number
    }
}

extend Float64 <: Jsonable {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Number
    }
}

extend Bool <: Jsonable {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Boolean
    }
}

extend<T> Option<T> <: Jsonable where T <: Jsonable {
    public static func toSchema(): JsonSchemaType {
        T.toSchema()
    }
}

extend<T> Array<T> <: Jsonable where T <: Jsonable {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Arr(T.toSchema())
    }
}

extend<T> ArrayList<T> <: Jsonable where T <: Jsonable {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Arr(T.toSchema())
    }
}

extend<T> HashMap<String, T> <: Jsonable where T <: Jsonable {
    public static func toSchema(): JsonSchemaType {
        throw Exception("HashMap has no schema")
    }
}

extend DateTime <: Jsonable {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Str
    }
}

extend BigInt <: Jsonable {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Str
    }
}

extend Decimal <: Jsonable {
    public static func toSchema(): JsonSchemaType {
        JsonSchemaType.Str
    }
}
