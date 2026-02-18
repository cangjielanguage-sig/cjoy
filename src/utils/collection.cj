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
 * 将值转换为指定类型
 *
 * @param t 要转换的值
 * @return 转换为类型 R 的值
 */
protected func cast<R>(t: Any): R {
    (t as R).getOrThrow()
}

/**
 * 递归地将 ArrayList<T> 转换为 ArrayList<R>
 *
 * @param list 要转换的输入列表
 * @return 转换后的列表，嵌套结构也会被转换
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
 * 递归地将 HashMap<String, T> 转换为 HashMap<String, R>
 *
 * @param map: 要转换的输入地图
 * @return: 转换后的地图，嵌套结构也会被转换
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
 * 用于从地图或列表结构中获取类型化值的接口
 *
 * @param T: 键类型（地图使用 String，列表使用 Int64）
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
     * 按键名获取字符串值
     *
     * @param name: 键名
     * @return: 字符串值（如果存在且是字符串类型），否则返回 None
     */
    public func getString(name: String): ?String {
        this.get(name).map({it => it.toString()})
    }

    /**
     * 按键名获取 int64 值
     *
     * @param name: 键名
     * @return: Int64 值（如果存在且是整数类型），否则返回 None
     */
    public func getInt(name: String): ?Int64 {
        (this.get(name) ?? Option<ToString>.None) as Int64
    }

    /**
     * 按键名获取 float64 值
     *
     * @param name: 键名
     * @return: Float64 值（如果存在且是浮点数类型），否则返回 None
     */
    public func getFloat(name: String): ?Float64 {
        (this.get(name) ?? Option<ToString>.None) as Float64
    }

    /**
     * 按键名获取布尔值
     *
     * @param name: 键名
     * @return: Bool 值（如果存在且是布尔类型），否则返回 None
     */
    public func getBool(name: String): ?Bool {
        (this.get(name) ?? Option<ToString>.None) as Bool
    }

    /**
     * 按键名获取列表值
     *
     * @param name: 键名
     * @return: ListToString 值（如果存在且是列表类型），否则返回 None
     */
    public func getList(name: String): ?ListToString {
        (this.get(name) ?? Option<ToString>.None) as ListToString
    }

    /**
     * 按键名获取地图值
     *
     * @param name: 键名
     * @return: MapToString 值（如果存在且是地图类型），否则返回 None
     */
    public func getMap(name: String): ?MapToString {
        (this.get(name) ?? Option<ToString>.None) as MapToString
    }
}

extend ListToString <: MapListGetFunc<Int64> {
    /**
     * 按索引获取字符串值
     *
     * @param idx: 索引
     * @return: 字符串值（如果存在且是字符串类型），否则返回 None
     */
    public func getString(idx: Int64): ?String {
        this.get(idx).map({it => it.toString()})
    }

    /**
     * 按索引获取 int64 值
     *
     * @param idx: 索引
     * @return: Int64 值（如果存在且是整数类型），否则返回 None
     */
    public func getInt(idx: Int64): ?Int64 {
        (this.get(idx) ?? Option<ToString>.None) as Int64
    }

    /**
     * 按索引获取 float64 值
     *
     * @param idx: 索引
     * @return: Float64 值（如果存在且是浮点数类型），否则返回 None
     */
    public func getFloat(idx: Int64): ?Float64 {
        (this.get(idx) ?? Option<ToString>.None) as Float64
    }

    /**
     * 按索引获取布尔值
     *
     * @param idx: 索引
     * @return: Bool 值（如果存在且是布尔类型），否则返回 None
     */
    public func getBool(idx: Int64): ?Bool {
        (this.get(idx) ?? Option<ToString>.None) as Bool
    }

    /**
     * 按索引获取列表值
     *
     * @param idx: 索引
     * @return: ListToString 值（如果存在且是列表类型），否则返回 None
     */
    public func getList(idx: Int64): ?ListToString {
        (this.get(idx) ?? Option<ToString>.None) as ListToString
    }

    /**
     * 按索引获取地图值
     *
     * @param idx: 索引
     * @return: MapToString 值（如果存在且是地图类型），否则返回 None
     */
    public func getMap(idx: Int64): ?MapToString {
        (this.get(idx) ?? Option<ToString>.None) as MapToString
    }
}

/**
 * 带时间戳的缓存项包装器
 *
 * @param T: 缓存项的类型
 * @param item: 缓存值
 * @param addTime: 项添加到缓存的时间
 */
class CacheItem<T> {
    public CacheItem(public let item: T, public let addTime: DateTime) {}
}

/**
 * 线程安全的自动过期缓存
 *
 * @param K: 键类型，必须是 Hashable 和 Equatable
 * @param V: 值类型
 * @param expireTime: 项过期后的持续时间
 * @param timeoutFn: 项过期时调用的回调
 */
protected class TimeoutCache<K, V> where K <: Hashable & Equatable<K> {
    let _expireTime: Duration
    let _timeoutFn: (k: K, v: V) -> Unit
    let _map: ConcurrentHashMap<K, CacheItem<V>> = ConcurrentHashMap()
    let _future: Future<Unit>

    /**
     * 创建一个新的超时缓存
     *
     * @param expireTime: 缓存项过期后的持续时间
     * @param timeoutFn: 项过期时调用的回调函数，包含键和值
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
     * 向缓存中添加或更新值
     *
     * @param k: 键
     * @param v: 要缓存的值
     */
    public func add(k: K, v: V): Unit {
        _map.add(k, CacheItem(v, DateTime.now()))
    }

    /**
     * 从缓存中获取值
     *
     * @param k: 键
     * @return: 缓存值（如果存在且未过期），否则返回 None
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
