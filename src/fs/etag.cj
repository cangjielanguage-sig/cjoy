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
 * Utility class for parsing and generating HTTP ETags
 */
class JoyHttpEtag {
    private static let PREFIX = "W/"

    /**
     * Checks if two ETags match strongly
     *
     * @param a The first ETag to compare
     * @param b The second ETag to compare
     * @return True if the ETags match strongly, False otherwise
     */
    static func strongMatch(a: String, b: String): Bool {
        a == b && a != "" && a[0] == b'"'
    }

    /**
     * Checks if two ETags match weakly
     *
     * @param a The first ETag to compare
     * @param b The second ETag to compare
     * @return True if the ETags match weakly, False otherwise
     */
    static func weakMatch(a: String, b: String): Bool {
        a.trimStart(PREFIX) == b.trimStart(PREFIX)
    }

    /**
     * Generates an ETag for a file based on size and modification time
     *
     * @param size File size in bytes
     * @param modTime File modification time
     * @return Generated ETag string
     */
    static func generate(size: Int64, modTime: DateTime): String {
        // 简单处理，使用文件大小、修改时间和文件名生成ETag
        let sizeStr = size.toString()
        let timeStr = modTime.toUnixTimeStamp().toSeconds().toString()
        "\"${sizeStr}-${timeStr}\""
    }

    /**
     * Scans a string to extract an ETag
     *
     * @param str The string to scan for an ETag
     * @return Tuple containing (extracted ETag, remaining string)
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
