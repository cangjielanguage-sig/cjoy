/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.context

import std.collection.concurrent.ConcurrentHashMap

/**
 * Context interface for key-value storage and service retrieval.
 *
 * Provides a mechanism to store and retrieve arbitrary data using string keys,
 * as well as access registered services from the global service container.
 */
public interface Context {
    /**
     * Set parameter in context.
     *
     * @param key parameter key name
     * @param value parameter value
     */
    func set(key: String, value: Any): Unit

    /**
     * Get parameter from context.
     *
     * @param key parameter key name
     * @return parameter value, or None if not found
     */
    func get<T>(key: String): ?T

    /**
     * Remove parameter from context.
     *
     * @param key parameter key name
     */
    func remove(key: String): Unit

    /**
     * Get service from context.
     *
     * @param name name of service
     * @return service instance, or None if not found
     */
    func getService<T>(name: String): ?T

    /**
     * Get service from context, throw exception if not found.
     *
     * @param name name of service
     * @return service instance
     * @throws OptionError if service not found
     */
    func mustService<T>(name: String): T {
        getService<T>(name).getOrThrow()
    }
}

/**
 * Map-based context implementation using ConcurrentHashMap.
 *
 * Provides thread-safe storage for key-value pairs and delegates
 * service lookup to the global ServiceContainer.
 */
public open class MapContext <: Context {
    private let _data: ConcurrentHashMap<String, Any> = ConcurrentHashMap()

    /**
     * Set parameter in context.
     *
     * @param key parameter key name
     * @param value parameter value
     */
    public func set(key: String, value: Any): Unit {
        _data.add(key, value)
    }

    /**
     * Get parameter from context.
     *
     * @param key parameter key name
     * @return parameter value, or None if not found
     */
    public func get<T>(key: String): ?T {
        (_data.get(key) ?? Option<Any>.None) as T
    }

    /**
     * Remove parameter from context.
     *
     * @param key parameter key name
     */
    public func remove(key: String): Unit {
        _data.remove(key)
    }

    /**
     * Get service from context.
     *
     * @param name name of service
     * @return service instance, or None if not found
     */
    public open func getService<T>(name: String): ?T {
        ServiceContainer.GLOBAL.getService<T>(name)
    }
}
