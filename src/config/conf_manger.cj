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

import std.collection.{ArrayList, HashMap, Map}
import std.sync.Mutex
import std.sort.sort
import std.env.getVariables
import cjoy.bind.{JoyBindable, MapContainer}

class ConfigData {
    ConfigData(let data: Map<String, Any>, let priority: Int) {
    }
}

public class ConfigManager <: Config {
    private let envData = HashMap<String, String>()
    private let data = ArrayList<ConfigData>()

    init() {
        // 加载环境变量，环境变量优先级最高
        let envVars = getVariables()
        for ((key, value) in envVars) {
            envData.add(key, value)
        }
    }

    public func hashKey(key: String): Bool {
        if (envData.contains(key)) {
            return true
        }

        let cfgKey = splitKey(transferKey(key))
        for (d in data) {
            let val = getDataValue(d.data, cfgKey)
            if (let Some(v) <- val) {
                return true
            }
        }
        false
    }

    public func getValue(key: String): ?String {
        let v = envData.get(key)
        match (v) {
            case Some(x) => x
            case _ =>
                let cfgKey = splitKey(transferKey(key))
                for (d in data) {
                    let val = getDataValue(d.data, cfgKey)
                    if (let Some(v) <- getStringValue(val)) {
                        return v
                    }
                }
                None
        }
    }

    public func getValue(key: String, defaultValue: String): String {
        getValue(key) ?? defaultValue
    }

    public func bind<T>(key: String): ?T where T <: JoyBindable<T> {
        let v = envData.get(key)
        match (v) {
            case Some(x) => T.bind(envData, key)
            case _ =>
                let cfgKey = splitKey(transferKey(key))
                for (d in data) {
                    let val = getDataValue(d.data, cfgKey)
                    match (val) {
                        case Some(v) =>
                            let container = MapContainer(HashMap<String, Any>([("", v)]))
                            return T.bind(container, "")
                        case _ => ()
                    }
                }
                None
        }
    }

    public func resolve(exp: String): String {
        resolveString(this, exp)
    }

    public func addLoader(loader: ConfigLoader): Unit {
        let ld = loader.load()
        data.add(ConfigData(ld, loader.priority))
        sort(data,
            by: {
                a, b => if (a.priority < b.priority) {
                    Ordering.LT
                } else if (a.priority > b.priority) {
                    Ordering.GT
                } else {
                    Ordering.EQ
                }
            }, stable: true)
    }
}
