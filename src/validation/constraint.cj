/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.validation

import std.regex.Regex
import std.time.DateTime
import std.collection.HashMap

/**
 * base interface for validation constraints
 */
public interface JoyConstraint {}

/**
 * size constraint for collection
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
 * length constraint for string
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
 * not empty constraint for string
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
 * not blank constraint for string
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
 * range constraint for number
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
 * regex pattern constraint for string
 */
public class PatternConstraint <: JoyConstraint {
    public let message: String
    public let regex: Regex
    public PatternConstraint(let regexStr: String, let msg: String) {
        this.regex = Regex(regexStr)
        if (msg.isEmpty()) {
            this.message = "this constraint of value is Pattern[${regexStr}]"
        } else {
            this.message = msg.replace("{regex}", regexStr)
        }
    }
}

/**
 * datetime range constraint
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

/**
 * chinese mobile phone number constraint
 */
public class ChMobilePhoneConstraint <: JoyConstraint {
    public let message: String
    public static let REGEX: Regex = Regex(#"^(?:\+86[\s-]?)?1[3456789]\d{9}$"#)
    public ChMobilePhoneConstraint(let msg: String) {
        if (msg.isEmpty()) {
            this.message = "this constraint of value is chinese mobile phone number"
        } else {
            this.message = msg
        }
    }
}

/**
 * email format constraint
 */
public class EmailConstraint <: JoyConstraint {
    public let message: String
    public static let REGEX: Regex = Regex(#"^[a-zA-Z0-9_-]+@[a-zA-Z0-9_-]+(\.[a-zA-Z0-9_-]+)+$"#)
    public EmailConstraint(let msg: String) {
        if (msg.isEmpty()) {
            this.message = "this constraint of value is email"
        } else {
            this.message = msg
        }
    }
}

/**
 * IPv4 address format constraint
 */
public class IPV4Constraint <: JoyConstraint {
    public let message: String
    public static let REGEX: Regex = Regex(
        #"^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"#)
    public IPV4Constraint(let msg: String) {
        if (msg.isEmpty()) {
            this.message = "this constraint of value is IP V4"
        } else {
            this.message = msg
        }
    }
}

/**
 * enum string constraint
 */
public class EnumStrConstraint <: JoyConstraint {
    public let message: String
    public EnumStrConstraint(public let values: Array<String>, let msg: String) {
        if (msg.isEmpty()) {
            this.message = "this constraint of value is ${values}"
        } else {
            this.message = msg
        }
    }
}

/**
 * enum integer constraint
 */
public class EnumIntConstraint <: JoyConstraint {
    public let message: String
    public EnumIntConstraint(public let values: Array<Int>, let msg: String) {
        if (msg.isEmpty()) {
            this.message = "this constraint of value is ${values}"
        } else {
            this.message = msg
        }
    }
}

/**
 * validation exception for constraint violation
 */
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
