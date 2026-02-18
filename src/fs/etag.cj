/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.fs

import std.time.DateTime

/**
 * 用于解析和生成 HTTP ETags 的工具类
 */
class JoyHttpEtag {
    private static let PREFIX = "W/"

    /**
     * 检查两个 ETag 是否强匹配
     *
     * @param a 要比较的第一个 ETag
     * @param b 要比较的第二个 ETag
     * @return 如果 ETag 强匹配返回 True，否则返回 False
     */
    static func strongMatch(a: String, b: String): Bool {
        a == b && a != "" && a[0] == b'"'
    }

    /**
     * 检查两个 ETag 是否弱匹配
     *
     * @param a 要比较的第一个 ETag
     * @param b 要比较的第二个 ETag
     * @return 如果 ETag 弱匹配返回 True，否则返回 False
     */
    static func weakMatch(a: String, b: String): Bool {
        a.trimStart(PREFIX) == b.trimStart(PREFIX)
    }

    /**
     * 基于文件大小和修改时间生成 ETag
     *
     * @param size 文件大小（字节）
     * @param modTime 文件修改时间
     * @return 生成的 ETag 字符串
     */
    static func generate(size: Int64, modTime: DateTime): String {
        // 简单处理，使用文件大小、修改时间和文件名生成ETag
        let sizeStr = size.toString()
        let timeStr = modTime.toUnixTimeStamp().toSeconds().toString()
        "\"${sizeStr}-${timeStr}\""
    }

    /**
     * 扫描字符串以提取 ETag
     *
     * @param str 要扫描 ETag 的字符串
     * @return 包含（提取的 ETag，剩余字符串）的元组
     */
    static func scan(str: String): (String, String) {
        // ETag is either W/"text" or "text"
        // See RFC 7232 2.3.
        let x = str.trimAscii()
        var start = 0
        if (x.startsWith(PREFIX)) {
            start = 2
        }

        let s = x[start..]
        if (s.size < 2 || x[start] != b'"') {
            return ("", "")
        }

        var i = start + 1
        while (i < x.size) {
            let c = x[i]
            match {
                case c == b'"' => return (x[..i + 1], x[i + 1..])
                case c == 0x21 || c >= 0x23 && c <= 0x7E || c >= 0x80 => ()
                case _ => return ("", "")
            }
            i++
        }

        ("", "")
    }
}
