/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.utils

import stdx.encoding.base64.{toBase64String, fromBase64String}

protected func rawBase64URLEncode(bs: Array<Byte>): String {
    var res: String = toBase64String(bs)
    res = res.trimEnd("=")
    res = res.replace("+", "-")
    res = res.replace("/", "_")
    res
}

protected func rawBase64URLDecode(str: String): ?Array<Byte> {
    var v = str
    let len = str.size % 4
    if (len > 0) {
        v += String.repeat("=", 4 - len)
    }
    v = v.replace("-", "+")
    v = v.replace("_", "/")
    fromBase64String(v)
}
