/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.bind.api

import std.convert.Parsable
import std.collection.{HashMap, ArrayList, map, collectArray, collectArrayList}
import std.time.DateTime
import stdx.encoding.url.Form
import stdx.net.http.HttpHeaders

/**
 * the interface of binding
 */
public interface JoyBindable<T> {
    /**
     *
     * bind http request query, postform or header params to object
     *
     * @param source: the http request
     * @param meta: the bind meta info
     * @return the object
     */
    static func bind(source: JoyBindSource, name: String, defaultValue: ?String, timeformat: ?String): ?T
    static func bind(source: JoyBindSource, name: String, defaultValue: ?String): ?T {
        bind(source, name, defaultValue, None)
    }
    static func bind(source: JoyBindSource, name: String): ?T {
        bind(source, name, None, None)
    }
}

public interface JoyBindSource {
    func getOne(name: String): ?String
    func getAll(name: String): Collection<String>
}

extend Form <: JoyBindSource {
    public func getOne(name: String): ?String {
        this.get(name)
    }
}

extend HttpHeaders <: JoyBindSource {
    public func getOne(name: String): ?String {
        this.getFirst(name)
    }
    public func getAll(name: String): Collection<String> {
        this.get(name)
    }
}

extend HashMap<String, String> <: JoyBindSource {
    public func getOne(name: String): ?String {
        this.get(name)
    }
    public func getAll(_: String): Collection<String> {
        ArrayList<String>()
    }
}

extend String <: JoyBindable<String> {
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?String {
        if (let Some(dv) <- defaultValue) {
            source.getOne(name) ?? dv
        } else {
            source.getOne(name)
        }
    }
}

extend<T> Option<T> <: JoyBindable<Option<T>> where T <: JoyBindable<T> {
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, timeformat: ?String): ?Option<T> {
        T.bind(source, name, defaultValue, timeformat)
    }
}

func bindParsable<T>(source: JoyBindSource, name: String, defaultValue: ?String): ?T where T <: Parsable<T> {
    if (let Some(dv) <- defaultValue) {
        T.tryParse(source.getOne(name) ?? dv)
    } else {
        if (let Some(v) <- source.getOne(name)) {
            T.tryParse(v)
        } else {
            None
        }
    }
}

extend Int8 <: JoyBindable<Int8> {
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?Int8 {
        bindParsable<Int8>(source, name, defaultValue)
    }
}

extend Int16 <: JoyBindable<Int16> {
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?Int16 {
        bindParsable<Int16>(source, name, defaultValue)
    }
}

extend Int32 <: JoyBindable<Int32> {
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?Int32 {
        bindParsable<Int32>(source, name, defaultValue)
    }
}

extend Int64 <: JoyBindable<Int64> {
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?Int64 {
        bindParsable<Int64>(source, name, defaultValue)
    }
}

extend UInt8 <: JoyBindable<UInt8> {
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?UInt8 {
        bindParsable<UInt8>(source, name, defaultValue)
    }
}

extend UInt16 <: JoyBindable<UInt16> {
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?UInt16 {
        bindParsable<UInt16>(source, name, defaultValue)
    }
}

extend UInt32 <: JoyBindable<UInt32> {
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?UInt32 {
        bindParsable<UInt32>(source, name, defaultValue)
    }
}

extend UInt64 <: JoyBindable<UInt64> {
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?UInt64 {
        bindParsable<UInt64>(source, name, defaultValue)
    }
}

extend Float16 <: JoyBindable<Float16> {
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?Float16 {
        bindParsable<Float16>(source, name, defaultValue)
    }
}

extend Float32 <: JoyBindable<Float32> {
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?Float32 {
        bindParsable<Float32>(source, name, defaultValue)
    }
}

extend Float64 <: JoyBindable<Float64> {
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?Float64 {
        bindParsable<Float64>(source, name, defaultValue)
    }
}

extend Bool <: JoyBindable<Bool> {
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?Bool {
        bindParsable<Bool>(source, name, defaultValue)
    }
}

extend Array<String> <: JoyBindable<Array<String>> {
    public static func bind(source: JoyBindSource, name: String, _: ?String, _: ?String): ?Array<String> {
        source.getAll(name).toArray()
    }
}

extend ArrayList<String> <: JoyBindable<ArrayList<String>> {
    public static func bind(source: JoyBindSource, name: String, _: ?String, _: ?String): ?ArrayList<String> {
        ArrayList(source.getAll(name))
    }
}

// extend<T> Array<T> <: JoyBindable<Array<T>> where T <: Parsable<T> {
//     public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, timeformat: ?String): ?Array<T> {
//         let array = source.getAll(name)
//         array |> map {x: String => T.parse(x)} |> collectArray
//     }
// }

// extend<T> ArrayList<T> <: JoyBindable<ArrayList<T>> where T <: Parsable<T> {
//     public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, timeformat: ?String): ?ArrayList<T> {
//         let array = source.getAll(name)
//         array |> map {x: String => T.parse(x)} |> collectArrayList
//     }
// }

extend DateTime <: JoyBindable<DateTime> {
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, timeformat: ?String): ?DateTime {
        if (let Some(dv) <- defaultValue) {
            if (let Some(f) <- timeformat) {
                DateTime.parse(source.getOne(name) ?? dv, f)
            } else {
                DateTime.parse(source.getOne(name) ?? dv)
            }
        } else {
            if (let Some(v) <- source.getOne(name)) {
                if (let Some(f) <- timeformat) {
                    DateTime.parse(v, f)
                } else {
                    DateTime.parse(v)
                }
            } else {
                None
            }
        }
    }
}
