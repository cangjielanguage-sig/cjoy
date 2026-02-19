/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
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
import cjoy.macros.*
import std.time.*

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
func test7(@Pattern[regex = "^[0-9]+$"] num: String): Unit {
}

@Validated
func test8(@DateTimeRange[after = "DateTime.now().addMinutes(-1)", before = "DateTime.now().addDays(1)"] dt: DateTime): Unit {
}

@Validated
func test9(
    @DateTimeRange[after = "{=>DateTime.now().addMinutes(-1)}()", before = "{=>let x=DateTime.now().addDays(1);x}()"]
    dt: DateTime): Unit {
}

@Validated
func test10(@ChMobileNumber num: String): Unit {
}

@Validated
func test11(@Email email: String): Unit {
}

@Validated
func test12(@IPV4 ip: String): Unit {
}

@Validated
func test13(@EnumStr[values = ["a", "b", "c"]] str: String): Unit {
}

@Validated
func test14(@EnumInt[values = [2, 4, 6]] number: Int): Unit {
}

@Validated
func test15(@EqualField[field = "password"] confirmPassword: String, password: String): Unit {
}

@Valid
@Json
public struct TestEqualFieldData {
    @NotEmpty
    var password: String = "123456"

    @EqualField[field = "password", msg = "两次输入的密码不一致"]
    var confirmPassword: String = "123456"
}

@Valid
@Json
public struct TestWhenPropertyData {
    var status: String = "inactive"

    @NotEmpty[when = #"status == "active""#]
    var activeReason: String = ""

    var isAdmin: Bool = false

    @Email[when = "isAdmin"]
    var adminEmail: String = ""
}

@Validated
func test16(@NestedValid data1: TestEqualFieldData): Unit {
}

@Validated
func test17(@NestedValid data2: TestWhenPropertyData): Unit {
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
    public func testPatternOk() {
        test7("10")
    }

    @TestCase
    public func testPatternFaild() {
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

    @TestCase
    public func testChMobileNumberOk() {
        test10("18812341234")
        test10("+86 18812341234")
        test10("+86-18812341234")
        test10("+8618812341234")
    }

    @TestCase
    public func testChMobileNumberFaild() {
        try {
            test10("12345")
            @Fail("shoud throw a validate exception")
        } catch (ex: JoyValidationException) {
            @Assert(ex.message.startsWith("this constraint of value is chinese mobile phone number"), true)
        }
    }

    @TestCase
    public func testEmailOk() {
        test11("12@163.com")
        test11("xiao@163.com")
    }

    @TestCase
    public func testEmailFaild() {
        try {
            test11("@163.com")
            @Fail("shoud throw a validate exception")
        } catch (ex: JoyValidationException) {
            @Assert(ex.message.startsWith("this constraint of value is email"), true)
        }
    }

    @TestCase
    public func testIPV4Ok() {
        test12("127.0.0.1")
        test12("255.255.255.255")
    }

    @TestCase
    public func testIPV4Faild() {
        try {
            test12("1.2.3.4.5")
            @Fail("shoud throw a validate exception")
        } catch (ex: JoyValidationException) {
            @Assert(ex.message.startsWith("this constraint of value is IP V4"), true)
        }
    }

    @TestCase
    public func testEnumStrOk() {
        test13("a")
        test13("b")
        test13("c")
    }

    @TestCase
    public func testEnumStrFaild() {
        try {
            test13("d")
            @Fail("shoud throw a validate exception")
        } catch (ex: JoyValidationException) {
            @Assert(ex.message.startsWith("this constraint of value is ["), true)
        }
    }

    @TestCase
    public func testEnumIntOk() {
        test14(2)
        test14(4)
        test14(6)
    }

    @TestCase
    public func testEnumIntFaild() {
        try {
            test14(10)
            @Fail("shoud throw a validate exception")
        } catch (ex: JoyValidationException) {
            @Assert(ex.message.startsWith("this constraint of value is ["), true)
        }
    }

    @TestCase
    public func testEqualFieldOk() {
        let data = TestEqualFieldData(
            password: "123456",
            confirmPassword: "123456"
        )
        test16(data)
    }

    @TestCase
    public func testEqualFieldFaild() {
        let data = TestEqualFieldData(
            password: "123456",
            confirmPassword: "abc123"
        )
        try {
            test16(data)
            @Fail("shoud throw a validate exception")
        } catch (ex: JoyValidationException) {
            @Assert(ex.message.startsWith("两次输入的密码不一致"), true)
        }
    }

    @TestCase
    public func testWhenPropertyOk1() {
        let data = TestWhenPropertyData(
            status: "inactive",
            activeReason: "",
            isAdmin: false,
            adminEmail: ""
        )
        test17(data)
    }

    @TestCase
    public func testWhenPropertyOk2() {
        let data = TestWhenPropertyData(
            status: "active",
            activeReason: "正在处理中",
            isAdmin: true,
            adminEmail: "admin@example.com"
        )
        test17(data)
    }

    @TestCase
    public func testWhenPropertyFaild1() {
        let data = TestWhenPropertyData(
            status: "active",
            activeReason: "",
            isAdmin: false,
            adminEmail: ""
        )
        try {
            test17(data)
            @Fail("shoud throw a validate exception")
        } catch (ex: JoyValidationException) {
            @Assert(ex.message.startsWith("this constraint of value is NOT EMPTY"), true)
        }
    }

    @TestCase
    public func testWhenPropertyFaild2() {
        let data = TestWhenPropertyData(
            status: "inactive",
            activeReason: "",
            isAdmin: true,
            adminEmail: "invalid-email"
        )
        try {
            test17(data)
            @Fail("shoud throw a validate exception")
        } catch (ex: JoyValidationException) {
            @Assert(ex.message.startsWith("this constraint of value is email"), true)
        }
    }
}
