/*
 * Copyright (c) 2026 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 *
 */

package cjoy.fs

import std.time.{DateTime, TimeParseException, DateTimeFormat}

/**
 * ANSIC 格式："Mon Jan _2 15:04:05 2006"
 * 对应 Go 的 time.ANSIC 常量
 * 此格式可能无法解析像 Go 一样的单位数日期值
 */
const ANSIC: String = "www MMM dd HH:mm:ss yyyy"

/**
 * 解析 HTTP 时间头（如 Date: 头）
 * 尝试 HTTP/1.1 允许的三种格式：RFC1123、RFC850 和 ANSIC
 *
 * @param text 要解析的时间字符串
 * @return 解析成功返回 DateTime
 * @throws TimeParseException 如果所有格式解析尝试都失败
 */
public func parseHttpTime(text: String): DateTime {
    let formats = [DateTimeFormat.RFC1123, DateTimeFormat.RFC850, ANSIC]

    for (format in formats) {
        try {
            return DateTime.parse(text, format)
        } catch (e: TimeParseException) {
            // Try next format
        } catch (_: IllegalArgumentException) {
            // Try next format
        }
    }

    throw TimeParseException("Failed to parse time: ${text}")
}

/**
 * 尝试解析 HTTP 时间头字符串
 * 尝试 HTTP/1.1 允许的三种格式
 *
 * @param text 要解析的时间字符串
 * @return 解析成功返回 Option<DateTime>，失败返回 None
 */
public func tryParseHttpTime(text: String): Option<DateTime> {
    try {
        Some(parseHttpTime(text))
    } catch (_: TimeParseException) {
        None
    }
}
