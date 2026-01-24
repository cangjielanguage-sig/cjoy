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

class JoyETag {
    private static let PREFIX = "W/"

    static func strongMatch(a: String, b: String): Bool {
        a == b && a != "" && a[0] == b'"'
    }

    static func weakMatch(a: String, b: String): Bool {
        a.trimStart(PREFIX) == b.trimStart(PREFIX)
    }

    static func scan(str: String): (String, String) {
        // ETag is either W/"text" or "text"
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
