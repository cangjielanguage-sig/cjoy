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
 * ANSIC format: "Mon Jan _2 15:04:05 2006"
 * Corresponds to Go's time.ANSIC constant.
 * This may not parse single-digit day values like Go does.
 */
const ANSIC: String = "www MMM dd HH:mm:ss yyyy"

/**
 * ParseHttpTime parses a time header (such as the Date: header),
 * trying each of the three formats allowed by HTTP/1.1:
 * RFC1123, RFC850, and ANSIC.
 *
 * @param text The time string to parse.
 * @return A DateTime if parsing succeeds.
 * @throws TimeParseException if all format parsing attempts fail.
 */
public func parseHttpTime(text: String): DateTime {
    let formats = [DateTimeFormat.RFC1123, DateTimeFormat.RFC850, ANSIC]

    for (format in formats) {
        try {
            return DateTime.parse(text, format)
        } catch (e: TimeParseException) {
            e.printStackTrace()
            // Try next format
        } catch (_: IllegalArgumentException) {
            // Try next format
        }
    }

    throw TimeParseException("Failed to parse time: ${text}")
}

/**
 * TryParseHttpTime attempts to parse a time header string,
 * trying each of the three formats allowed by HTTP/1.1.
 *
 * @param text The time string to parse.
 * @return Option<DateTime> with the parsed time, or None if parsing fails.
 */
public func tryParseHttpTime(text: String): Option<DateTime> {
    try {
        Some(parseHttpTime(text))
    } catch (_: TimeParseException) {
        None
    }
}
