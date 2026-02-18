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
 * 用于键值存储和服务检索的上下文接口。
 *
 * 提供使用字符串键存储和检索任意数据的机制，
 * 以及从全局服务容器访问已注册服务的能力。
 */
public interface Context {
    /**
     * 在上下文中设置参数。
     *
     * @param key 参数键名
     * @param value 参数值
     */
    func set(key: String, value: Any): Unit

    /**
     * 从上下文中获取参数。
     *
     * @param key 参数键名
     * @return 参数值，如果未找到则返回 None
     */
    func get<T>(key: String): ?T

    /**
     * 从上下文中移除参数。
     *
     * @param key 参数键名
     */
    func remove(key: String): Unit

    /**
     * 从上下文中获取服务。
     *
     * @param name 服务名称
     * @return 服务实例，如果未找到则返回 None
     */
    func getService<T>(name: String): ?T

    /**
     * 从上下文中获取服务，如果未找到则抛出异常。
     *
     * @param name 服务名称
     * @return 服务实例
     * @throws OptionError 如果未找到服务
     */
    func mustService<T>(name: String): T {
        getService<T>(name).getOrThrow()
    }
}

/**
 * 使用 ConcurrentHashMap 的基于映射的上下文实现。
 *
 * 为键值对提供线程安全的存储，并将
 * 服务查找委托给全局 ServiceContainer。
 */
public open class MapContext <: Context {
    private let _data: ConcurrentHashMap<String, Any> = ConcurrentHashMap()

    /**
     * 在上下文中设置参数。
     *
     * @param key 参数键名
     * @param value 参数值
     */
    public func set(key: String, value: Any): Unit {
        _data.add(key, value)
    }

    /**
     * 从上下文中获取参数。
     *
     * @param key 参数键名
     * @return 参数值，如果未找到则返回 None
     */
    public func get<T>(key: String): ?T {
        (_data.get(key) ?? Option<Any>.None) as T
    }

    /**
     * 从上下文中移除参数。
     *
     * @param key 参数键名
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
