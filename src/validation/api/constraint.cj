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

public interface Constraint {}

/**
 * for collection
 */
public class SizeConstraint <: Constraint {
    public let message: String
    public SizeConstraint(public let min: Int, public let max: Int, let msg: String) {
        if (msg.isEmpty()) {
            this.message = "this constraint of value is size[${min}, ${max}]"
        } else {
            this.message = msg.replace("{min}", min.toString()).replace("{max}", max.toString())
        }
    }
}

/**
 * for string
 */
public class LengthConstraint <: Constraint {
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
public class NotEmptyConstraint <: Constraint {
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
public class NotBlankConstraint <: Constraint {
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
public class RangeConstraint <: Constraint {
    public let message: String
    public RangeConstraint(public let min: String, public let max: String, let msg: String) {
        if (msg.isEmpty()) {
            this.message = "this constraint of value is rang[${min}, ${max}]"
        } else {
            this.message = msg.replace("{min}", min.toString()).replace("{max}", max.toString())
        }
    }
}

/**
 * for string
 */
public class PattenConstraint <: Constraint {
    public let message: String
    public let regex: Regex
    public PattenConstraint(let regexStr: String, let msg: String) {
        this.regex = Regex(regexStr)
        if (msg.isEmpty()) {
            this.message = "this constraint of value is pattern[${regexStr}]"
        } else {
            this.message = msg.replace("{regex}", regexStr)
        }
    }
}

/**
 * for datetime
 */
public class DateTimeRangeConstraint <: Constraint {
    public DateTimeRangeConstraint(public let before: DateTime, public let after: DateTime, public let message: String) {}
}

public class ValidationException <: Exception {
    public let field: String
    public let condition: Constraint

    public init(message: String, field: String, condition: Constraint) {
        super(message)
        this.field = field
        this.condition = condition
    }
}
