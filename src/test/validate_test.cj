/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.test

import cjoy.json.*
import cjoy.validation.*
import std.time.*
import std.convert.*

@Valid
@Json
public struct Data {
    @Length[min = 0, max = 10, msg = "xxxxx"]
    @NotBlank
    @NotEmpty
    var str: String = "str"

    @NumberRange[min = 0, max = 123456789]
    var u32: UInt32 = 12345678

    @Size[max = 6]
    @NestedValid
    @NumberRange[min = 0, max = 123456789]
    var arr: Array<Int32> = [1, 2, 3, 4]

    @DateTimeRange[before = "DateTime.now().addDays(1)"]
    var data: DateTime = DateTime.now()

    @NestedValid
    var nestedData: NestedData = NestedData()
}

@Valid
@Json
public struct NestedData {
    @Length[min = 0, max = 10, msg = "xxxxx"]
    var name: String = "NestedData"

    @NestedValid
    var nestedData2: NestedData2 = NestedData2()
}

@Valid
@Json
public struct NestedData2 {
    @Length[min = 0, max = 10, msg = "xxxxx"]
    var name: String = "NestedData"
}

@Validated
func test1(@Size[max = 6] arrparam: Array<Int32>): Unit {
}

@Validated
func test2(@NestedValid data: Data): Unit {
}

@Validated
func test3(@Length[max = 6] str: String): Unit {
}

@Validated
func test4(@NotEmpty str: String): Unit {
}

@Validated
func test5(@NotBlank str: String): Unit {
}

@Validated
func test6(@NumberRange[min = 1, max = 100] num: Int): Unit {
}

@Validated
func test7(@Patten[regex = "^[0-9]+$"] num: String): Unit {
}

@Validated
func test8(@DateTimeRange[after = "DateTime.now().addMinutes(-1)", before = "DateTime.now().addDays(1)"] dt: DateTime): Unit {
}

@Validated
func test9(@DateTimeRange[after = "{=>DateTime.now().addMinutes(-1)}()", before = "{=>let x=DateTime.now().addDays(1);x}()"] dt: DateTime): Unit {
}

@Test
public class ValidateTestCaseSuit {
    @TestCase
    public func testSizeOk() {
        test1([1, 2, 3, 4])
    }

    @TestCase
    public func testSizeFaild() {
        try {
            test1([1, 2, 3, 4, 5, 6, 7, 8])
            @Fail("shoud throw a validate exception")
        } catch (ex: JoyValidationException) {
            @Assert(ex.message, "this constraint of value is Size[0, 6]")
        }
    }

    @TestCase
    public func testLengthOk() {
        test3("1234")
    }

    @TestCase
    public func testLengthFaild() {
        try {
            test3("12345678")
            @Fail("shoud throw a validate exception")
        } catch (ex: JoyValidationException) {
            @Assert(ex.message, "this constraint of value is Length[0, 6]")
        }
    }

    @TestCase
    public func testNotEmptyOk() {
        test4("1234")
    }

    @TestCase
    public func testNotEmptyFaild() {
        try {
            test4("")
            @Fail("shoud throw a validate exception")
        } catch (ex: JoyValidationException) {
            @Assert(ex.message, "this constraint of value is NOT EMPTY")
        }
    }

    @TestCase
    public func testNotBlankOk() {
        test5("1234")
    }

    @TestCase
    public func testNotBlankFaild() {
        try {
            test5("   ")
            @Fail("shoud throw a validate exception")
        } catch (ex: JoyValidationException) {
            @Assert(ex.message, "this constraint of value is NOT BLANK")
        }
    }

    @TestCase
    public func testNumberRangeOk() {
        test6(10)
    }

    @TestCase
    public func testNumberRangeFaild() {
        try {
            test6(-1)
            @Fail("shoud throw a validate exception")
        } catch (ex: JoyValidationException) {
            @Assert(ex.message, "this constraint of value is NumberRange[1, 100]")
        }
    }

    @TestCase
    public func testPattenOk() {
        test7("10")
    }

    @TestCase
    public func testPattenFaild() {
        try {
            test7("-1")
            @Fail("shoud throw a validate exception")
        } catch (ex: JoyValidationException) {
            @Assert(ex.message, "this constraint of value is Pattern[^[0-9]+$]")
        }
    }

    @TestCase
    public func testDateTimeRangeOk() {
        test8(DateTime.now())
    }

    @TestCase
    public func testDateTimeRangeFaild() {
        try {
            test8(DateTime.now().addMinutes(-10))
            @Fail("shoud throw a validate exception")
        } catch (ex: JoyValidationException) {
            @Assert(ex.message.startsWith("this constraint of value is DateTimeRange["), true)
        }
    }
}
