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

import std.collection.{map, collectArray}
import std.convert.Parsable

class ConfigKey {
    ConfigKey(let key: String, let arrIdx: Int, var sub: ?ConfigKey) {
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
private func oneKeySeg(seg: String): (String, Int) {
    let start = seg.indexOf("[") ?? -1
    let end = seg.indexOf("]") ?? -1
    if (start > 0 && end > start) {
        let segArr = seg.toRuneArray()
        let seg = String(segArr[..start])
        let idx = Int.tryParse(String(segArr[start + 1..end])) ?? throw ConfigException("invalid index in ${seg}")
        return (seg, idx)
    } else if (start > 0 && end <= start) {
        throw ConfigException("invalid index in ${seg}")
    }
    (seg, -1)
}

/**
 * @throws ConfigException
 */
func splitKey(key: String): ConfigKey {
    let exist = key.indexOf(".") ?? -1
    if (exist < 0) {
        return ConfigKey(key, -1, None)
    } else if (exist == 0) {
        throw ConfigException("key can not start with `.`")
    }

    let arr = key.split(".")
    let (seg, arrIdx) = oneKeySeg(arr[0])
    let cfgKey = ConfigKey(seg, arrIdx, None)
    for (idx in 1..arr.size) {
        let (seg, arrIdx) = oneKeySeg(arr[idx])
        cfgKey.sub = ConfigKey(seg, arrIdx, None)
    }
    cfgKey
}

/**
 * @throws ConfigException
 */
func resolveString(cfg: Config, str: String): String {
    let start = str.indexOf(#"${"#) ?? -1
    if (start < 0) {
        return cfg.getValue(str) ?? throw ConfigException("not found key ${str}")
    }

    var level = 1
    var end = -1
    let arr = str.toRuneArray()
    for (idx in (start + 2)..arr.size) {
        if (arr[idx] == Rune(b'$')) {
            if (idx + 1 < arr.size && arr[idx + 1] == Rune(b'{')) {
                level += 1
            }
        } else if (arr[idx] == Rune(b'}')) {
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

    let resolved = resolve(cfg, String(arr[start..(end + 1)]))
    let suffix = resolveString(cfg, String(arr[end + 1..]))
    String(arr[..start]) + resolved + suffix
}

func resolve(cfg: Config, key: String): String {
    let start = key.indexOf(":") ?? -1
    var rk = key
    var defVal = "//@@//"

    if (start > 0) {
        let arr = key.toRuneArray()
        rk = String(arr[0..start])
        defVal = String(arr[start + 1..])
    }

    let val = cfg.getValue(key, defVal)
    if (val != defVal) {
        return resolveString(cfg, val)
    }
    ""
}
