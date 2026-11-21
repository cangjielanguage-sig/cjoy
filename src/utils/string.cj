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
    /**
     * 按字节分隔符分割字符串
     *
     * @param b 分隔符字节
     * @return (左侧部分, 右侧部分, 是否找到的标记) 元组
     */
    func cut(b: Byte): (String, String, Bool)

    /**
     * 查找第一个匹配谓词的字节索引
     *
     * @param f 谓词函数
     * @return 第一个匹配字节的索引，如果未找到则返回 -1
     */
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

/**
 * 检查字节是否为十六进制字符 (0-9, a-f, A-F)
 *
 * @param c 要检查的字节
 * @return 如果字节是十六进制字符返回 true
 */
protected func ishex(c: Byte): Bool {
    match {
        case b'0' <= c && c <= b'9' => true
        case b'a' <= c && c <= b'f' => true
        case b'A' <= c && c <= b'F' => true
        case _ => false
    }
}

/**
 * 将十六进制字符字节转换为其数值
 *
 * @param c 十六进制字符字节 (0-9, a-f, A-F)
 * @return 数值 0-15，如果不是十六进制字符则返回 0
 */
protected func unhex(c: Byte): Byte {
    match {
        case b'0' <= c && c <= b'9' => c - b'0'
        case b'a' <= c && c <= b'f' => c - b'a' + 10
        case b'A' <= c && c <= b'F' => c - b'A' + 10
        case _ => b'\0'
    }
}

/**
 * 将 CamelCase 字符串转换为 snake_case 字符串
 *
 * @param str CamelCase 格式的输入字符串
 * @return snake_case 格式的字符串
 */
protected func snakeCase(str: String): String {
    let arr = str.toRuneArray()
    let builder = StringBuilder()
    var upper = false
    for (a in arr) {
        if (a.isAsciiUpperCase()) {
            if (!upper && builder.size > 0) {
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

/**
 * 检查字节是否为 ASCII 空白字符
 *
 * @param b 要检查的字节
 * @return 如果字节是空格、制表符、换行符或回车符返回 true
 */
protected func isASCIISpace(b: Byte): Bool {
    return b == b' ' || b == b'\t' || b == b'\n' || b == b'\r'
}

/**
 * 检查字节是否为 ASCII 字母字符
 *
 * @param b 要检查的字节
 * @return 如果字节是 a-z 或 A-Z 返回 true
 */
protected func isASCIILetter(b: Byte): Bool {
    let x = b | 0x20 // 转换为小写
    x >= b'a' && x <= b'z'
}

/**
 * 从字节数组的两端修剪 ASCII 空白字符
 *
 * @param bs 输入字节数组
 * @return 移除了前导/尾随空白的字节数组
 */
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

/**
 * 从字符串的两端修剪 ASCII 空白字符
 *
 * @param s 输入字符串
 * @return 移除了前导/尾随空白的字符串
 */
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
