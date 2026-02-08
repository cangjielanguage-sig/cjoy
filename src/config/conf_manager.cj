/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.config

import std.collection.{ArrayList, HashMap, Map}
import std.sort.sort
import std.env.getVariables
import cjoy.bind.{JoyBindable, MapContainer}
import cjoy.context.ServiceContainer
import cjoy.log.macros.*

class ConfigData <: ToString {
    ConfigData(let data: Map<String, Any>, let priority: Int) {
    }

    public func toString(): String {
        "{data:${MapContainer.mapToString(data)},priority:${priority}}"
    }

    func copy(other: ConfigData): Unit {
        copy(other.data, data)
    }

    func copy(src: Map<String, Any>, dest: Map<String, Any>): Unit {
        for ((k, v) in src) {
            match (v) {
                case x: Map<String, Any> => match (dest.get(k)) {
                    case Some(y) => match (y) {
                        case y: Map<String, Any> =>
                            let m = HashMap<String, Any>()
                            m.add(all: y)
                            dest[k] = m
                            copy(x, m)
                        case _ =>
                            let m = HashMap<String, Any>()
                            dest[k] = m
                            copy(x, m)
                    }
                    case _ =>
                        let m = HashMap<String, Any>()
                        dest[k] = m
                        copy(x, m)
                }
                case _ => dest[k] = v
            }
        }
    }
}

/**
 * Central configuration manager that loads and provides access to configuration values
 * Supports multiple configuration sources with priority-based override
 * Environment variables have the highest priority
 */
public class ConfigManager <: Config {
    /**
     * Singleton instance of the config manager
     */
    public static let INSTANCE: Config = ConfigManager()

    private let envData = HashMap<String, String>()
    private let data = ArrayList<ConfigData>()

    init() {
        // 加载环境变量，环境变量优先级最高
        let envVars = getVariables()
        for ((key, value) in envVars) {
            envData.add(key, value)
        }
        // 第一个为合并所有配置源的配置集
        data.add(ConfigData(HashMap<String, Any>(), Int64.Max))
    }

    public func hashKey(key: String): Bool {
        if (envData.contains(key)) {
            return true
        }

        let cfgKey = splitKey(convertKey(key))
        for (d in data) {
            if (let Some(v) <- getDataValue(d.data, cfgKey)) {
                return true
            }
        }
        false
    }

    public func getValue(key: String): ?String {
        match (getValueInner(key)) {
            case Some(val) =>
                if (val.startsWith(#"${"#)) {
                    resolve(val)
                } else {
                    val
                }
            case _ => None
        }
    }

    public func getValue(key: String, defaultValue: String): String {
        getValue(key) ?? defaultValue
    }

    private func getValueInner(key: String): ?String {
        let v = envData.get(key)
        match (v) {
            case Some(x) => x
            case _ =>
                let cfgKey = splitKey(convertKey(key))
                for (d in data) {
                    let val = getDataValue(d.data, cfgKey)
                    if (let Some(v) <- getStringValue(val)) {
                        return v
                    }
                }
                None
        }
    }

    public func bind<T>(key: String): ?T where T <: JoyBindable<T> {
        let v = envData.get(key)
        match (v) {
            case Some(x) => T.bind(envData, key, None, None)
            case _ => bindInner<T>(key)
        }
    }

    private func bindInner<T>(key: String): Option<T> where T <: JoyBindable<T> {
        let cfgKey = splitKey(convertKey(key))
        let map = HashMap<String, Any>()
        let container = MapContainer(map)
        for (d in data) {
            if (let Some(val) <- getDataValue(d.data, cfgKey)) {
                map["obj"] = val
                @JoyLogInfo("[Config] bind data is ${container}")
                let obj = T.bind(container, "obj", None, None)
                if (let Some(y) <- obj) {
                    return y
                }
            }
        }
        None
    }

    public func resolve(exp: String): String {
        ResolveHelp(this).resolveString(exp)
    }

    public func addLoader(loaders: Array<ConfigLoader>): Unit {
        for (loader in loaders) {
            let ld = loader.load()
            let cd = ConfigData(ld, loader.priority)
            @JoyLogDebug("[Config] load data ${cd}")
            data.add(cd)
        }

        if (data.size > 1) {
            sort(data, by: {a, b => b.priority.compare(a.priority)}, stable: true)
            // 依次把级别低到最高的容器中
            for (i in (data.size - 1)..0 : -1) {
                data[0].copy(data[i])
            }
        }
    }
}

private let _: Unit = ServiceContainer.GLOBAL.addService("config", ConfigManager.INSTANCE)
