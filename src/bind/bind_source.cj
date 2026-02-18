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
 * 实现 JoyBindSource 的 Map 容器类
 *
 * 为参数绑定提供基于 HashMap 的数据源
 */
public class MapContainer <: JoyBindSource & ToString {
    /**
     * 创建一个新的 MapContainer 实例
     *
     * @param data 地图数据
     */
    public MapContainer(let data: HashMap<String, Any>) {}

    /**
     * 根据名称从源中获取一个值
     *
     * @param name 值的名称
     * @return 值，如果未找到则返回 None
     */
    public func getOne<T>(name: String): ?T {
        let v = data.get(name)
        getValue<Any, T>(v, name)
    }

    /**
     * 根据名称从源中获取所有值
     *
     * @param name 值的名称
     * @return 值的集合
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
     * 转换为字符串表示
     *
     * @return 字符串表示
     */
    public func toString(): String {
        mapToString(data)
    }

    /**
     * 将地图转换为字符串
     *
     * @param data 地图数据
     * @return 字符串表示
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
     * 将集合转换为字符串
     *
     * @param data 集合数据
     * @return 字符串表示
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
 * 扩展 Form 类以实现 JoyBindSource，用于表单数据绑定
 */
extend Form <: JoyBindSource {
    /**
     * 从表单中获取一个值
     *
     * @param name 值的名称
     * @return 值，如果未找到则返回 None
     */
    public func getOne<T>(name: String): ?T {
        let v = this.get(name)
        getValue<String, T>(v, name)
    }

    /**
     * 从表单中获取所有值
     *
     * @param name 值的名称
     * @return 值的集合
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
 * 扩展 HttpHeaders 类以实现 JoyBindSource，用于请求头绑定
 */
extend HttpHeaders <: JoyBindSource {
    /**
     * 从请求头中获取一个值
     *
     * @param name 请求头名称
     * @return 请求头值，如果未找到则返回 None
     */
    public func getOne<T>(name: String): ?T {
        let v = this.getFirst(name)
        getValue<String, T>(v, name)
    }

    /**
     * 从请求头中获取所有值
     *
     * @param name 请求头名称
     * @return 请求头值的集合
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
 * 扩展 HashMap<String, String> 类以实现 JoyBindSource，用于地图绑定
 */
extend HashMap<String, String> <: JoyBindSource {
    /**
     * 从 HashMap 中获取一个值
     *
     * @param name 键名称
     * @return 值，如果未找到则返回 None
     */
    public func getOne<T>(name: String): ?T {
        let v = this.get(name)
        getValue<String, T>(v, name)
    }

    /**
     * 从 HashMap 获取列表（始终返回空）
     *
     * @param _ 键名称（未使用）
     * @return 空集合
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
