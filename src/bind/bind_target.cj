/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.bind

import std.convert.Parsable
import std.collection.{HashMap, ArrayList}
import std.time.DateTime

extend String <: JoyBindable<String> {
    /**
     * bind source to string
     *
     * @param source: the bind source
     * @param name: the field name
     * @param defaultValue: the default value
     * @return the string value or None
     */
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?String {
        let val = source.getOne<ToString>(name)
        getString(val, defaultValue)
    }
}

private func getString(a: ?ToString, b: ?String): ?String {
    match (a) {
        case Some(x) => x.toString()
        case _ => match (b) {
            case Some(v) => v
            case _ => None
        }
    }
}

extend<T> Option<T> <: JoyBindable<Option<T>> where T <: JoyBindable<T> {
    /**
     * bind source to optional value
     *
     * @param source: the bind source
     * @param name: the field name
     * @param defaultValue: the default value
     * @param timeformat: the datetime format
     * @return the optional value
     */
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, timeformat: ?String): ?Option<T> {
        T.bind(source, name, defaultValue, timeformat)
    }
}

private func bindParsable<T>(source: JoyBindSource, name: String, defaultValue: ?String): ?T where T <: Parsable<T> {
    let val = source.getOne<T>(name)
    match (val) {
        case Some(x) => x
        case _ => bindParsable(source.getOne<ToString>(name), defaultValue)
    }
}

private func bindParsable<T>(val: ?ToString, defaultValue: ?String): ?T where T <: Parsable<T> {
    let v = getString(val, defaultValue)
    match (v) {
        case Some(x) => T.tryParse(x)
        case _ => None
    }
}

extend Int8 <: JoyBindable<Int8> {
    /**
     * bind source to int8
     *
     * @param source: the bind source
     * @param name: the field name
     * @param defaultValue: the default value
     * @return the int8 value or None
     */
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?Int8 {
        bindParsable<Int8>(source, name, defaultValue)
    }
}

extend Int16 <: JoyBindable<Int16> {
    /**
     * bind source to int16
     *
     * @param source: the bind source
     * @param name: the field name
     * @param defaultValue: the default value
     * @return the int16 value or None
     */
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?Int16 {
        bindParsable<Int16>(source, name, defaultValue)
    }
}

extend Int32 <: JoyBindable<Int32> {
    /**
     * bind source to int32
     *
     * @param source: the bind source
     * @param name: the field name
     * @param defaultValue: the default value
     * @return the int32 value or None
     */
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?Int32 {
        bindParsable<Int32>(source, name, defaultValue)
    }
}

extend Int64 <: JoyBindable<Int64> {
    /**
     * bind source to int64
     *
     * @param source: the bind source
     * @param name: the field name
     * @param defaultValue: the default value
     * @return the int64 value or None
     */
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?Int64 {
        bindParsable<Int64>(source, name, defaultValue)
    }
}

extend UInt8 <: JoyBindable<UInt8> {
    /**
     * bind source to uint8
     *
     * @param source: the bind source
     * @param name: the field name
     * @param defaultValue: the default value
     * @return the uint8 value or None
     */
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?UInt8 {
        bindParsable<UInt8>(source, name, defaultValue)
    }
}

extend UInt16 <: JoyBindable<UInt16> {
    /**
     * bind source to uint16
     *
     * @param source: the bind source
     * @param name: the field name
     * @param defaultValue: the default value
     * @return the uint16 value or None
     */
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?UInt16 {
        bindParsable<UInt16>(source, name, defaultValue)
    }
}

extend UInt32 <: JoyBindable<UInt32> {
    /**
     * bind source to uint32
     *
     * @param source: the bind source
     * @param name: the field name
     * @param defaultValue: the default value
     * @return the uint32 value or None
     */
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?UInt32 {
        bindParsable<UInt32>(source, name, defaultValue)
    }
}

extend UInt64 <: JoyBindable<UInt64> {
    /**
     * bind source to uint64
     *
     * @param source: the bind source
     * @param name: the field name
     * @param defaultValue: the default value
     * @return the uint64 value or None
     */
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?UInt64 {
        bindParsable<UInt64>(source, name, defaultValue)
    }
}

extend Float16 <: JoyBindable<Float16> {
    /**
     * bind source to float16
     *
     * @param source: the bind source
     * @param name: the field name
     * @param defaultValue: the default value
     * @return the float16 value or None
     */
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?Float16 {
        bindParsable<Float16>(source, name, defaultValue)
    }
}

extend Float32 <: JoyBindable<Float32> {
    /**
     * bind source to float32
     *
     * @param source: the bind source
     * @param name: the field name
     * @param defaultValue: the default value
     * @return the float32 value or None
     */
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?Float32 {
        bindParsable<Float32>(source, name, defaultValue)
    }
}

extend Float64 <: JoyBindable<Float64> {
    /**
     * bind source to float64
     *
     * @param source: the bind source
     * @param name: the field name
     * @param defaultValue: the default value
     * @return the float64 value or None
     */
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?Float64 {
        bindParsable<Float64>(source, name, defaultValue)
    }
}

extend Bool <: JoyBindable<Bool> {
    /**
     * bind source to bool
     *
     * @param source: the bind source
     * @param name: the field name
     * @param defaultValue: the default value
     * @return the bool value or None
     */
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?Bool {
        bindParsable<Bool>(source, name, defaultValue)
    }
}

// 当前不考虑T是Option
extend<T> Array<T> <: JoyBindable<Array<T>> where T <: JoyBindable<T> {
    /**
     * bind source to array
     *
     * @param source: the bind source
     * @param name: the field name
     * @return the array value or None
     */
    public static func bind(source: JoyBindSource, name: String, _: ?String, _: ?String): ?Array<T> {
        // 先尝试按同类型获取，如Array<String>
        let arr: Collection<T> = source.getList<T>(name)
        if (!arr.isEmpty()) {
            return arr.toArray()
        }

        let col: Collection<Any> = source.getList<Any>(name)
        bindCollection<T>(col).toArray()
    }
}

private func bindCollection<T>(col: Collection<Any>): ArrayList<T> where T <: JoyBindable<T> {
    // 按任一类型获取，则需要调用T.bind转换对应的类型
    // 如Array<Int>， 则先生成临时的map
    let map = HashMap<String, Any>()
    let container = MapContainer(map)
    let res = ArrayList<T>()
    for (a in col) {
        map[""] = a
        let val = T.bind(container, "", None, None)
        if (let Some(v) <- val) {
            res.add(v)
        }
    }
    res
}

// 当前不考虑T是Option
extend<T> ArrayList<T> <: JoyBindable<ArrayList<T>> where T <: JoyBindable<T> {
    /**
     * bind source to array list
     *
     * @param source: the bind source
     * @param name: the field name
     * @return the array list value or None
     */
    public static func bind(source: JoyBindSource, name: String, _: ?String, _: ?String): ?ArrayList<T> {
        let arr: Collection<T> = source.getList<T>(name)
        if (!arr.isEmpty()) {
            return ArrayList(arr)
        }

        let col: Collection<Any> = source.getList<Any>(name)
        bindCollection<T>(col)
    }
}

extend DateTime <: JoyBindable<DateTime> {
    /**
     * bind source to datetime
     *
     * @param source: the bind source
     * @param name: the field name
     * @param defaultValue: the default value
     * @param timeformat: the datetime format
     * @return the datetime value or None
     */
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, timeformat: ?String): ?DateTime {
        func parse(str: ?ToString): ?DateTime {
            match (str) {
                case Some(v) => match (timeformat) {
                    case Some(f) => DateTime.parse(v.toString(), f)
                    case _ => DateTime.parse(v.toString())
                }
                case _ => None
            }
        }
        match (defaultValue) {
            case Some(dv) =>
                let str = getString(source.getOne<ToString>(name), dv)
                match (str) {
                    case Some(v) => parse(v)
                    case _ => None
                }
            case _ => parse(source.getOne<ToString>(name))
        }
    }
}
