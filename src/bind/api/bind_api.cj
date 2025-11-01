/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.bind.api

import std.collection.{HashMap}
import cjoy.log.*

/**
 * the interface of binding
 */
public interface JoyBindable<T> {
    /**
     *
     * bind http request query, postform or header params to object
     *
     * @param source: the bind source object
     * @param name: the name of bind field
     * @param defaultValue: the default value of field
     * @param timeformat: the datetime field format
     * @return: the object
     */
    static func bind(source: JoyBindSource, name: String, defaultValue: ?String, timeformat: ?String): ?T
    static func bind(source: JoyBindSource, name: String, defaultValue: ?String): ?T {
        bind(source, name, defaultValue, None)
    }
    static func bind(source: JoyBindSource, name: String): ?T {
        bind(source, name, None, None)
    }
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
                        @LogDebug("[Bind] not found bind source data for ${name}")
                        None
                }
        }
    }
}

/**
 * the interface of bind source, JoyBindable can get value from the source
 */
public interface JoyBindSource {
    /**
     * get one value by name from source
     */
    func getOne<T>(name: String): ?T

    /**
     * get all values by name from source
     */
    func getList<T>(name: String): Collection<T>
}
