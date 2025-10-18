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

import std.collection.{HashMap, ArrayList, map, collectArray}
import std.convert.Parsable
import cjoy.log.*

class ConfigKey <: ToString {
    ConfigKey(let key: String, let arrIdx: Int, var sub: ?ConfigKey) {
    }

    public func toString(): String {
        var str = "(${key}, ${arrIdx})"
        if (let Some(ck) <- sub) {
            str += ck.toString()
        }
        str
    }
}

func transferKey(key: String): String {
    let arr = key.toRuneArray()
    let builder = StringBuilder()
    var upper = false
    for (a in arr) {
        if (a.isAsciiUpperCase()) {
            if (!upper) {
                builder.append("-")
            }
            builder.append(a.toAsciiLowerCase())
            upper = true
        } else {
            upper = false
            builder.append(a)
        }
    }
    builder.toString()
}

/**
 * @throws ConfigException
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
 * @throws ConfigException
 */
func splitKey(key: String): ConfigKey {
    let exist = key.indexOf(".") ?? -1
    if (exist < 0) {
        let (seg, arrIdx) = oneKeySeg(key)
        return ConfigKey(seg, arrIdx, None)
    } else if (exist == 0) {
        throw ConfigException("key can not start with `.`")
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
