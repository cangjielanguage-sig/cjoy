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

import std.collection.{Map, List, HashMap, ArrayList}

/**
 * 将键和值添加到数据
 */
public func addToData(data: Map<String, Any>, key: String, cfgKey: ConfigKey, value: String): Unit {
    // 有子节点
    if (let Some(subKey) <- cfgKey.sub) {
        return match (data.get(cfgKey.key)) {
            case Some(sm) => addSubToDataExist(sm, key, cfgKey, subKey, value) // 已存在
            case _ => addSubToDataFirst(data, key, cfgKey, subKey, value) // 首次
        }
    }

    // 尾节点
    addLastToData(data, key, cfgKey, value)
}

/**
 * @throws ConfigException 如果键或值无效
 */
private func addSubToDataExist(sm: Any, key: String, cfgKey: ConfigKey, subKey: ConfigKey, value: String): Unit {
    // 不是数组配置
    if (cfgKey.arrIdx == -1) {
        match (sm) {
            case x: Map<String, Any> => addToData(x, key, subKey, value)
            case _ => throw ConfigException("invalid config, the key `${key}` is conflict")
        }
        return
    }

    // 数组配置
    match (sm) {
        case x: List<Any> =>
            if (cfgKey.arrIdx >= x.size) {
                // 扩充
                for (_ in x.size..(cfgKey.arrIdx + 1)) {
                    x.add(HashMap<String, Any>())
                }
            }
            let slot = x[cfgKey.arrIdx]
            if (slot is Option<Any>) {
                // 空槽位可以回填子 map，与叶子节点的空槽处理保持一致
                let map = HashMap<String, Any>()
                x[cfgKey.arrIdx] = map
                addToData(map, key, subKey, value)
                return
            }
            let map = (slot as Map<String, Any>) ?? throw ConfigException(
                "invalid config, the key `${key}` is conflict")
            addToData(map, key, subKey, value)
        case _ => throw ConfigException("invalid config, the key `${key}` is conflict")
    }
}

private func addSubToDataFirst(data: Map<String, Any>, key: String, cfgKey: ConfigKey, subKey: ConfigKey, value: String): Unit {
    // 不是数组配置
    if (cfgKey.arrIdx == -1) {
        let map = HashMap<String, Any>()
        data.add(cfgKey.key, map)
        addToData(map, key, subKey, value)
        return
    }

    // 数组配置
    let arr = ArrayList<Any>(cfgKey.arrIdx + 1, {_ => Option<Any>.None})
    let map = HashMap<String, Any>()
    arr[cfgKey.arrIdx] = map
    data.add(cfgKey.key, arr)
    addToData(map, key, subKey, value)
}

/**
 * @throws ConfigException 如果键或值无效
 */
private func addLastToData(data: Map<String, Any>, key: String, cfgKey: ConfigKey, value: String): Unit {
    // 不是数组配置，后面的覆盖前面的
    if (cfgKey.arrIdx == -1) {
        if (data.addIfAbsent(cfgKey.key, value).isSome()) {
            throw ConfigException("invalid config, the key `${key}` is overwrite")
        }
        return
    }

    // 数组配置
    let val = data.get(cfgKey.key)
    match (val) {
        case Some(v) => match (v) {
            case arr: List<Any> =>
                if (cfgKey.arrIdx < arr.size && !(arr[cfgKey.arrIdx] is Option<Any>)) {
                    throw ConfigException("invalid config, the key `${key}` is overwrite")
                }
                if (cfgKey.arrIdx >= arr.size) { // 需要扩充
                    for (_ in arr.size..(cfgKey.arrIdx + 1)) {
                        arr.add(Option<Any>.None)
                    }
                }
                arr[cfgKey.arrIdx] = value
            case _ => throw ConfigException("invalid config, the key `${key}` is conflict")
        }
        case _ =>
            // 不存在
            let arr = ArrayList<Any>(cfgKey.arrIdx + 1, {_ => Option<Any>.None})
            arr[cfgKey.arrIdx] = value
            data.add(cfgKey.key, arr)
    }
}

/**
 * 从 MapData 中获取对应的值，支持 key 采用前缀获取
 */
func getDataValue(data: Map<String, Any>, cfgKey: ConfigKey): ?Any {
    if (let Some(sub) <- cfgKey.sub) {
        return getSubDataValue(data, cfgKey, sub)
    }
    // 尾节点
    getLastDataValue(data, cfgKey)
}

private func getSubDataValue(data: Map<String, Any>, cfgKey: ConfigKey, sub: ConfigKey): ?Any {
    let val = data.get(cfgKey.key)
    match (val) {
        case Some(v) =>
            if (cfgKey.arrIdx == -1) {
                getSubDataValueFromMap(v, sub)
            } else {
                getSubDataValueFromArray(v, cfgKey, sub)
            }
        case _ => None
    }
}

private func getSubDataValueFromMap(val: Any, sub: ConfigKey): ?Any {
    match (val) {
        case x: Map<String, Any> => getDataValue(x, sub)
        case _ => None
    }
}

private func getSubDataValueFromArray(val: Any, cfgKey: ConfigKey, sub: ConfigKey): ?Any {
    match (val) {
        case x: List<Any> =>
            if (cfgKey.arrIdx >= x.size) {
                return None
            }
            match (x.get(cfgKey.arrIdx)) {
                case Some(v) => match (v) {
                    case x: Map<String, Any> => getDataValue(x, sub)
                    case _ => None
                }
                case _ => None
            }
        case _ => None
    }
}

private func getLastDataValue(data: Map<String, Any>, cfgKey: ConfigKey): ?Any {
    let val = data.get(cfgKey.key)
    if (cfgKey.arrIdx == -1) {
        return val
    }
    getLastDataValueFromArray(val, cfgKey)
}

private func getLastDataValueFromArray(val: ?Any, cfgKey: ConfigKey): ?Any {
    match (val) {
        case Some(v) =>
            if (v is Option<Any>) {
                // 数组空洞中的 Option.None 哨兵不代表有效配置
                return None
            }
            match (v) {
                case x: List<Any> =>
                    if (cfgKey.arrIdx < x.size) {
                        let elem = x[cfgKey.arrIdx]
                        if (elem is Option<Any>) {
                            return None
                        }
                        return Some(elem)
                    }
                    None
                case _ => None
            }
        case _ => None
    }
}

func getStringValue(val: ?Any): ?String {
    match (val) {
        case Some(v) =>
            if (v is Option<Any>) {
                return None
            }
            match (v) {
                case x: ToString => x.toString()
                case _ => None
            }
        case _ => None
    }
}

class ResolveHelp {
    ResolveHelp(let cfg: Config) {}

    /**
     * 解释配置表达式，如${a.b.c:default}，或者${HOME:/home/xiao}，HOME从环境变量获取
     *
     * @throws ConfigException the config express is invalid
     */
    func resolveString(str: String): String {
        resolveString(str, 0)
    }

    private func resolveString(str: String, depth: Int): String {
        if (depth > 10) {
            // 循环引用
            throw ConfigException("the config express is invalid, circular reference, ${str}")
        }
        if (str.isEmpty()) {
            return str
        }
        let start = str.indexOf(#"${"#) ?? -1
        if (start < 0) {
            return str
        }

        var level = 1
        var end = -1
        for (idx in (start + 2)..str.size) {
            if (str[idx] == b'$') {
                if (idx + 1 < str.size && str[idx + 1] == b'{') {
                    level += 1
                }
            } else if (str[idx] == b'}') {
                level -= 1
                if (level == 0) {
                    end = idx
                    break
                }
            }
        }

        if (end < 0) {
            throw ConfigException("the config express is invalid, ${str}")
        }

        let resolved = resolveToValue(str[(start + 2)..end], depth)
        let suffix = resolveString(str[end + 1..], depth)
        str[..start] + resolved + suffix
    }

    /**
     * @throws ConfigException if the config express is invalid
     */
    private func resolveToValue(key: String, depth: Int): String {
        let start = key.indexOf(":") ?? -1
        var rk = key
        var defVal = "//@@//"

        if (start > 0) {
            rk = key[0..start]
            defVal = key[start + 1..]
        }

        let val = cfg.getValue(rk, defVal)
        if (val == "\${${rk}}" || val.startsWith("\${${rk}:")) {
            // 循环引用
            throw ConfigException("the config express is invalid, circular reference, ${key}")
        }
        if (val != "//@@//") {
            return resolveString(val, depth + 1)
        }
        ""
    }
}
