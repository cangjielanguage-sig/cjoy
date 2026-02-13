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
 * Service container for managing and retrieving service instances.
 *
 * Provides a global service registry that allows storing and retrieving
 * services by name, enabling dependency injection and service lookup patterns.
 */
public class ServiceContainer {
    public static let GLOBAL: ServiceContainer = ServiceContainer()
    private let _services: ConcurrentHashMap<String, Any> = ConcurrentHashMap()

    /**
     * Add service to container.
     *
     * @param name the service name
     * @param service the service instance
     */
    public func addService(name: String, service: Any): Unit {
        _services.add(name, service)
    }

    /**
     * Get service instance from container.
     *
     * @param name the service name
     * @return the service instance of type T, or None if not found
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
