/*
 * Copyright (c) lanlingx 2025-present. All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.test

import cjoy.*
import cjoy.json.*
import cjoy.macros.*
import cjoy.validation.*
import std.deriving.*
import std.collection.*
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
func test(@Size[max = 6] arrparam: Array<Int32>): Unit {
}

@Validated
func test2(@NestedValid nestedData: NestedData): Unit {
}
