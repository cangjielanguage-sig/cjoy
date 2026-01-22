/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
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

public var serializableSingleStringAsArray: Bool = true

public class NumberData <: JsonSerializable & JsonDeserializable<NumberData> {
    public NumberData(public let value: DateTime) {}

    /**
     * create number data from float64
     *
     * @param number: float64 number
     * @return: number data
     */
    public static func of(number: Float64): NumberData {
        let a = trunc(number)
        let b = (number - a) * 1e9
        NumberData(DateTime.ofEpoch(second: Int64(a), nanosecond: Int64(b)))
    }

    /**
     * create number data from int64
     *
     * @param number: int64 number
     * @return: number data
     */
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

    /**
     * @throws JwtException if it is invalid  payload json
     */
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

    /**
     * get first claim value
     *
     * @return: first claim value or empty string
     */
    public func getFirstValue(): String {
        if (claims.size >= 1) {
            return claims[0]
        }
        return ""
    }
}

public interface Claims {
    /**
     * get expiration time
     *
     * @return: expiration time or None
     */
    func getExpirationTime(): ?NumberData

    /**
     * get issued at time
     *
     * @return: issued at time or None
     */
    func getIssuedAt(): ?NumberData

    /**
     * get not before time
     *
     * @return: not before time or None
     */
    func getNotBefore(): ?NumberData

    /**
     * get issuer
     *
     * @return: issuer or None
     */
    func getIssuer(): ?String

    /**
     * get subject
     *
     * @return: subject or None
     */
    func getSubject(): ?String

    /**
     * get audience
     *
     * @return: audience or None
     */
    func getAudience(): ?ClaimStrings

    /**
     * get claim string by name
     *
     * @param name: claim name
     * @return: claim value or None
     */
    func getClaimString(name: String): ?String

    /**
     * set expiration time
     *
     * @param exp: expiration time
     * @return: claims
     */
    func expirationTime(exp: DateTime): Claims

    /**
     * set issued at time
     *
     * @param iat: issued at time
     * @return: claims
     */
    func issuedAt(iat: DateTime): Claims

    /**
     * set not before time
     *
     * @param nbf: not before time
     * @return: claims
     */
    func notBefore(nbf: DateTime): Claims

    /**
     * set issuer
     *
     * @param iss: issuer
     * @return: claims
     */
    func issuer(iss: String): Claims

    /**
     * set subject
     *
     * @param sub: subject
     * @return: claims
     */
    func subject(sub: String): Claims

    /**
     * set audience
     *
     * @param aud: audience
     * @return: claims
     */
    func audience(aud: String): Claims

    /**
     * set audiences
     *
     * @param auds: audiences
     * @return: claims
     */
    func audiences(auds: Array<String>): Claims

    /**
     * set claim
     *
     * @param name: claim name
     * @param value: claim value
     * @return: claims
     */
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

    public func getClaimString(name: String): ?String {
        toString(name)
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
        add("aud", ClaimStrings([aud]))
        this
    }

    public func audiences(auds: Array<String>): Claims {
        add("aud", ClaimStrings(auds))
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
                case x: String => ClaimStrings([x])
                case x: Array<String> => ClaimStrings(x)
                case x: Collection<JsonSerializable> =>
                    let arr = x |> map {it => (it as String).getOrThrow()} |> collectArray
                    ClaimStrings(arr)
                case x: ClaimStrings => x
                case _ => None
            }
        }
        None
    }

    func toString(key: String): ?String {
        (get(key) ?? Option<JsonSerializable>.None) as String
    }
}
