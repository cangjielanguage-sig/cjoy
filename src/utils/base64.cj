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

import stdx.encoding.base64.{toBase64String, fromBase64String}

/**
 * 将字节编码为 base64 URL 安全格式
 *
 * @param bs 要编码的输入字节
 * @return base64 URL 安全编码字符串（无填充，使用 '-' 和 '_' 代替 '+' 和 '/'）
 */
protected func rawBase64URLEncode(bs: Array<Byte>): String {
    var res: String = toBase64String(bs)
    res = res.trimEnd("=")
    res = res.replace("+", "-")
    res = res.replace("/", "_")
    res
}

/**
 * 将 base64 URL 安全字符串解码为字节
 *
 * @param str 要解码的 base64 URL 安全字符串（可能缺少填充）
 * @return 解码后的字节，如果 base64 格式无效则返回 None
 */
protected func rawBase64URLDecode(str: String): ?Array<Byte> {
    var v = str
    let len = str.size % 4
    if (len > 0) {
        v += "=" * (4 - len)
    }
    v = v.replace("-", "+")
    v = v.replace("_", "/")
    fromBase64String(v)
}
