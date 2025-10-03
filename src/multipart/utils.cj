/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.multipart

private let SPECAIL_CHARS_AND_SPACE = #"()<>@,;:\"/[]?= "#.toArray()
private let SPECAIL_CHARS = #"()<>@,;:\"/[]?="#.toArray()

protected func isTSpecialAndSpace(b: Byte): Bool {
    SPECAIL_CHARS_AND_SPACE.contains(b)
}

protected func escapeQuotes(s: String): String {
    s.replace("\\", "\\\\").replace(#'"'#, "\\\"")
}

protected func isTSpecial(b: Byte): Bool {
    SPECAIL_CHARS.contains(b)
}

protected func isNotTokenChar(b: Byte): Bool {
    return !(b > 0x20 && b < 0x7f && !isTSpecial(b))
}

protected func decode2231Enc(str: String): String {
    let sv = str.split("'", 3)
    if (sv.size != 3) {
        return ""
    }

    let charset = sv[0].toAsciiLower()
    if (charset.isEmpty()) {
        return ""
    }

    if (charset != "us-ascii" && charset != "utf-8") {
        return ""
    }

    return percentHexUnescape(sv[2])
}
