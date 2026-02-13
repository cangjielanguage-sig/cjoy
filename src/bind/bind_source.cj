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

import std.collection.{Map, HashMap, ArrayList}
import stdx.encoding.url.Form
import stdx.net.http.HttpHeaders
import cjoy.log.macros.*

/**
 * Map container that implements JoyBindSource.
 *
 * Provides a HashMap-based data source for parameter binding.
 */
public class MapContainer <: JoyBindSource & ToString {
    /**
     * Create a new MapContainer.
     *
     * @param data the map data
     */
    public MapContainer(let data: HashMap<String, Any>) {}

    /**
     * Get one value by name from source.
     *
     * @param name the value name
     * @return the value, or None if not found
     */
    public func getOne<T>(name: String): ?T {
        let v = data.get(name)
        getValue<Any, T>(v, name)
    }

    /**
     * Get all values by name from source.
     *
     * @param name the value name
     * @return the collection of values
     */
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
                    @JoyLogDebug("[Bind] bind source data for ${name} is not collection")
                    ()
            }
        } else {
            @JoyLogDebug("[Bind] not found bind source data for ${name}")
        }
        res
    }

    /**
     * Convert to string.
     *
     * @return the string representation
     */
    public func toString(): String {
        mapToString(data)
    }

    /**
     * Convert map to string.
     *
     * @param data the map data
     * @return the string representation
     */
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

    /**
     * Convert collection to string.
     *
     * @param data the collection data
     * @return the string representation
     */
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

/**
 * Extend Form to implement JoyBindSource for form data binding.
 */
extend Form <: JoyBindSource {
    /**
     * Get one value by name from form.
     *
     * @param name the value name
     * @return the value, or None if not found
     */
    public func getOne<T>(name: String): ?T {
        let v = this.get(name)
        getValue<String, T>(v, name)
    }

    /**
     * Get all values by name from form.
     *
     * @param name the value name
     * @return the collection of values
     */
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

/**
 * Extend HttpHeaders to implement JoyBindSource for header binding.
 */
extend HttpHeaders <: JoyBindSource {
    /**
     * Get one value by name from headers.
     *
     * @param name the header name
     * @return the header value, or None if not found
     */
    public func getOne<T>(name: String): ?T {
        let v = this.getFirst(name)
        getValue<String, T>(v, name)
    }

    /**
     * Get all values by name from headers.
     *
     * @param name the header name
     * @return the collection of header values
     */
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

/**
 * Extend HashMap<String, String> to implement JoyBindSource for map binding.
 */
extend HashMap<String, String> <: JoyBindSource {
    /**
     * Get one value by name from hashmap.
     *
     * @param name the key name
     * @return the value, or None if not found
     */
    public func getOne<T>(name: String): ?T {
        let v = this.get(name)
        getValue<String, T>(v, name)
    }

    /**
     * Get list from hashmap (always return empty).
     *
     * @param _ the key name (not used)
     * @return the empty collection
     */
    public func getList<T>(_: String): Collection<T> {
        @JoyLogWarn("[Bind] get list from HashMap<String, String> return empty")
        ArrayList<T>()
    }
}

private func getValue<V, T>(v: ?V, name: String): ?T {
    match (v) {
        case Some(x) => match (x) {
            case y: T => y
            case _ => None
        }
        case _ =>
            @JoyLogDebug("[Bind] not found bind data for ${name}")
            None
    }
}
