/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
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

protected func converterList<T, R>(list: ArrayList<T>): ArrayList<R> {
    let res = ArrayList<R>()
    for (it in list) {
        match (it) {
            case x: R => res.add(x)
            case x: HashMap<String, T> =>
                let r: HashMap<String, R> = converterMap(x)
                res.add((r as R).getOrThrow())
            case x: ArrayList<T> =>
                let r: ArrayList<R> = converterList(x)
                res.add((r as R).getOrThrow())
            case _ => ()
        }
    }
    res
}

protected func converterMap<T, R>(map: HashMap<String, T>): HashMap<String, R> {
    let res = HashMap<String, R>()
    for ((k, v) in map) {
        match (v) {
            case x: R => res.add(k, x)
            case x: HashMap<String, T> =>
                let r: HashMap<String, R> = converterMap(x)
                res.add(k, (r as R).getOrThrow())
            case x: ArrayList<T> =>
                let r: ArrayList<R> = converterList(x)
                res.add(k, (r as R).getOrThrow())
            case _ => ()
        }
    }
    res
}

protected type MapToString = HashMap<String, ToString>

protected type ListToString = ArrayList<ToString>

protected interface MapListGetFunc<T> {
    func getString(name: T): ?String
    func getInt(name: T): ?Int64
    func getFloat(name: T): ?Float64
    func getBool(name: T): ?Bool
    func getList(name: T): ?ListToString
    func getMap(name: T): ?MapToString
}

extend MapToString <: MapListGetFunc<String> {
    public func getString(name: String): ?String {
        this.get(name).map({it => it.toString()})
    }

    public func getInt(name: String): ?Int64 {
        (this.get(name) ?? Option<ToString>.None) as Int64
    }

    public func getFloat(name: String): ?Float64 {
        (this.get(name) ?? Option<ToString>.None) as Float64
    }

    public func getBool(name: String): ?Bool {
        (this.get(name) ?? Option<ToString>.None) as Bool
    }

    public func getList(name: String): ?ListToString {
        (this.get(name) ?? Option<ToString>.None) as ListToString
    }

    public func getMap(name: String): ?MapToString {
        (this.get(name) ?? Option<ToString>.None) as MapToString
    }
}

extend ListToString <: MapListGetFunc<Int64> {
    public func getString(idx: Int64): ?String {
        this.get(idx).map({it => it.toString()})
    }

    public func getInt(idx: Int64): ?Int64 {
        (this.get(idx) ?? Option<ToString>.None) as Int64
    }

    public func getFloat(idx: Int64): ?Float64 {
        (this.get(idx) ?? Option<ToString>.None) as Float64
    }

    public func getBool(idx: Int64): ?Bool {
        (this.get(idx) ?? Option<ToString>.None) as Bool
    }

    public func getList(idx: Int64): ?ListToString {
        (this.get(idx) ?? Option<ToString>.None) as ListToString
    }

    public func getMap(idx: Int64): ?MapToString {
        (this.get(idx) ?? Option<ToString>.None) as MapToString
    }
}

class CacheItem<T> {
    public CacheItem(public let item: T, public let addTime: DateTime) {}
}

protected class TimeoutCache<K, V> where K <: Hashable & Equatable<K> {
    let _expireTime: Duration
    let _timeoutFn: (k: K, v: V) -> Unit
    let _map: ConcurrentHashMap<K, CacheItem<V>> = ConcurrentHashMap()
    let _future: Future<Unit>

    public init(expireTime: Duration, timeoutFn: (k: K, v: V) -> Unit) {
        _expireTime = expireTime
        _timeoutFn = timeoutFn
        let tmap = _map
        _future = spawn {
            while (true) {
                if (Thread.currentThread.hasPendingCancellation) {
                    return
                }
                sleep(2 * Duration.second)
                let iter = tmap.iterator()
                let now = DateTime.now()
                while (let Some((k, v)) <- iter.next()) {
                    if (v.addTime.addNanoseconds(expireTime.toNanoseconds()) > now) {
                        tmap.remove(k)
                    }
                }
            }
        }
    }

    public func add(k: K, v: V): Unit {
        _map.add(k, CacheItem(v, DateTime.now()))
    }

    public func get(k: K): ?V {
        _map.get(k).map({v => v.item})
    }

    public func remove(k: K): Unit {
        _map.remove(k)
    }

    public func close(): Unit {
        _future.cancel()
    }
}
