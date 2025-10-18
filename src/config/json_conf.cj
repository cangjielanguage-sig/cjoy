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

import std.collection.{HashMap, ArrayList, Map}
import std.fs.{File, OpenMode}
import std.io.{ByteBuffer, readToEnd}
import stdx.encoding.json.stream.{JsonReader}
import cjoy.json.JsonTool

/**
 * json file config
 */
public class JsonConfigLoader <: ConfigLoader {
    public JsonConfigLoader(let filePath: String) {}

    public func load(): Map<String, Any> {
        let data = HashMap<String, Any>()
        try (fs: File = File(filePath, OpenMode.Read)) {
            var stream = ByteBuffer()
            stream.write(readToEnd(fs))
            let reader = JsonReader(stream)
            let d = JsonTool.fromJsonToAny(reader)
            match (d) {
                case x: Map<String, Any> => data.add(all: x)
                case _ => ()
            }
        }
        transferKeys(data)
        data
    }

    public prop priority: Int {
        get() {
            1
        }
    }
}
