/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.json

import stdx.encoding.json.stream.{JsonSerializable}
import std.collection.{HashMap, ArrayList}
import std.time.DateTime
import std.math.numeric.{BigInt, Decimal}

/**
 * JSON schema 字段信息。
 *
 * 表示 JSON schema 中的字段及其类型、描述和必需状态。
 */
public class JsonSchemaInfo {
    /**
     * 创建 JsonSchemaInfo 实例。
     *
     * @param name 字段名称
     * @param schemaType JSON schema 类型
     * @param description 字段描述
     * @param required 字段是否必需（默认：true）
     * @param schema 自定义 schema 字符串
     */
    public JsonSchemaInfo(
        public let name: String,
        public let schemaType!: JsonSchemaType = JsonSchemaType.Str,
        public let description!: String = "",
        public let required!: Bool = true,
        public let schema!: String = ""
    ) {}

    /**
     * 转换为 JsonSerializable。
     *
     * @return 表示 schema 的 JSON 可序列化对象
     */
    public func toJson(): JsonSerializable {
        if (schema != "") {
            return JsonTool.fromJsonToSerializable(schema)
        }
        schemaType.toJson(description: description)
    }
}

/**
 * JSON schema 规范的类型枚举。
 *
 * 可能的值：
 * - Str: 字符串类型
 * - Int: 整数类型
 * - Number: 数字类型（包括浮点数）
 * - Boolean: 布尔类型
 * - Arr(JsonSchemaType): 带项目 schema 的数组类型
 * - Obj(Array<JsonSchemaInfo>): 带字段 schema 的对象类型
 */
public enum JsonSchemaType {
    | Str
    | Int
    | Number
    | Boolean
    | Arr(JsonSchemaType)
    | Obj(Array<JsonSchemaInfo>)

    /**
     * 转换为 JsonSerializable schema。
     *
     * @param description schema 描述
     * @return JSON 可序列化 schema 对象
     */
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

/**
 * 可以生成 JSON schema 的类型接口。
 *
 * 提供转换为 JSON Schema 格式的方法。
 */
public interface Jsonable {
    /**
     * 获取 JSON schema 类型。
     *
     * @return JSON schema 类型
     */
    static func toSchema(): JsonSchemaType

    /**
     * 转换为 JSON schema 可序列化对象。
     *
     * @return JSON 可序列化 schema 对象
     */
    static func toJsonSchema(): JsonSerializable {
        toSchema().toJson()
    }

    /**
     * 转换为带描述的 JSON schema 可序列化对象。
     *
     * @param description schema 描述
     * @return JSON 可序列化 schema 对象
     */
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
        // BigInt 序列化为 JSON 数字而非字符串
        JsonSchemaType.Number
    }
}

extend Decimal <: Jsonable {
    public static func toSchema(): JsonSchemaType {
        // Decimal 序列化为 JSON 数字而非字符串
        JsonSchemaType.Number
    }
}
