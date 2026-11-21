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
import std.fs.{File, OpenMode}
import std.io.StringReader

/**
 * Properties 文件配置
 */
public class PropertiesConfigLoader <: ConfigLoader {
    public PropertiesConfigLoader(let filePath: String, let priorityNum!: Int = 0) {}

    public func load(): Map<String, Any> {
        let data = HashMap<String, Any>()
        try (fs: File = File(filePath, OpenMode.Read)) {
            var reader = StringReader(fs)
            while (let Some(line) <- reader.readln()) {
                if (!line.trimAscii().startsWith("#") && let Some(pos) <- line.indexOf("=") && pos > 0) {
                    let key = line[0..pos].trimAscii()
                    // 需要考虑value中存在=
                    let value = line[(pos + 1)..].trimAscii()
                    let cfgKey = splitKey(key)
                    addToData(data, key, cfgKey, value)
                }
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
