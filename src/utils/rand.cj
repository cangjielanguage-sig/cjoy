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

import std.convert.Formattable
import std.collection.{map, collectArray}
import std.random.Random
import stdx.crypto.crypto.SecureRandom


/**
 * 用于生成随机字符串的字符串工具函数
 *
 * @param len 要生成的随机字符串长度
 * @return 指定长度的随机字符串
 */
protected func randStr(len: Int32): String {
    let r = Random()
    let bs = r.nextBytes(len)
    let array = bs |> map {b => b.format("02x")} |> collectArray
    String.join(array)
}

/**
 * 使用 SecureRandom 生成安全随机字符串
 *
 * @param len 要生成的随机字符串长度
 * @return 指定长度的安全随机字符串
 */
protected func secureRandStr(len: Int32): String {
    let r = SecureRandom()
    let bs = r.nextBytes(len)
    let array = bs |> map {b => b.format("02x")} |> collectArray
    String.join(array)
}
