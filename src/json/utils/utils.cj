/*
 * Copyright (c) lanlingx 2024-present. All rights resvered.
 */

package cjoy.json.utils

import std.io.ByteBuffer
import encoding.json.stream.{JsonDeserializable, JsonSerializable, JsonReader, JsonWriter}

/**
* json util tool
*/
public class JsonTool {
    /**
    * Deserialize the json string to T
    * 
    * @param jsonStr the json string
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
    * @param val the object of T
    * @param indent output indent using '\t'
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
}