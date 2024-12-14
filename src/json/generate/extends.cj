package cjoy.json.generate

import std.io.ByteBuffer
import std.collection.{ArrayList, HashMap}
import encoding.json.stream.{JsonDeserializable, JsonSerializable, JsonReader, JsonWriter}

public interface JsonAdapter<T> {
    func toJson() : String

    static func fromJson(jsonStr: String) : T

    static func readRune(reader: JsonReader): Rune {
        let str = reader.readValue<String>()
        if (str.toRuneArray().size != 1) {
            throw Exception("the json value is not Rune")
        }
        Rune(str[0])
    }
}

private func toJsonStr<T>(val: T) : String where T <: JsonSerializable {
    let stream = ByteBuffer() 
    let writer = JsonWriter(stream) 
    writer.writeValue(val) 
    writer.flush()
    String.fromUtf8(stream.bytes())
}

private func fromJsonStr<T>(jsonStr: String) : T where T <: JsonDeserializable<T> {
    var stream = ByteBuffer()
    unsafe { stream.write(jsonStr.rawData()) }
    let reader = JsonReader(stream)
    T.fromJson(reader)
}

extend<T> Array<T> <: JsonAdapter<Array<T>> where T <: JsonSerializable & JsonDeserializable<T> {
    public func toJson(): String {
        toJsonStr<Array<T>>(this)
    }

    public static func fromJson(jsonStr: String) : Array<T> {
       fromJsonStr<Array<T>>(jsonStr)
    }
}

extend<T> ArrayList<T> <: JsonAdapter<ArrayList<T>> where T <: JsonSerializable & JsonDeserializable<T> {
    public func toJson(): String {
        toJsonStr<ArrayList<T>>(this)
    }
    
    public static func fromJson(jsonStr: String) : ArrayList<T> {
        fromJsonStr<ArrayList<T>>(jsonStr)
    }
}

extend<T> HashMap<String, T> <: JsonAdapter<HashMap<String, T>> where T <: JsonSerializable & JsonDeserializable<T> {
    public func toJson(): String {
        toJsonStr<HashMap<String, T>>(this)
    }
    
    public static func fromJson(jsonStr: String) :HashMap<String, T> {
        fromJsonStr<HashMap<String, T>>(jsonStr)
    }
}