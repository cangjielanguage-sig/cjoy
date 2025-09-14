/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.jwt

import std.collection.{HashMap, map, collectArray}
import std.time.DateTime
import std.math.trunc
import stdx.encoding.json.stream.{JsonDeserializable, JsonSerializable, JsonWriter, JsonReader, JsonToken}

public class JwtException <: Exception {
    public init(message: String) {
        super(message)
    }
}

public var serializableSingleStringAsArray = true

public class NumberData <: JsonSerializable & JsonDeserializable<NumberData> {
    public NumberData(public let value: DateTime) {}

    public static func of(number: Float64): NumberData {
        let a = trunc(number)
        let b = number - a
        NumberData(DateTime.ofEpoch(second: Int64(a), nanosecond: Int64(b)))
    }

    public static func of(number: Int64): NumberData {
        NumberData(DateTime.ofEpoch(second: number, nanosecond: 0))
    }

    public func toJson(writer: JsonWriter): Unit {
        let uts = value.toUnixTimeStamp()
        // let time = Float64(uts.toNanoseconds()) / 1e9
        // writer.writeValue(time)
        writer.writeValue(uts.toSeconds())
    }

    public static func fromJson(reader: JsonReader): NumberData {
        let number = reader.readValue<Float64>()
        NumberData.of(number)
    }
}

public class ClaimStrings <: JsonSerializable & JsonDeserializable<ClaimStrings> {
    public ClaimStrings(public let claims: Array<String>) {
    }

    public func toJson(writer: JsonWriter): Unit {
        if (claims.size == 1 && !serializableSingleStringAsArray) {
            writer.writeValue(claims[0])
        } else {
            writer.writeValue(claims)
        }
    }

    public static func fromJson(reader: JsonReader): ClaimStrings {
        let token = reader.peek()
        if (let Some(t) <- token) {
            if (t == JsonToken.BeginArray) {
                return ClaimStrings(reader.readValue<Array<String>>())
            } else if (t == JsonToken.JsonString) {
                return ClaimStrings(reader.readValue<String>())
            }
        }
        throw JwtException("deserializable claim strings failed")
    }

    public func getFirstValue(): String {
        if (claims.size >= 1) {
            return claims[0]
        }
        return ""
    }
}

public interface Claims {
    func getExpirationTime(): ?NumberData
    func getIssuedAt(): ?NumberData
    func getNotBefore(): ?NumberData
    func getIssuer(): ?String
    func getSubject(): ?String
    func getAudience(): ?ClaimStrings

    func expirationTime(exp: DateTime): Claims
    func issuedAt(iat: DateTime): Claims
    func notBefore(nbf: DateTime): Claims
    func issuer(iss: String): Claims
    func subject(sub: String): Claims
    func audience(aud: String): Claims
    func claim(name: String, value: JsonSerializable): Claims
}

public type MapClaims = HashMap<String, JsonSerializable>

extend MapClaims <: Claims {
    public func getExpirationTime(): ?NumberData {
        toNumberDate("exp")
    }

    public func getNotBefore(): ?NumberData {
        toNumberDate("nbf")
    }

    public func getIssuedAt(): ?NumberData {
        toNumberDate("iat")
    }

    public func getAudience(): ?ClaimStrings {
        toClaimStrings("aud")
    }

    public func getIssuer(): ?String {
        toString("iss")
    }

    public func getSubject(): ?String {
        toString("sub")
    }

    public func expirationTime(exp: DateTime): Claims {
        add("exp", NumberData(exp))
        this
    }

    public func issuedAt(iat: DateTime): Claims {
        add("iat", NumberData(iat))
        this
    }
    public func notBefore(nbf: DateTime): Claims {
        add("nbf", NumberData(nbf))
        this
    }

    public func issuer(iss: String): Claims {
        add("iss", iss)
        this
    }

    public func subject(sub: String): Claims {
        add("sub", sub)
        this
    }

    public func audience(aud: String): Claims {
        add("aud", aud)
        this
    }

    public func claim(name: String, value: JsonSerializable): Claims {
        add(name, value)
        this
    }

    func toNumberDate(key: String): ?NumberData {
        if (let Some(v) <- get(key)) {
            return match (v) {
                case x: Float16 => NumberData.of(Float64(x))
                case x: Float32 => NumberData.of(Float64(x))
                case x: Float64 => NumberData.of(x)
                case x: Int16 => NumberData.of(Int64(x))
                case x: UInt16 => NumberData.of(Int64(x))
                case x: Int32 => NumberData.of(Int64(x))
                case x: UInt32 => NumberData.of(Int64(x))
                case x: Int64 => NumberData.of(Int64(x))
                case x: UInt64 => NumberData.of(Int64(x))
                case _ => None
            }
        }
        None
    }

    func toClaimStrings(key: String): ?ClaimStrings {
        if (let Some(v) <- get(key)) {
            return match (v) {
                case x: ToString => ClaimStrings([x.toString()])
                case x: Array<String> => ClaimStrings(x)
                case x: Collection<String> => ClaimStrings(x.toArray())
                case x: ClaimStrings => x
                case x: Collection<ToString> =>
                    let a: Array<String> = x |> map {it => it.toString()} |> collectArray
                    ClaimStrings(a)
                case _ => None
            }
        }
        None
    }

    func toString(key: String): ?String {
        (get(key) ?? Option<JsonSerializable>.None) as String
    }
}
