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
func testSizeConstraint(@Size[max = 6] arrparam: Array<Int32>): Unit {
}

@Validated
func testNestedDataValidation(@NestedValid data: Data): Unit {
}

@Validated
func testLengthConstraint(@Length[max = 6] str: String): Unit {
}

@Validated
func testNotEmptyConstraint(@NotEmpty str: String): Unit {
}

@Validated
func testNotEmptyArrayConstraint(@NotEmpty arr: Array<String>): Unit {
}

@Validated
func testNotBlankConstraint(@NotBlank str: String): Unit {
}

@Validated
func testNumberRangeConstraint(@NumberRange[min = 1, max = 100] num: Int): Unit {
}

@Validated
func testPatternConstraint(@Pattern[regex = "^[0-9]+$"] num: String): Unit {
}

@Validated
func testDateTimeRangeConstraint(@DateTimeRange[after = "DateTime.now().addMinutes(-1)", before = "DateTime.now().addDays(1)"] dt: DateTime): Unit {
}

@Validated
func testDateTimeRangeWithComplexExpressions(
    @DateTimeRange[after = "{=>DateTime.now().addMinutes(-1)}()", before = "{=>let x=DateTime.now().addDays(1);x}()"]
    dt: DateTime): Unit {
}

@Validated
func testChMobileNumberConstraint(@ChMobileNumber num: String): Unit {
}

@Validated
func testEmailConstraint(@Email email: String): Unit {
}

@Validated
func testIPV4Constraint(@IPV4 ip: String): Unit {
}

@Validated
func testEnumStrConstraint(@EnumStr[values = ["a", "b", "c"]] str: String): Unit {
}

@Validated
func testEnumIntConstraint(@EnumInt[values = [2, 4, 6]] number: Int): Unit {
}

@Validated
func testEqualFieldConstraint(@EqualField[field = "password"] confirmPassword: String, password: String): Unit {
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

@Valid
@Json
public struct TestAllWhenPropertiesData {
    var condition1: Bool = false
    var condition2: Bool = false
    var condition3: Bool = false
    var status: String = "draft"

    @Size[max = 5, when = "condition1"]
    var sizeField: Array<Int32> = [1, 2, 3, 4, 5, 6]

    @Length[min = 3, max = 10, when = "condition2"]
    var lengthField: String = "ab"

    @NotEmpty[when = #"status == "published""#]
    var notEmptyField: String = ""

    @NotBlank[when = #"status == "published""#]
    var notBlankField: String = "   "

    @NumberRange[min = 10, max = 100, when = "condition3"]
    var numberRangeField: Int32 = 5

    @Pattern[regex = "^[0-9]+$", when = "condition1"]
    var patternField: String = "abc123"

    @DateTimeRange[after = "DateTime.now().addDays(-1)", before = "DateTime.now().addDays(1)", when = "condition2"]
    var dateTimeField: DateTime = DateTime.now().addDays(2)

    @ChMobileNumber[when = "condition3"]
    var mobileField: String = "12345"

    @IPV4[when = "condition1"]
    var ipv4Field: String = "256.0.0.1"

    @EnumStr[values = ["a", "b", "c"], when = "condition2"]
    var enumStrField: String = "d"

    @EnumInt[values = [1, 3, 5], when = "condition3"]
    var enumIntField: Int32 = 2

    var password: String = "123456"
    @EqualField[field = "password", when = "condition1"]
    var confirmPasswordField: String = "abc123"
}

@Validated
func testEqualFieldDataValidation(@NestedValid data1: TestEqualFieldData): Unit {
}

@Validated
func testWhenPropertyDataValidation(@NestedValid data2: TestWhenPropertyData): Unit {
}

@Validated
func testAllWhenPropertiesDataValidation(@NestedValid data3: TestAllWhenPropertiesData): Unit {
}

@Test
public class ValidateTestCaseSuit {
    /**
     * 测试 Size 约束 - 验证数组大小在允许范围内
     */
    @TestCase
    public func testSizeOk() {
        testSizeConstraint([1, 2, 3, 4])
    }

    /**
     * 测试 Size 约束 - 验证数组大小超过最大限制时会抛出异常
     */
    @TestCase
    public func testSizeFaild() {
        try {
            testSizeConstraint([1, 2, 3, 4, 5, 6, 7, 8])
            @Fail("shoud throw a validate exception")
        } catch (ex: JoyValidationException) {
            @Assert(ex.message, "this constraint of value is Size[0, 6]")
        }
    }

    /**
     * 测试 Length 约束 - 验证字符串长度在允许范围内
     */
    @TestCase
    public func testLengthOk() {
        testLengthConstraint("1234")
    }

    /**
     * 测试 Length 约束 - 验证字符串长度超过最大限制时会抛出异常
     */
    @TestCase
    public func testLengthFaild() {
        try {
            testLengthConstraint("12345678")
            @Fail("shoud throw a validate exception")
        } catch (ex: JoyValidationException) {
            @Assert(ex.message, "this constraint of value is Length[0, 6]")
        }
    }

    /**
     * 测试 NotEmpty 约束 - 验证非空字符串通过验证
     */
    @TestCase
    public func testNotEmptyOk() {
        testNotEmptyConstraint("1234")
    }

    /**
     * 测试 NotEmpty 约束 - 验证空字符串会抛出异常
     */
    @TestCase
    public func testNotEmptyFaild() {
        try {
            testNotEmptyConstraint("")
            @Fail("shoud throw a validate exception")
        } catch (ex: JoyValidationException) {
            @Assert(ex.message, "this constraint of value is NOT EMPTY")
        }
    }

    /**
     * 测试 NotBlank 约束 - 验证非空白字符串通过验证
     */
    @TestCase
    public func testNotBlankOk() {
        testNotBlankConstraint("1234")
    }

    /**
     * 测试 NotBlank 约束 - 验证空白字符串会抛出异常
     */
    @TestCase
    public func testNotBlankFaild() {
        try {
            testNotBlankConstraint("   ")
            @Fail("shoud throw a validate exception")
        } catch (ex: JoyValidationException) {
            @Assert(ex.message, "this constraint of value is NOT BLANK")
        }
    }

    /**
     * 测试 NumberRange 约束 - 验证数值在允许范围内
     */
    @TestCase
    public func testNumberRangeOk() {
        testNumberRangeConstraint(10)
    }

    /**
     * 测试 NumberRange 约束 - 验证数值小于最小值时会抛出异常
     */
    @TestCase
    public func testNumberRangeFaild() {
        try {
            testNumberRangeConstraint(-1)
            @Fail("shoud throw a validate exception")
        } catch (ex: JoyValidationException) {
            @Assert(ex.message, "this constraint of value is NumberRange[1, 100]")
        }
    }

    /**
     * 测试 Pattern 约束 - 验证符合正则表达式的字符串通过验证
     */
    @TestCase
    public func testPatternOk() {
        testPatternConstraint("10")
    }

    /**
     * 测试 Pattern 约束 - 验证不符合正则表达式的字符串会抛出异常
     */
    @TestCase
    public func testPatternFaild() {
        try {
            testPatternConstraint("-1")
            @Fail("shoud throw a validate exception")
        } catch (ex: JoyValidationException) {
            @Assert(ex.message, "this constraint of value is Pattern[^[0-9]+$]")
        }
    }

    /**
     * 测试 DateTimeRange 约束 - 验证当前时间在允许范围内
     */
    @TestCase
    public func testDateTimeRangeOk() {
        testDateTimeRangeConstraint(DateTime.now())
    }

    /**
     * 测试 DateTimeRange 约束 - 验证超出时间范围的日期会抛出异常
     */
    @TestCase
    public func testDateTimeRangeFaild() {
        try {
            testDateTimeRangeConstraint(DateTime.now().addMinutes(-10))
            @Fail("shoud throw a validate exception")
        } catch (ex: JoyValidationException) {
            @Assert(ex.message.startsWith("this constraint of value is DateTimeRange["), true)
        }
    }

    /**
     * 测试 ChMobileNumber 约束 - 验证有效的中国手机号码通过验证
     */
    @TestCase
    public func testChMobileNumberOk() {
        testChMobileNumberConstraint("18812341234")
        testChMobileNumberConstraint("+86 18812341234")
        testChMobileNumberConstraint("+86-18812341234")
        testChMobileNumberConstraint("+8618812341234")
    }

    /**
     * 测试 ChMobileNumber 约束 - 验证无效的手机号码会抛出异常
     */
    @TestCase
    public func testChMobileNumberFaild() {
        try {
            testChMobileNumberConstraint("12345")
            @Fail("shoud throw a validate exception")
        } catch (ex: JoyValidationException) {
            @Assert(ex.message.startsWith("this constraint of value is chinese mobile phone number"), true)
        }
    }

    /**
     * 测试 Email 约束 - 验证有效的邮箱地址通过验证
     */
    @TestCase
    public func testEmailOk() {
        testEmailConstraint("12@163.com")
        testEmailConstraint("xiao@163.com")
        testEmailConstraint("john.doe+tag@example.com")
    }

    /**
     * 测试集合 NotEmpty 约束 - 验证空数组会抛出异常
     */
    @TestCase
    public func testNotEmptyArray() {
        testNotEmptyArrayConstraint(["a"])
        try {
            testNotEmptyArrayConstraint([])
            @Fail("should throw a validate exception")
        } catch (ex: JoyValidationException) {
            @Assert(ex.message != "", true)
        }
    }

    /**
     * 测试函数参数错误字段 - 验证异常中包含参数名
     */
    @TestCase
    public func testFunctionParamFieldName() {
        try {
            testLengthConstraint("abcdefg")
            @Fail("should throw a validate exception")
        } catch (ex: JoyValidationException) {
            @Assert(ex.field, "str")
        }
    }

    /**
     * 测试 Email 约束 - 验证无效的邮箱地址会抛出异常
     */
    @TestCase
    public func testEmailFaild() {
        try {
            testEmailConstraint("@163.com")
            @Fail("shoud throw a validate exception")
        } catch (ex: JoyValidationException) {
            @Assert(ex.message.startsWith("this constraint of value is email"), true)
        }
    }

    /**
     * 测试 IPV4 约束 - 验证有效的 IPv4 地址通过验证
     */
    @TestCase
    public func testIPV4Ok() {
        testIPV4Constraint("127.0.0.1")
        testIPV4Constraint("255.255.255.255")
    }

    /**
     * 测试 IPV4 约束 - 验证无效的 IPv4 地址会抛出异常
     */
    @TestCase
    public func testIPV4Faild() {
        try {
            testIPV4Constraint("1.2.3.4.5")
            @Fail("shoud throw a validate exception")
        } catch (ex: JoyValidationException) {
            @Assert(ex.message.startsWith("this constraint of value is IP V4"), true)
        }
    }

    /**
     * 测试 EnumStr 约束 - 验证符合枚举值的字符串通过验证
     */
    @TestCase
    public func testEnumStrOk() {
        testEnumStrConstraint("a")
        testEnumStrConstraint("b")
        testEnumStrConstraint("c")
    }

    /**
     * 测试 EnumStr 约束 - 验证不符合枚举值的字符串会抛出异常
     */
    @TestCase
    public func testEnumStrFaild() {
        try {
            testEnumStrConstraint("d")
            @Fail("shoud throw a validate exception")
        } catch (ex: JoyValidationException) {
            @Assert(ex.message.startsWith("this constraint of value is ["), true)
        }
    }

    /**
     * 测试 EnumInt 约束 - 验证符合枚举值的整数通过验证
     */
    @TestCase
    public func testEnumIntOk() {
        testEnumIntConstraint(2)
        testEnumIntConstraint(4)
        testEnumIntConstraint(6)
    }

    /**
     * 测试 EnumInt 约束 - 验证不符合枚举值的整数会抛出异常
     */
    @TestCase
    public func testEnumIntFaild() {
        try {
            testEnumIntConstraint(10)
            @Fail("shoud throw a validate exception")
        } catch (ex: JoyValidationException) {
            @Assert(ex.message.startsWith("this constraint of value is ["), true)
        }
    }

    /**
     * 测试 EqualField 约束 - 验证字段相等时通过验证
     */
    @TestCase
    public func testEqualFieldOk() {
        let data = TestEqualFieldData(
            password: "123456",
            confirmPassword: "123456"
        )
        testEqualFieldDataValidation(data)
    }

    /**
     * 测试 EqualField 约束 - 验证字段不相等时会抛出异常
     */
    @TestCase
    public func testEqualFieldFaild() {
        let data = TestEqualFieldData(
            password: "123456",
            confirmPassword: "abc123"
        )
        try {
            testEqualFieldDataValidation(data)
            @Fail("shoud throw a validate exception")
        } catch (ex: JoyValidationException) {
            @Assert(ex.message.startsWith("两次输入的密码不一致"), true)
        }
    }

    /**
     * 测试 When 属性 - 验证条件不满足时不执行验证
     */
    @TestCase
    public func testWhenPropertyOk1() {
        let data = TestWhenPropertyData(
            status: "inactive",
            activeReason: "",
            isAdmin: false,
            adminEmail: ""
        )
        testWhenPropertyDataValidation(data)
    }

    /**
     * 测试 When 属性 - 验证条件满足时执行验证且通过
     */
    @TestCase
    public func testWhenPropertyOk2() {
        let data = TestWhenPropertyData(
            status: "active",
            activeReason: "正在处理中",
            isAdmin: true,
            adminEmail: "admin@example.com"
        )
        testWhenPropertyDataValidation(data)
    }

    /**
     * 测试 When 属性 - 验证条件满足但值不满足约束时会抛出异常
     */
    @TestCase
    public func testWhenPropertyFaild1() {
        let data = TestWhenPropertyData(
            status: "active",
            activeReason: "",
            isAdmin: false,
            adminEmail: ""
        )
        try {
            testWhenPropertyDataValidation(data)
            @Fail("shoud throw a validate exception")
        } catch (ex: JoyValidationException) {
            @Assert(ex.message.startsWith("this constraint of value is NOT EMPTY"), true)
        }
    }

    /**
     * 测试 When 属性 - 验证条件满足但值不满足约束时会抛出异常
     */
    @TestCase
    public func testWhenPropertyFaild2() {
        let data = TestWhenPropertyData(
            status: "inactive",
            activeReason: "",
            isAdmin: true,
            adminEmail: "invalid-email"
        )
        try {
            testWhenPropertyDataValidation(data)
            @Fail("shoud throw a validate exception")
        } catch (ex: JoyValidationException) {
            @Assert(ex.message.startsWith("this constraint of value is email"), true)
        }
    }

    /**
     * 测试所有 When 属性的宏 - 验证当所有条件都不满足时，所有约束都不会被触发
     */
    @TestCase
    public func testAllWhenPropertiesOkWhenConditionsFalse() {
        let data = TestAllWhenPropertiesData(
            condition1: false,
            condition2: false,
            condition3: false,
            status: "draft",
            sizeField: [1, 2, 3, 4, 5, 6],
            lengthField: "ab",
            notEmptyField: "",
            notBlankField: "   ",
            numberRangeField: 5,
            patternField: "abc123",
            dateTimeField: DateTime.now().addDays(2),
            mobileField: "12345",
            ipv4Field: "256.0.0.1",
            enumStrField: "d",
            enumIntField: 2,
            password: "123456",
            confirmPasswordField: "abc123"
        )
        testAllWhenPropertiesDataValidation(data)
    }

    /**
     * 测试所有 When 属性的宏 - 验证当所有条件都满足时，所有约束都会被触发并抛出异常
     */
    @TestCase
    public func testAllWhenPropertiesFailWhenConditionsTrue() {
        let data = TestAllWhenPropertiesData(
            condition1: true,
            condition2: true,
            condition3: true,
            status: "published",
            sizeField: [1, 2, 3, 4, 5, 6],
            lengthField: "ab",
            notEmptyField: "",
            notBlankField: "   ",
            numberRangeField: 5,
            patternField: "abc123",
            dateTimeField: DateTime.now().addDays(2),
            mobileField: "12345",
            ipv4Field: "256.0.0.1",
            enumStrField: "d",
            enumIntField: 2,
            password: "123456",
            confirmPasswordField: "abc123"
        )
        try {
            testAllWhenPropertiesDataValidation(data)
            @Fail("should throw a validate exception")
        } catch (ex: JoyValidationException) {
            @Assert(ex.message != "", true)
        }
    }
}
