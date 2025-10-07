/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.framework

import std.collection.concurrent.ConcurrentHashMap

/**
 * service conainter
 */
public class ServiceConainter {
    private let _services: ConcurrentHashMap<String, Any> = ConcurrentHashMap()

    public func addService(name: String, service: Any): Unit {
        _services.add(name, service)
    }

    public func getService<T>(name: String): ?T {
        (_services.get(name) ?? Option<Any>.None) as T
    }

    func addServicesFrom(sc: ServiceConainter): Unit {
        for ((k, v) in sc._services) {
            _services.add(k, v)
        }
    }
}

public let DEFAULT_SERVICE_CONTAINER: ServiceConainter = ServiceConainter()
