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

import std.io.ByteBuffer
import std.collection.{ArrayList, HashMap}
import std.convert.Parsable
import stdx.encoding.json.stream.{JsonDeserializable, JsonSerializable, JsonReader, JsonWriter, JsonToken}

/**
 * JSON 工具类，用于序列化和反序列化。
 *
 * 提供静态方法用于在 JSON 字符串/字节和仓颉对象之间转换。
 */
public class JsonTool {
    /**
     * 将 JSON 字符串反序列化为 T。
     *
     * @param jsonStr JSON 字符串
     * @return 类型 T 的对象
     */
    public static func fromJson<T>(jsonStr: String): T where T <: JsonDeserializable<T> {
        var stream = ByteBuffer()
        unsafe { stream.write(jsonStr.rawData()) }
        let reader = JsonReader(stream)
        T.fromJson(reader)
    }

    /**
     * 将 JSON 字节反序列化为 T。
     *
     * @param bs JSON 字节
     * @return 类型 T 的对象
     */
    public static func fromJson<T>(bs: Array<Byte>): T where T <: JsonDeserializable<T> {
        var stream = ByteBuffer()
        stream.write(bs)
        let reader = JsonReader(stream)
        T.fromJson(reader)
    }

    /**
     * 将类型 T 的对象序列化为 JSON 字符串。
     *
     * @param val 类型 T 的对象
     * @param indent 是否使用 '\t' 输出缩进
     * @return JSON 字符串
     */
    public static func toJson<T>(val: T, indent!: Bool = false): String where T <: JsonSerializable {
        String.fromUtf8(toJsonBytes(val, indent: indent))
    }

    /**
     * 将类型 T 的对象序列化为 JSON 字节。
     *
     * @param val 类型 T 的对象
     * @param indent 是否使用 '\t' 输出缩进
     * @return JSON 字节
     */
    public static func toJsonBytes<T>(val: T, indent!: Bool = false): Array<Byte> where T <: JsonSerializable {
        let stream = ByteBuffer()
        let writer = JsonWriter(stream)
        if (indent) {
            writer.writeConfig.newline = "\n"
            writer.writeConfig.indent = "\t"
        }
        writer.writeValue(val)
        writer.flush()
        stream.bytes()
    }

    /**
     * 将 JSON 字节反序列化为 JsonSerializable 对象。
     *
     * @param bs JSON 字节
     * @return JsonSerializable 对象
     */
    public static func fromJsonToSerializable(bs: Array<Byte>): JsonSerializable {
        var buffer = ByteBuffer()
        buffer.write(bs)
        let reader = JsonReader(buffer)
        return fromJsonToSerializable(reader)
    }

    /**
     * 将 JSON 字符串反序列化为 JsonSerializable 对象。
     *
     * @param jsonStr JSON 字符串
     * @return JsonSerializable 对象
     */
    public static func fromJsonToSerializable(jsonStr: String): JsonSerializable {
        var buffer = ByteBuffer()
        unsafe { buffer.write(jsonStr.rawData()) }
        let reader = JsonReader(buffer)
        return fromJsonToSerializable(reader)
    }

    /**
     * 从读取器反序列化 JSON 到 JsonSerializable 对象。
     *
     * @param reader JSON 读取器
     * @return JsonSerializable 对象
     * @throws Exception 如果令牌无效
     */
    public static func fromJsonToSerializable(reader: JsonReader): JsonSerializable {
        while (let Some(v) <- reader.peek()) {
            match (v) {
                case BeginObject =>
                    reader.startObject()
                    let map: HashMap<String, JsonSerializable> = HashMap()
                    while (reader.peek() != EndObject) {
                        let name = reader.readName()
                        let value = JsonTool.fromJsonToSerializable(reader)
                        map.add(name, value)
                    }
                    reader.endObject()
                    return map
                case BeginArray =>
                    reader.startArray()
                    let list: ArrayList<JsonSerializable> = ArrayList()
                    while (reader.peek() != EndArray) {
                        let value = JsonTool.fromJsonToSerializable(reader)
                        list.add(value)
                    }
                    reader.endArray()
                    return list
                case JsonBool => return reader.readValue<Bool>()
                case JsonString => return reader.readValue<String>()
                case JsonNumber =>
                    let value = reader.readValue<String>()
                    if (value.indexOf(b'.').isSome()) {
                        return Float64.parse(value)
                    } else {
                        return Int64.parse(value)
                    }
                case JsonNull =>
                    reader.readValue<String>()
                    return Option<String>.None
                case _ => throw Exception("the token is invalid")
            }
        }
        throw Exception("unreable")
    }

    /**
     * 从读取器反序列化 JSON 到 Any 对象。
     *
     * @param reader JSON 读取器
     * @return Any 对象
     * @throws Exception 如果令牌无效
     */
    public static func fromJsonToAny(reader: JsonReader): Any {
        while (let Some(v) <- reader.peek()) {
            match (v) {
                case BeginObject =>
                    reader.startObject()
                    let map: HashMap<String, Any> = HashMap()
                    while (reader.peek() != EndObject) {
                        let name = reader.readName()
                        let value = JsonTool.fromJsonToAny(reader)
                        map.add(name, value)
                    }
                    reader.endObject()
                    return map
                case BeginArray =>
                    reader.startArray()
                    let list: ArrayList<Any> = ArrayList()
                    while (reader.peek() != EndArray) {
                        let value = JsonTool.fromJsonToAny(reader)
                        list.add(value)
                    }
                    reader.endArray()
                    return list
                case JsonBool => return reader.readValue<Bool>()
                case JsonString => return reader.readValue<String>()
                case JsonNumber =>
                    let value = reader.readValue<String>()
                    if (value.indexOf(b'.').isSome()) {
                        return Float64.parse(value)
                    } else {
                        return Int64.parse(value)
                    }
                case JsonNull =>
                    reader.readValue<String>()
                    return Option<String>.None
                case _ => throw Exception("the token is invalid")
            }
        }
        throw Exception("unreable")
    }

    /**
     * 将 JSON 字符串字段反序列化为 Rune 类型。
     *
     * @param reader JSON 读取器
     * @return Rune 值
     * @throws Exception 如果值不是单个 Rune
     */
    public static func readRune(reader: JsonReader): Rune {
        let str = reader.readValue<String>()
        if (str.toRuneArray().size != 1) {
            throw Exception("the json value is not Rune")
        }
        Rune(str[0])
    }

    /**
     * 返回 T 的 JSON 模式类型。
     *
     * @param T 实现 Jsonable 的类型
     * @return JSON 模式类型
     */
    public static func getSchema<T>(): JsonSchemaType where T <: Jsonable {
        T.toSchema()
    }
}
