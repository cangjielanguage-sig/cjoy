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

import std.io.ByteBuffer
import std.collection.{ArrayList, HashMap}
import std.convert.Parsable
import stdx.encoding.json.stream.{JsonDeserializable, JsonSerializable, JsonReader, JsonWriter, JsonToken}

/**
 * json util tool
 */
public class JsonTool {
    /**
     * Deserialize the json string to T
     *
     * @param jsonStr: the json string
     * @return T the object of T
     */
    public static func fromJson<T>(jsonStr: String): T where T <: JsonDeserializable<T> {
        var stream = ByteBuffer()
        unsafe { stream.write(jsonStr.rawData()) }
        let reader = JsonReader(stream)
        T.fromJson(reader)
    }

    /**
     * serialize the object of T to json string
     *
     * @param val: the object of T
     * @param indent: output indent using '\t'
     * @return String the json string
     */
    public static func toJson<T>(val: T, indent!: Bool = false): String where T <: JsonSerializable {
        let stream = ByteBuffer()
        let writer = JsonWriter(stream)
        if (indent) {
            writer.writeConfig.indent = "\t"
        }
        writer.writeValue(val)
        writer.flush()
        String.fromUtf8(stream.bytes())
    }

    /**
     * deserialize json string to object
     *
     * @param jsonStr: the json string
     * @return ?Any the object
     */
    public static func fromJsonToAny(jsonStr: String): Any {
        var buffer = ByteBuffer()
        unsafe { buffer.write(jsonStr.rawData()) }
        let reader = JsonReader(buffer)
        return fromJsonToAny(reader)
    }

    /**
     * deserialize json string to object
     *
     * @param reader: the json reader
     * @return ?Any the object
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
                    return Option<Any>.None
                case _ => throw Exception("the token is invalid")
            }
        }
    }

    /**
     * deserialize json string feild to rune type
     *
     * @param reader: the json reader
     * @return rune
     */
    public static func readRune(reader: JsonReader): Rune {
        let str = reader.readValue<String>()
        if (str.toRuneArray().size != 1) {
            throw Exception("the json value is not Rune")
        }
        Rune(str[0])
    }
}
