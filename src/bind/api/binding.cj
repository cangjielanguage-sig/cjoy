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
import std.collection.{Map, HashMap, ArrayList, map, filter, collectArray, collectArrayList}
import std.time.DateTime
import stdx.encoding.url.Form
import stdx.net.http.HttpHeaders
import cjoy.log.*

/**
 * the interface of binding
 */
public interface JoyBindable<T> {
    /**
     *
     * bind http request query, postform or header params to object
     *
     * @param source: the bind source object
     * @param name: the name of bind field
     * @param defaultValue: the default value of field
     * @param timeformat: the datetime field format
     * @return the object
     */
    static func bind(source: JoyBindSource, name: String, defaultValue: ?String, timeformat: ?String): ?T
    static func bind(source: JoyBindSource, name: String, defaultValue: ?String): ?T {
        bind(source, name, defaultValue, None)
    }
    static func bind(source: JoyBindSource, name: String): ?T {
        bind(source, name, None, None)
    }
    static func bindField(source: JoyBindSource, name: String): ?T {
        let map = source.getOne<HashMap<String, Any>>(name)
        match (map) {
            case Some(data) =>
                let container = MapContainer(data)
                bind(container, "", None, None)
            case _ =>
                // 这里后续得优化
                let col = source.getOne<Collection<Any>>(name)
                match (col) {
                    case Some(data) =>
                        let container = MapContainer(HashMap<String, Any>([("", data)]))
                        bind(container, "", None, None)
                    case _ =>
                        @LogDebug("not found bind source data for ${name}")
                        None
                }
        }
    }
}

/**
 * the interface of bind source, JoyBindable can get value from the source
 */
public interface JoyBindSource {
    /**
     * get one value by name from source
     */
    func getOne<T>(name: String): ?T

    /**
     * get all values by name from source
     */
    func getList<T>(name: String): Collection<T>
}

public class MapContainer <: JoyBindSource & ToString {
    public MapContainer(let data: HashMap<String, Any>) {}
    public func getOne<T>(name: String): ?T {
        let v = data.get(name)
        getValue<Any, T>(v, name)
    }

    public func getList<T>(name: String): Collection<T> {
        let res = ArrayList<T>()
        if (let Some(val) <- data.get(name)) {
            match (val) {
                case xl: Collection<Any> => for (x in xl) {
                    match (x) {
                        case x: T => res.add(x)
                        case _ => ()
                    }
                }
                case xl: Collection<T> => return xl
                case _ =>
                    @LogDebug("bind source data for ${name} is not collection")
                    ()
            }
        } else {
            @LogDebug("not found bind source data for ${name}")
        }
        res
    }

    public func toString(): String {
        mapToString(data)
    }

    public static func mapToString(data: Map<String, Any>): String {
        let builder = StringBuilder()
        builder.append("{")
        let iter = data.iterator()
        while (let Some((k, v)) <- iter.next()) {
            match (v) {
                case x: Map<String, Any> =>
                    if (builder.size > 1) {
                        builder.append(",")
                    }
                    builder.append("${k}:${mapToString(x)}")
                case x: Collection<Any> =>
                    if (builder.size > 1) {
                        builder.append(",")
                    }
                    builder.append("${k}:${colToString(x)}")
                case x: ToString => builder.append("${k}:${x.toString()}")
                case _ => ()
            }
        }
        builder.append("}")
        builder.toString()
    }

    public static func colToString(data: Collection<Any>): String {
        let builder = StringBuilder()
        builder.append("[")
        for (x in data) {
            match (x) {
                case v: ToString =>
                    if (builder.size > 1) {
                        builder.append(",")
                    }
                    builder.append(v.toString())
                case _ => ()
            }
        }
        builder.append("]")
        builder.toString()
    }
}

extend Form <: JoyBindSource {
    public func getOne<T>(name: String): ?T {
        let v = this.get(name)
        getValue<String, T>(v, name)
    }

    public func getList<T>(name: String): Collection<T> {
        let list = this.getAll(name)
        let res = ArrayList<T>()
        for (x in list) {
            match (x) {
                case x: T => res.add(x)
                case _ => ()
            }
        }
        res
    }
}

extend HttpHeaders <: JoyBindSource {
    public func getOne<T>(name: String): ?T {
        let v = this.getFirst(name)
        getValue<String, T>(v, name)
    }

    public func getList<T>(name: String): Collection<T> {
        let list = this.get(name)
        let res = ArrayList<T>()
        for (x in list) {
            match (x) {
                case x: T => res.add(x)
                case _ => ()
            }
        }
        res
    }
}

extend HashMap<String, String> <: JoyBindSource {
    public func getOne<T>(name: String): ?T {
        let v = this.get(name)
        getValue<String, T>(v, name)
    }

    public func getList<T>(_: String): Collection<T> {
        @LogWarn("get list from HashMap<String, String> return empty")
        ArrayList<T>()
    }
}

private func getValue<V, T>(v: ?V, name: String): ?T {
    match (v) {
        case Some(x) => match (x) {
            case y: T => y
            case _ => None
        }
        case _ => None
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

extend String <: JoyBindable<String> {
    public static func bind(source: JoyBindSource, name: String, defaultValue: ?String, _: ?String): ?String {
        let val = source.getOne<ToString>(name)
        getString(val, defaultValue)
    }
}

extend<T> Option<T> <: JoyBindable<Option<T>> where T <: JoyBindable<T> {
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

// T当前不考虑是Option
extend<T> Array<T> <: JoyBindable<Array<T>> where T <: JoyBindable<T> {
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

// T当前不考虑是Option
extend<T> ArrayList<T> <: JoyBindable<ArrayList<T>> where T <: JoyBindable<T> {
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
