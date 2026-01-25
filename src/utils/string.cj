/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.utils

protected interface StrExt {
    func cut(b: Byte): (String, String, Bool)

    func indexFunc(f: (x: Byte) -> Bool): Int
}

extend String <: StrExt {
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

protected func ishex(c: Byte): Bool {
    match {
        case b'0' <= c && c <= b'9' => true
        case b'a' <= c && c <= b'f' => true
        case b'A' <= c && c <= b'F' => true
        case _ => false
    }
}

protected func unhex(c: Byte): Byte {
    match {
        case b'0' <= c && c <= b'9' => c - b'0'
        case b'a' <= c && c <= b'f' => c - b'a' + 10
        case b'A' <= c && c <= b'F' => c - b'A' + 10
        case _ => b'\0'
    }
}

protected func snakeCase(str: String): String {
    let arr = str.toRuneArray()
    let builder = StringBuilder()
    var upper = false
    for (a in arr) {
        if (a.isAsciiUpperCase()) {
            if (!upper && builder.size > 1) {
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

protected func isASCIISpace(b: Byte): Bool {
    return b == b' ' || b == b'\t' || b == b'\n' || b == b'\r'
}

protected func isASCIILetter(b: Byte): Bool {
    let x = b | 0x20 // make lower case
    x >= b'a' && x <= b'z'
}

protected func trimBytes(bs: Array<Byte>): Array<Byte> {
    var x = bs
    while (x.size > 0 && isASCIISpace(x[0])) {
        x = x[1..]
    }
    while (x.size > 0 && isASCIISpace(x[x.size - 1])) {
        x = x[..x.size - 1]
    }
    x
}

protected func trimString(s: String): String {
    var x = s
    while (x.size > 0 && isASCIISpace(x[0])) {
        x = x[1..]
    }
    while (x.size > 0 && isASCIISpace(x[x.size - 1])) {
        x = x[..x.size - 1]
    }
    x
}
