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

import std.collection.{Map}
import cjoy.bind.JoyBindable

/*
 * the config manger api
 *
 * the key of config support env variable and a multi level key separated with `.`, e.g:
 * - single level key:
 *   - abc, cdf
 * - multi level key:
 *   - a.b.c
 * - array key:
 *   - a[0], a[1]
 *   - a.b[0].c, a.b[1].c
 * - env variable:
 *  - HOME, USER
 *
 * if the key contains uppercase letter, it will be converted to underline+lowercase, e.g:
 *   - aBc -> a_bc
 *   - aBC -> a_bc
 */
public interface Config {
    /**
     * return true if the key is existed
     */
    func hashKey(key: String): Bool

    /**
     * get value by key
     */
    func getValue(key: String): ?String

    /**
     * get value by key with default value
     */
    func getValue(key: String, defaultValue: String): String

    /**
     * bind config to object
     */
    func bind<T>(key: String): ?T where T <: JoyBindable<T>

    /**
     * resolves config values into a string, eg: ${host}:${port} -> 127.0.0.1:18881
     */
    func resolve(exp: String): String

    /**
     * add config loaders
     */
    func addLoader(loaders: Array<ConfigLoader>): Unit
}

public interface ConfigLoader {
    /**
     * load configs to map
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
