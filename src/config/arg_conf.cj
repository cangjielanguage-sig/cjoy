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

import std.collection.{HashMap, Map}

/**
 * 应用程序命令行参数配置
 */
public class ArgConfigLoader <: ConfigLoader {
    public ArgConfigLoader(let args: Array<String>, let priorityNum!: Int = 50) {}

    /**
     * @throws ConfigException 如果配置表达式无效
     */
    public func load(): Map<String, Any> {
        let data = HashMap<String, Any>()
        for (arg in args) {
            if (arg.startsWith("-D") && let Some(pos) <- arg.indexOf("=") && pos > 2) {
                // 需要考虑value中存在=
                let key = arg[2..pos]
                let value = arg[(pos + 1)..]
                if (value == "\${${key}}" || value.startsWith("\${${key}:")) {
                    // 循环引用
                    throw ConfigException("the config express is invalid, circular reference, ${key}")
                }
                let cfgKey = splitKey(key)
                addToData(data, arg, cfgKey, value)
            }
        }
        convertKeys(data)
        data
    }

    public prop priority: Int {
        get() {
            priorityNum
        }
    }
}
