/*
 * Copyright (c) lanlingx 2025-present. All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.utils

protected interface StrFunc {
    func cut(b: Byte): (String, String, Bool)

    func indexFunc(f: (x: Byte) -> Bool): Int
}

extend String <: StrFunc {
    public func cut(b: Byte): (String, String, Bool) {
        if (let Some(i) <- this.indexOf(b)) {
            return (this[0..i], this[i + 1..this.size], true)
        }
        return (this, "", false)
    }

    public func indexFunc(f: (x: Byte) -> Bool): Int {
        for (i in 0..size) {
            if (f(this[i])) {
                return i
            }
        }
        -1
    }
}

protected class HexUtils {
    public static func ishex(c: Byte): Bool {
        match {
            case b'0' <= c && c <= b'9' => true
            case b'a' <= c && c <= b'f' => true
            case b'A' <= c && c <= b'F' => true
            case _ => false
        }
    }

    public static func unhex(c: Byte): Byte {
        match {
            case b'0' <= c && c <= b'9' => c - b'0'
            case b'a' <= c && c <= b'f' => c - b'a' + 10
            case b'A' <= c && c <= b'F' => c - b'A' + 10
            case _ => b'\0'
        }
    }
}
