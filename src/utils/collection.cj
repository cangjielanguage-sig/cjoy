/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.utils

import std.collection.{ArrayList, HashMap}
import std.collection.concurrent.ConcurrentHashMap
import std.time.DateTime

/**
 * casts value to specified type
 *
 * @param t value to cast
 * @return value casted to type R
 */
protected func cast<R>(t: Any): R {
    (t as R).getOrThrow()
}

/**
 * converts ArrayList<T> to ArrayList<R> recursively
 *
 * @param list input list to convert
 * @return converted list with nested structures also converted
 */
protected func converterList<T, R>(list: ArrayList<T>): ArrayList<R> {
    let res = ArrayList<R>()
    for (it in list) {
        match (it) {
            case x: R => res.add(x)
            case x: HashMap<String, T> =>
                let r: HashMap<String, R> = converterMap(x)
                res.add(cast<R>(r))
            case x: ArrayList<T> =>
                let r: ArrayList<R> = converterList(x)
                res.add(cast<R>(r))
            case _ => ()
        }
    }
    res
}

/**
 * converts HashMap<String, T> to HashMap<String, R> recursively
 *
 * @param map: input map to convert
 * @return: converted map with nested structures also converted
 */
protected func converterMap<T, R>(map: HashMap<String, T>): HashMap<String, R> {
    let res = HashMap<String, R>()
    for ((k, v) in map) {
        match (v) {
            case x: R => res.add(k, x)
            case x: HashMap<String, T> =>
                let r: HashMap<String, R> = converterMap(x)
                res.add(k, cast<R>(r))
            case x: ArrayList<T> =>
                let r: ArrayList<R> = converterList(x)
                res.add(k, cast<R>(r))
            case _ => ()
        }
    }
    res
}

protected type MapToString = HashMap<String, ToString>

protected type ListToString = ArrayList<ToString>

/**
 * interface for getting typed values from map or list structures
 *
 * @param T: key type (String for Map, Int64 for List)
 */
protected interface MapListGetFunc<T> {
    func getString(name: T): ?String
    func getInt(name: T): ?Int64
    func getFloat(name: T): ?Float64
    func getBool(name: T): ?Bool
    func getList(name: T): ?ListToString
    func getMap(name: T): ?MapToString
}

extend MapToString <: MapListGetFunc<String> {
    /**
     * gets string value by key name
     *
     * @param name: the key name
     * @return: string value if exists and is string, None otherwise
     */
    public func getString(name: String): ?String {
        this.get(name).map({it => it.toString()})
    }

    /**
     * gets int64 value by key name
     *
     * @param name: the key name
     * @return: Int64 value if exists and is int, None otherwise
     */
    public func getInt(name: String): ?Int64 {
        (this.get(name) ?? Option<ToString>.None) as Int64
    }

    /**
     * gets float64 value by key name
     *
     * @param name: the key name
     * @return: Float64 value if exists and is float, None otherwise
     */
    public func getFloat(name: String): ?Float64 {
        (this.get(name) ?? Option<ToString>.None) as Float64
    }

    /**
     * gets bool value by key name
     *
     * @param name: the key name
     * @return: Bool value if exists and is bool, None otherwise
     */
    public func getBool(name: String): ?Bool {
        (this.get(name) ?? Option<ToString>.None) as Bool
    }

    /**
     * gets list value by key name
     *
     * @param name: the key name
     * @return: ListToString value if exists and is list, None otherwise
     */
    public func getList(name: String): ?ListToString {
        (this.get(name) ?? Option<ToString>.None) as ListToString
    }

    /**
     * gets map value by key name
     *
     * @param name: the key name
     * @return: MapToString value if exists and is map, None otherwise
     */
    public func getMap(name: String): ?MapToString {
        (this.get(name) ?? Option<ToString>.None) as MapToString
    }
}

extend ListToString <: MapListGetFunc<Int64> {
    /**
     * gets string value by index
     *
     * @param idx: the index
     * @return: string value if exists and is string, None otherwise
     */
    public func getString(idx: Int64): ?String {
        this.get(idx).map({it => it.toString()})
    }

    /**
     * gets int64 value by index
     *
     * @param idx: the index
     * @return: Int64 value if exists and is int, None otherwise
     */
    public func getInt(idx: Int64): ?Int64 {
        (this.get(idx) ?? Option<ToString>.None) as Int64
    }

    /**
     * gets float64 value by index
     *
     * @param idx: the index
     * @return: Float64 value if exists and is float, None otherwise
     */
    public func getFloat(idx: Int64): ?Float64 {
        (this.get(idx) ?? Option<ToString>.None) as Float64
    }

    /**
     * gets bool value by index
     *
     * @param idx: the index
     * @return: Bool value if exists and is bool, None otherwise
     */
    public func getBool(idx: Int64): ?Bool {
        (this.get(idx) ?? Option<ToString>.None) as Bool
    }

    /**
     * gets list value by index
     *
     * @param idx: the index
     * @return: ListToString value if exists and is list, None otherwise
     */
    public func getList(idx: Int64): ?ListToString {
        (this.get(idx) ?? Option<ToString>.None) as ListToString
    }

    /**
     * gets map value by index
     *
     * @param idx: the index
     * @return: MapToString value if exists and is map, None otherwise
     */
    public func getMap(idx: Int64): ?MapToString {
        (this.get(idx) ?? Option<ToString>.None) as MapToString
    }
}

/**
 * cache item wrapper with timestamp
 *
 * @param T: type of cached item
 * @param item: the cached value
 * @param addTime: when the item was added to cache
 */
class CacheItem<T> {
    public CacheItem(public let item: T, public let addTime: DateTime) {}
}

/**
 * thread-safe cache with automatic expiration
 *
 * @param K: key type, must be Hashable and Equatable
 * @param V: value type
 * @param expireTime: duration after which items expire
 * @param timeoutFn: callback called when items expire
 */
protected class TimeoutCache<K, V> where K <: Hashable & Equatable<K> {
    let _expireTime: Duration
    let _timeoutFn: (k: K, v: V) -> Unit
    let _map: ConcurrentHashMap<K, CacheItem<V>> = ConcurrentHashMap()
    let _future: Future<Unit>

    /**
     * creates a new timeout cache
     *
     * @param expireTime: duration after which cached items expire
     * @param timeoutFn: callback function called with key and value when items expire
     */
    public init(expireTime: Duration, timeoutFn: (k: K, v: V) -> Unit) {
        _expireTime = expireTime
        _timeoutFn = timeoutFn
        let tmap = _map
        _future = spawn {
            while (true) {
                if (Thread.currentThread.hasPendingCancellation) {
                    return
                }
                sleep(Duration.millisecond*100)
                let iter = tmap.iterator()
                let now = DateTime.now()
                while (let Some((k, v)) <- iter.next()) {
                    if (v.addTime + expireTime > now) {
                        tmap.remove(k)
                    }
                }
            }
        }
    }

    /**
     * adds or updates a value in the cache
     *
     * @param k: the key
     * @param v: the value to cache
     */
    public func add(k: K, v: V): Unit {
        _map.add(k, CacheItem(v, DateTime.now()))
    }

    /**
     * gets a value from the cache
     *
     * @param k: the key
     * @return: cached value if exists and not expired, None otherwise
     */
    public func get(k: K): ?V {
        _map.get(k).map({v => v.item})
    }

    /**
     * removes a value from the cache
     *
     * @param k: the key to remove
     */
    public func remove(k: K): Unit {
        _map.remove(k)
    }

    /**
     * closes the cache and stops the expiration cleanup task
     */
    public func close(): Unit {
        _future.cancel()
    }
}
