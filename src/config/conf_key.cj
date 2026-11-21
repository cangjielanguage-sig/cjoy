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
import std.convert.Parsable
import cjoy.utils.snakeCase
import cjoy.log.macros.*

/**
 * 表示解析后的配置键，支持嵌套键和数组索引
 *
 * @param key: 键段名称
 * @param arrIdx: 数组索引，如果不是数组则为 -1
 * @param sub: 嵌套键的下一个键段
 */
public class ConfigKey <: ToString {
    ConfigKey(public let key: String, public let arrIdx: Int, public var sub: ?ConfigKey) {
    }

    /**
     * 返回此配置键的字符串表示
     */
    public func toString(): String {
        var str = "(${key},${arrIdx})"
        if (let Some(ck) <- sub) {
            str += ck.toString()
        }
        str
    }
}

func convertKey(key: String): String {
    snakeCase(key)
}

/**
 * 将配置映射中的所有键递归转换为 snake_case 格式
 * 这将把 camelCase 键转换为 snake_case（例如，"userName" -> "user_name"）
 *
 * @param data: 要转换键的配置映射
 */
public func convertKeys(data: Map<String, Any>): Unit {
    let iter = data.iterator()
    let map = HashMap<String, Any>()
    let removed = ArrayList<String>()
    while (let Some((k, v)) <- iter.next()) {
        let tk = convertKey(k)
        if (k != tk) {
            removed.add(k)
            map.add(tk, v)
        }
        match (v) {
            case x: Map<String, Any> => convertKeys(x)
            case x: List<Any> =>
                // 数组中的对象同样需要转换键名
                for (item in x) {
                    match (item) {
                        case m: Map<String, Any> => convertKeys(m)
                        case _ => ()
                    }
                }
            case _ => ()
        }
    }
    for (k in removed) {
        data.remove(k)
    }
    for ((k, v) in map) {
        data.addIfAbsent(k, v)
    }
}

/**
 * @throws ConfigException 如果索引超出范围
 */
private func oneKeySeg(str: String): (String, Int) {
    let start = str.indexOf("[") ?? -1
    let end = str.indexOf("]") ?? -1
    if (start > 0 && end > start) {
        let key = str[..start]
        let idx = Int.tryParse(str[(start + 1)..end]) ?? throw ConfigException("invalid index in ${str}")
        if (idx < 0 || idx > 50) {
            throw ConfigException("index of array must in [0,50] for ${str}")
        }
        return (key, idx)
    } else if (start > 0 && end <= start) {
        throw ConfigException("invalid index in ${str}")
    }
    (str, -1)
}

/**
 * 将键分割为 ConfigKey
 *
 * @throws ConfigException 如果键无效
 */
public func splitKey(key: String): ConfigKey {
    let exist = key.indexOf(".") ?? -1
    if (exist < 0) {
        let (seg, arrIdx) = oneKeySeg(key)
        return ConfigKey(seg, arrIdx, None)
    } else if (exist == 0) {
        throw ConfigException("key key is invalid, can not start with `.`")
    }

    let arr = key.split(".")
    let (seg, arrIdx) = oneKeySeg(arr[0])
    let cfgKey = ConfigKey(seg, arrIdx, None)
    var temp = cfgKey
    for (idx in 1..arr.size) {
        let (seg, arrIdx) = oneKeySeg(arr[idx])
        let sub = ConfigKey(seg, arrIdx, None)
        temp.sub = sub
        temp = sub
    }

    @JoyLogDebug("[Config] split ${key} to ${cfgKey}")
    cfgKey
}
