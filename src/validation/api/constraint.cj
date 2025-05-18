/*
 * Copyright (c) lanlingx 2025-present. All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.validation.api

import std.regex.Regex
import std.time.DateTime
import std.collection.HashMap

public interface JoyConstraint {}

/**
 * for collection
 */
public class SizeConstraint <: JoyConstraint {
    public let message: String
    public SizeConstraint(public let min: Int, public let max: Int, let msg: String) {
        if (msg.isEmpty()) {
            this.message = "this constraint of value is Size[${min}, ${max}]"
        } else {
            this.message = msg.replace("{min}", min.toString()).replace("{max}", max.toString())
        }
    }
}

/**
 * for string
 */
public class LengthConstraint <: JoyConstraint {
    public let message: String
    public LengthConstraint(public let min: Int, public let max: Int, let msg: String) {
        if (msg.isEmpty()) {
            this.message = "this constraint of value is Length[${min}, ${max}]"
        } else {
            this.message = msg.replace("{min}", min.toString()).replace("{max}", max.toString())
        }
    }
}

/**
 * for string
 */
public class NotEmptyConstraint <: JoyConstraint {
    public let message: String
    public NotEmptyConstraint(let msg: String) {
        if (msg.isEmpty()) {
            this.message = "this constraint of value is NOT EMPTY"
        } else {
            this.message = msg
        }
    }
}

/**
 * for string
 */
public class NotBlankConstraint <: JoyConstraint {
    public let message: String
    public NotBlankConstraint(let msg: String) {
        if (msg.isEmpty()) {
            this.message = "this constraint of value is NOT BLANK"
        } else {
            this.message = msg
        }
    }
}

/**
 * for number
 */
public class RangeConstraint <: JoyConstraint {
    public let message: String
    public RangeConstraint(public let min: String, public let max: String, let msg: String) {
        if (msg.isEmpty()) {
            this.message = "this constraint of value is NumberRange[${min}, ${max}]"
        } else {
            this.message = msg.replace("{min}", min.toString()).replace("{max}", max.toString())
        }
    }
}

/**
 * for string
 */
public class PattenConstraint <: JoyConstraint {
    public let message: String
    public let regex: Regex
    public PattenConstraint(let regexStr: String, let msg: String) {
        this.regex = Regex(regexStr)
        if (msg.isEmpty()) {
            this.message = "this constraint of value is Pattern[${regexStr}]"
        } else {
            this.message = msg.replace("{regex}", regexStr)
        }
    }
}

/**
 * for datetime
 */
public class DateTimeRangeConstraint <: JoyConstraint {
    public let message: String
    public DateTimeRangeConstraint(public let before: DateTime, public let after: DateTime, public let msg: String) {
        if (msg.isEmpty()) {
            this.message = "this constraint of value is DateTimeRange[${after}, ${before}]"
        } else {
            this.message = msg.replace("{after}", after.toString()).replace("{before}", before.toString())
        }
    }
}

public class JoyValidationException <: Exception {
    public let field: String
    public let constraint: JoyConstraint

    public init(message: String, field: String, constraint: JoyConstraint) {
        super(message)
        this.field = field
        this.constraint = constraint
    }

    public func toMap(): HashMap<String, String> {
        let res: HashMap<String, String> = HashMap()
        res.add("field", field)
        res.add("errMsg", message)
        res
    }
}
