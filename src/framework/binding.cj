/*
 * Copyright (c) lanlingx 2025-present. All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.framework

import std.convert.*
import std.collection.{HashMap, ArrayList, map, collectArray, collectArrayList}
import std.time.DateTime
import encoding.url.Form
import net.http.HttpHeaders

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
}

public interface JoyBindMeta {
    prop name: String
    prop defaultValue: ?String
    prop timeformat: ?String
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
            source.getOne(name).getOrDefault({=> dv})
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

extend Int8 <: JoyBindable<Int8> {
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?Int8 {
        if (let Some(dv) <- defaultValue) {
            Int8.tryParse(source.getOne(name).getOrDefault({=> dv}))
        } else {
            if (let Some(v) <- source.getOne(name)) {
                Int8.tryParse(v)
            } else {
                None
            }
        }
    }
}

extend Int16 <: JoyBindable<Int16> {
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?Int16 {
        if (let Some(dv) <- defaultValue) {
            Int16.tryParse(source.getOne(name).getOrDefault({=> dv}))
        } else {
            if (let Some(v) <- source.getOne(name)) {
                Int16.tryParse(v)
            } else {
                None
            }
        }
    }
}

extend Int32 <: JoyBindable<Int32> {
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?Int32 {
        if (let Some(dv) <- defaultValue) {
            Int32.tryParse(source.getOne(name).getOrDefault({=> dv}))
        } else {
            if (let Some(v) <- source.getOne(name)) {
                Int32.tryParse(v)
            } else {
                None
            }
        }
    }
}

extend Int64 <: JoyBindable<Int64> {
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?Int64 {
        if (let Some(dv) <- defaultValue) {
            Int64.tryParse(source.getOne(name).getOrDefault({=> dv}))
        } else {
            if (let Some(v) <- source.getOne(name)) {
                Int64.tryParse(v)
            } else {
                None
            }
        }
    }
}

extend UInt8 <: JoyBindable<UInt8> {
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?UInt8 {
        if (let Some(dv) <- defaultValue) {
            UInt8.tryParse(source.getOne(name).getOrDefault({=> dv}))
        } else {
            if (let Some(v) <- source.getOne(name)) {
                UInt8.tryParse(v)
            } else {
                None
            }
        }
    }
}

extend UInt16 <: JoyBindable<UInt16> {
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?UInt16 {
        if (let Some(dv) <- defaultValue) {
            UInt16.tryParse(source.getOne(name).getOrDefault({=> dv}))
        } else {
            if (let Some(v) <- source.getOne(name)) {
                UInt16.tryParse(v)
            } else {
                None
            }
        }
    }
}

extend UInt32 <: JoyBindable<UInt32> {
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?UInt32 {
        if (let Some(dv) <- defaultValue) {
            UInt32.tryParse(source.getOne(name).getOrDefault({=> dv}))
        } else {
            if (let Some(v) <- source.getOne(name)) {
                UInt32.tryParse(v)
            } else {
                None
            }
        }
    }
}

extend UInt64 <: JoyBindable<UInt64> {
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?UInt64 {
        if (let Some(dv) <- defaultValue) {
            UInt64.tryParse(source.getOne(name).getOrDefault({=> dv}))
        } else {
            if (let Some(v) <- source.getOne(name)) {
                UInt64.tryParse(v)
            } else {
                None
            }
        }
    }
}

extend Float16 <: JoyBindable<Float16> {
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?Float16 {
        if (let Some(dv) <- defaultValue) {
            Float16.tryParse(source.getOne(name).getOrDefault({=> dv}))
        } else {
            if (let Some(v) <- source.getOne(name)) {
                Float16.tryParse(v)
            } else {
                None
            }
        }
    }
}

extend Float32 <: JoyBindable<Float32> {
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?Float32 {
        if (let Some(dv) <- defaultValue) {
            Float32.tryParse(source.getOne(name).getOrDefault({=> dv}))
        } else {
            if (let Some(v) <- source.getOne(name)) {
                Float32.tryParse(v)
            } else {
                None
            }
        }
    }
}

extend Float64 <: JoyBindable<Float64> {
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?Float64 {
        if (let Some(dv) <- defaultValue) {
            Float64.tryParse(source.getOne(name).getOrDefault({=> dv}))
        } else {
            if (let Some(v) <- source.getOne(name)) {
                Float64.tryParse(v)
            } else {
                None
            }
        }
    }
}

extend Bool <: JoyBindable<Bool> {
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?Bool {
        if (let Some(dv) <- defaultValue) {
            Bool.tryParse(source.getOne(name).getOrDefault({=> dv}))
        } else {
            if (let Some(v) <- source.getOne(name)) {
                Bool.tryParse(v)
            } else {
                None
            }
        }
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
                DateTime.parse(source.getOne(name).getOrDefault({=> dv}), f)
            } else {
                DateTime.parse(source.getOne(name).getOrDefault({=> dv}))
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
