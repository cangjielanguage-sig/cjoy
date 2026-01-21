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
    private static let PREFIX = [Rune(b'W'), Rune(b'/')]
    private static let PREFIX2 = "W/"

    static func strongMatch(a: String, b: String): Bool {
        a == b && a != "" && a[0] == b'"'
    }

    static func weakMatch(a: String, b: String): Bool {
        a.trimStart(PREFIX) == b.trimStart(PREFIX)
    }

    static func scan(str: String): (String, String) {
        // ETag is either W/"text" or "text"
        var x = str.trimAscii()
        var start = 0
        if (x.startsWith(PREFIX2)) {
            start += 2
        }

        x = x[start..]
        if (x.size < 2 || x[0] != b'"') {
            return ("", "")
        }

        var i = 1
        while (i < x.size) {
            let c = x[i]
            i++
            match {
                case c == b'"' => return (x[..i + 1], x[i + 1..])
                case c == 0x21 || c >= 0x23 && c <= 0x7E || c >= 0x80 => ()
                case _ => return ("", "")
            }
        }

        ("", "")
    }
}
