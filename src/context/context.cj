/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
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
 * the contenxt interface
 */
public interface Context {
    /**
     * set param in context
     *
     * @param key: the param key name
     * @param value: the param value
     *
     */
    func set(key: String, value: Any): Unit

    /**
     * get param from context
     *
     * @param key: the param key name
     * @return the param value
     */
    func get<T>(key: String): ?T

    /**
     * remove param from context
     *
     * @param key: the param key name
     */
    func remove(key: String): Unit

    /**
     * get the service from context
     *
     * @param name: the name of service
     * @return the service instance
     */
    func getService<T>(name: String): ?T

    func mustService<T>(name: String): T {
        getService<T>(name).getOrThrow()
    }
}

public open class MapContext <: Context {
    private let _data: ConcurrentHashMap<String, Any> = ConcurrentHashMap()

    public func set(key: String, value: Any): Unit {
        _data.add(key, value)
    }

    public func get<T>(key: String): ?T {
        (_data.get(key) ?? Option<Any>.None) as T
    }

    public func remove(key: String): Unit {
        _data.remove(key)
    }

    public open func getService<T>(name: String): ?T {
        ServiceConainter.GLOBAL.getService<T>(name)
    }
}
