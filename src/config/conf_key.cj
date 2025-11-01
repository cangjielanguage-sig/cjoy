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

import std.collection.{Map, HashMap, ArrayList, map, collectArray}
import std.convert.Parsable
import cjoy.utils.snakeCase
import cjoy.log.*

public class ConfigKey <: ToString {
    ConfigKey(public let key: String, public let arrIdx: Int, public var sub: ?ConfigKey) {
    }

    public func toString(): String {
        var str = "(${key},${arrIdx})"
        if (let Some(ck) <- sub) {
            str += ck.toString()
        }
        str
    }
}

func transferKey(key: String): String {
    snakeCase(key)
}

public func transferKeys(data: Map<String, Any>): Unit {
    let iter = data.iterator()
    let map = HashMap<String, Any>()
    while (let Some((k, v)) <- iter.next()) {
        let tk = transferKey(k)
        if (k != tk) {
            map.add(tk, data[k])
        }
        match (v) {
            case x: Map<String, Any> => transferKeys(x)
            case _ => ()
        }
    }
    data.add(all: map)
}

/**
 * @throws ConfigException if the index is out range
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
 * split key to ConfigKey
 *
 * @throws ConfigException if the key is invalid
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

    @LogDebug("[Config] split ${key} to ${cfgKey}")
    cfgKey
}
