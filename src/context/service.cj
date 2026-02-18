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
 * 用于管理和检索服务实例的服务容器。
 *
 * 提供全局服务注册表，允许按名称存储和检索
 * 服务，支持依赖注入和服务查找模式。
 */
public class ServiceContainer {
    public static let GLOBAL: ServiceContainer = ServiceContainer()
    private let _services: ConcurrentHashMap<String, Any> = ConcurrentHashMap()

    /**
     * 向容器添加服务。
     *
     * @param name 服务名称
     * @param service 服务实例
     */
    public func addService(name: String, service: Any): Unit {
        _services.add(name, service)
    }

    /**
     * 从容器获取服务实例。
     *
     * @param name 服务名称
     * @return 类型 T 的服务实例，如果未找到则返回 None
     */
    public func getService<T>(name: String): ?T {
        (_services.get(name) ?? Option<Any>.None) as T
    }

    protected func addServicesFrom(sc: ServiceContainer): Unit {
        for ((k, v) in sc._services) {
            _services.add(k, v)
        }
    }
}
