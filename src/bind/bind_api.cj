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
 * The interface for parameter binding.
 *
 * Enables binding of HTTP request query parameters, form data, or headers to typed objects.
 * Supports simple types, arrays, and complex nested structures.
 */
public interface JoyBindable<T> {
    /**
     * Bind HTTP request query, post form or header params to object.
     *
     * @param source the bind source object
     * @param name the name of bind field
     * @param defaultValue the default value of field
     * @param timeformat the datetime field format
     * @return the object, or None if binding fails
     */
    static func bind(source: JoyBindSource, name: String, defaultValue: ?String, timeformat: ?String): ?T
    static func bind(source: JoyBindSource, name: String, defaultValue: ?String): ?T {
        bind(source, name, defaultValue, None)
    }
    static func bind(source: JoyBindSource, name: String): ?T {
        bind(source, name, None, None)
    }
    /**
     * Bind HTTP request query, post form or header params to object with complex structure.
     *
     * Supports nested fields by treating the value as a map or collection and recursively binding.
     *
     * @param source the bind source object
     * @param name the name of bind field, can be a nested field
     * @return the object, or None if binding fails
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
 * The interface for bind source, JoyBindable can get value from the source.
 *
 * Provides methods to retrieve single or multiple values by name from various sources
 * such as query parameters, form data, headers, or maps.
 */
public interface JoyBindSource {
    /**
     * Get one value by name from source.
     *
     * @param name the value name
     * @return the value, or None if not found
     */
    func getOne<T>(name: String): ?T

    /**
     * Get all values by name from source.
     *
     * @param name the value name
     * @return the collection of values
     */
    func getList<T>(name: String): Collection<T>
}
