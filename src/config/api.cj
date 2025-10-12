/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.config

import std.collection.{Map, ArrayList}
import std.convert.Parsable

public interface Config {
    func allData(): Map<String, Any>

    func hashKey(key: String): Bool
    func getValue(key: String): ?String
    func getValue(key: String, defaultValue: String): String

    func getValueAs<T>(key: String): ?T where T <: Parsable<T>
    func getValueAs<T>(key: String, defaultValue: T): ?T where T <: Parsable<T>
    func getListValueAs<T>(key: String): ArrayList<T> where T <: Parsable<T>

    /**
     * resolves config values into a string, eg: ${host}:${port} -> 127.0.0.1:18881
     */
    func resolve(exp: String): String
}

public interface ConfigLoader {
    /**
     * load confs to map
     */
    func load(): Map<String, Any>

    /**
     * high priority will overwrite the config item value whit low priority
     */
    prop priority: Int
}

public class ConfigException <: Exception {
    public ConfigException(message: String) {
        super(message)
    }
}
