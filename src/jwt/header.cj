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

public type MapHeaders = HashMap<String, JsonSerializable>

public interface Headers {
    func header(name: String, value: JsonSerializable): Headers
    func getString(name: String): ?String
    func getInt<T>(name: String): ?T
}

extend MapHeaders <: Headers {
    public func header(name: String, value: JsonSerializable): Headers {
        add(name, value)
        this
    }

    public func getString(name: String): ?String {
        (get(name) ?? Option<JsonSerializable>.None) as String
    }

    public func getInt<T>(name: String): ?T {
        (get(name) ?? Option<JsonSerializable>.None) as T
        None
    }
}
