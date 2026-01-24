/*
 * Copyright (c) 2026 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to terms and conditions of Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.fs

import std.unittest.testmacro.*
import std.time.*

@Test
public class HeaderTimeTestCaseSuit {
    @TestCase
    public func testParseTimeValidCases() {
        // Test cases that should parse successfully
        // (inputString, expectedYear, expectedMonth, expectedDay, expectedHour, expectedMinute, expectedSecond)
        let validCases: Array<(String, Int64, Int64, Int64, Int64, Int64, Int64)> = [
            // HTTP_TIME_FORMAT: "Mon, 02 Jan 2006 15:04:05 GMT"
            ("Mon, 02 Jan 2006 15:04:05 GMT", 2006, 1, 2, 15, 4, 5),
            ("Tue, 15 Nov 1994 08:12:31 GMT", 1994, 11, 15, 8, 12, 31),
            ("Fri, 01 Dec 2023 23:59:59 GMT", 2023, 12, 1, 23, 59, 59),
            ("Fri, 31 Oct 2025 00:00:00 GMT", 2025, 10, 31, 0, 0, 0),

            // RFC850: "Monday, 02-Jan-06 15:04:05 MST"
            ("Monday, 02-Jan-06 15:04:05 GMT", 2006, 1, 2, 15, 4, 5),
            ("Tuesday, 15-Nov-94 08:12:31 GMT", 1994, 11, 15, 8, 12, 31),
            ("Friday, 01-Dec-23 23:59:59 GMT", 2023, 12, 1, 23, 59, 59),
            ("Friday, 31-Oct-25 00:00:00 GMT", 2025, 10, 31, 0, 0, 0),

            // ANSIC: "Mon Jan 02 15:04:05 2006"
            ("Mon Jan 02 15:04:05 2006", 2006, 1, 2, 15, 4, 5),
            ("Tue Nov 15 08:12:31 1994", 1994, 11, 15, 8, 12, 31),
            ("Fri Dec 01 23:59:59 2023", 2023, 12, 1, 23, 59, 59),
            ("Fri Oct 31 00:00:00 2025", 2025, 10, 31, 0, 0, 0)
        ]

        for ((input, expectedYear, expectedMonth, expectedDay, expectedHour, expectedMinute, expectedSecond) in validCases) {
            let dt = try {
                parseHttpTime(input)
            } catch (e: TimeParseException) {
                @Fail("parseHttpTime(\"${input}\") should not throw error: ${e.message}")
            }

            if (dt.year != expectedYear) {
                @Fail("parseHttpTime(\"${input}\").year = ${dt.year}, want ${expectedYear}")
            }
            if (dt.month.toInteger() != expectedMonth) {
                @Fail("parseHttpTime(\"${input}\").month = ${dt.month.toInteger()}, want ${expectedMonth}")
            }
            if (dt.dayOfMonth != expectedDay) {
                @Fail("parseHttpTime(\"${input}\").dayOfMonth = ${dt.dayOfMonth}, want ${expectedDay}")
            }
            if (dt.hour != expectedHour) {
                @Fail("parseHttpTime(\"${input}\").hour = ${dt.hour}, want ${expectedHour}")
            }
            if (dt.minute != expectedMinute) {
                @Fail("parseHttpTime(\"${input}\").minute = ${dt.minute}, want ${expectedMinute}")
            }
            if (dt.second != expectedSecond) {
                @Fail("parseHttpTime(\"${input}\").second = ${dt.second}, want ${expectedSecond}")
            }
        }
    }

    @TestCase
    public func testParseTimeInvalidCases() {
        // Test cases that should throw TimeParseException
        let invalidCases: Array<String> = [
            "",
            "invalid time string",
            "2023-01-01 00:00:00",
            "01/01/2023",
            "Jan 01 2023",
            "Not a date",
            "Mon, 32 Jan 2006 15:04:05 GMT",  // Invalid day
            "Mon, 02 Xxx 2006 15:04:05 GMT",  // Invalid month
            "Mon Jan 02 15:04:05",            // Missing year
            "15:04:05 GMT"                    // Missing date
        ]

        for (s in invalidCases) {
            let result = try {
                parseHttpTime(s)
                false
            } catch (_: TimeParseException) {
                true
            }
            if (!result) {
                @Fail("parseHttpTime(\"${s}\") should throw TimeParseException")
            }
        }
    }

    @TestCase
    public func testTryParseTimeValidCases() {
        // Test cases that should return Some(DateTime)
        let validCases: Array<String> = [
            "Mon, 02 Jan 2006 15:04:05 GMT",
            "Tuesday, 15-Nov-94 08:12:31 GMT",
            "Fri Dec 01 23:59:59 2023"
        ]

        for (s in validCases) {
            match (tryParseHttpTime(s)) {
                case Some(dt) => ()  // Success
                case None => @Fail("tryParseTime(\"${s}\") should return Some(DateTime)")
            }
        }
    }

    @TestCase
    public func testTryParseTimeInvalidCases() {
        // Test cases that should return None
        let invalidCases: Array<String> = [
            "",
            "invalid time string",
            "2023-01-01 00:00:00",
            "Not a date"
        ]

        for (s in invalidCases) {
            match (tryParseHttpTime(s)) {
                case Some(_) => @Fail("tryParseHttpTime(\"${s}\") should return None")
                case None => ()  // Success
            }
        }
    }

    @TestCase
    public func testParseTimeLeapYear() {
        // Test parsing leap year dates
        let leapYearCases: Array<(String, Int64, Int64, Int64)> = [
            ("Tue, 29 Feb 2000 12:00:00 GMT", 2000, 2, 29),  // Leap year divisible by 400
            ("Sun, 29 Feb 2004 12:00:00 GMT", 2004, 2, 29)   // Leap year divisible by 4
        ]

        for ((input, expectedYear, expectedMonth, expectedDay) in leapYearCases) {
            let dt = try {
                parseHttpTime(input)
            } catch (e: TimeParseException) {
                @Fail("parseHttpTime(\"${input}\") should not throw error: ${e.message}")
            }

            if (dt.year != expectedYear) {
                @Fail("parseHttpTime(\"${input}\").year = ${dt.year}, want ${expectedYear}")
            }
            if (dt.month.toInteger() != expectedMonth) {
                @Fail("parseHttpTime(\"${input}\").month = ${dt.month.toInteger()}, want ${expectedMonth}")
            }
            if (dt.dayOfMonth != expectedDay) {
                @Fail("parseHttpTime(\"${input}\").dayOfMonth = ${dt.dayOfMonth}, want ${expectedDay}")
            }
        }
    }
}
