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

import std.collection.{HashMap}
import cjoy.log.macros.*

/**
 * 参数绑定的接口。
 *
 * 支持将 HTTP 请求查询参数、表单数据或头信息绑定到类型化对象。
 * 支持简单类型、数组和复杂嵌套结构。
 */
public interface JoyBindable<T> {
    /**
     * 将 HTTP 请求查询、POST 表单或头参数绑定到对象。
     *
     * @param source 绑定源对象
     * @param name 绑定字段名
     * @param defaultValue 字段默认值
     * @param timeformat 日期时间字段格式
     * @return 对象，如果绑定失败则返回 None
     */
    static func bind(source: JoyBindSource, name: String, defaultValue: ?String, timeformat: ?String): ?T
    static func bind(source: JoyBindSource, name: String, defaultValue: ?String): ?T {
        bind(source, name, defaultValue, None)
    }
    static func bind(source: JoyBindSource, name: String): ?T {
        bind(source, name, None, None)
    }
    /**
     * 将 HTTP 请求查询、POST 表单或头参数绑定到具有复杂结构的对象。
     *
     * 通过将值视为映射或集合并递归绑定来支持嵌套字段。
     *
     * @param source 绑定源对象
     * @param name 绑定字段名，可以是嵌套字段
     * @return 对象，如果绑定失败则返回 None
     */
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
                        @JoyLogDebug("[Bind] not found bind source data for ${name}")
                        None
                }
        }
    }
}

/**
 * 绑定源的接口，JoyBindable 可以从源获取值。
 *
 * 提供按名称从各种源（如查询参数、表单数据、头信息或映射）
 * 检索单个或多个值的方法。
 */
public interface JoyBindSource {
    /**
     * 从源按名称获取单个值。
     *
     * @param name 值名称
     * @return 值，如果未找到则返回 None
     */
    func getOne<T>(name: String): ?T

    /**
     * 从源按名称获取所有值。
     *
     * @param name 值名称
     * @return 值的集合
     */
    func getList<T>(name: String): Collection<T>
}
