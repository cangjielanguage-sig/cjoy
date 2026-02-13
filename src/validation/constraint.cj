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
 * Base interface for validation constraints.
 *
 * All constraint types implement this interface.
 */
public interface JoyConstraint {}

/**
 * Size constraint for collection types.
 *
 * Validates that collection size is within [min, max] range (inclusive).
 */
public class SizeConstraint <: JoyConstraint {
    /**
     * Error message describing constraint violation.
     */
    public let message: String

    /**
     * Create SizeConstraint.
     *
     * @param min minimum size (inclusive)
     * @param max maximum size (inclusive)
     * @param msg custom error message (supports {min} and {max} placeholders)
     */
    public SizeConstraint(public let min: Int, public let max: Int, let msg: String) {
        if (msg.isEmpty()) {
            this.message = "this constraint of value is Size[${min}, ${max}]"
        } else {
            this.message = msg.replace("{min}", min.toString()).replace("{max}", max.toString())
        }
    }
}

/**
 * Length constraint for string types.
 *
 * Validates that string length is within [min, max] range (inclusive).
 */
public class LengthConstraint <: JoyConstraint {
    /**
     * Error message describing constraint violation.
     */
    public let message: String

    /**
     * Create LengthConstraint.
     *
     * @param min minimum length (inclusive)
     * @param max maximum length (inclusive)
     * @param msg custom error message (supports {min} and {max} placeholders)
     */
    public LengthConstraint(public let min: Int, public let max: Int, let msg: String) {
        if (msg.isEmpty()) {
            this.message = "this constraint of value is Length[${min}, ${max}]"
        } else {
            this.message = msg.replace("{min}", min.toString()).replace("{max}", max.toString())
        }
    }
}

/**
 * Not empty constraint for string types.
 *
 * Validates that string is not empty.
 */
public class NotEmptyConstraint <: JoyConstraint {
    /**
     * Error message describing constraint violation.
     */
    public let message: String

    /**
     * Create NotEmptyConstraint.
     *
     * @param msg custom error message
     */
    public NotEmptyConstraint(let msg: String) {
        if (msg.isEmpty()) {
            this.message = "this constraint of value is NOT EMPTY"
        } else {
            this.message = msg
        }
    }
}

/**
 * Not blank constraint for string types.
 *
 * Validates that trimmed string is not blank.
 */
public class NotBlankConstraint <: JoyConstraint {
    /**
     * Error message describing constraint violation.
     */
    public let message: String

    /**
     * Create NotBlankConstraint.
     *
     * @param msg custom error message
     */
    public NotBlankConstraint(let msg: String) {
        if (msg.isEmpty()) {
            this.message = "this constraint of value is NOT BLANK"
        } else {
            this.message = msg
        }
    }
}

/**
 * Range constraint for numeric types.
 *
 * Validates that number is within [min, max] range (inclusive).
 */
public class RangeConstraint <: JoyConstraint {
    /**
     * Error message describing constraint violation.
     */
    public let message: String

    /**
     * Create RangeConstraint.
     *
     * @param min minimum value as string (inclusive)
     * @param max maximum value as string (inclusive)
     * @param msg custom error message (supports {min} and {max} placeholders)
     */
    public RangeConstraint(public let min: String, public let max: String, let msg: String) {
        if (msg.isEmpty()) {
            this.message = "this constraint of value is NumberRange[${min}, ${max}]"
        } else {
            this.message = msg.replace("{min}", min.toString()).replace("{max}", max.toString())
        }
    }
}

/**
 * Regex pattern constraint for string types.
 *
 * Validates that string matches the specified regex pattern.
 */
public class PatternConstraint <: JoyConstraint {
    /**
     * Error describing constraint violation.
     */
    public let message: String

    /**
     * Compiled regex pattern.
     */
    public let regex: Regex

    /**
     * Create PatternConstraint.
     *
     * @param regexStr regex pattern string
     * @param msg custom error message (supports {regex} placeholder)
     */
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
 * DateTime range constraint.
 *
 * Validates that DateTime is within [after, before] range.
 */
public class DateTimeRangeConstraint <: JoyConstraint {
    /**
     * Error message describing constraint violation.
     */
    public let message: String

    /**
     * Create DateTimeRangeConstraint.
     *
     * @param before maximum allowed datetime
     * @param after minimum allowed datetime
     * @param msg custom error message (supports {after} and {before} placeholders)
     */
    public DateTimeRangeConstraint(public let before: DateTime, public let after: DateTime, public let msg: String) {
        if (msg.isEmpty()) {
            this.message = "this constraint of value is DateTimeRange[${after}, ${before}]"
        } else {
            this.message = msg.replace("{after}", after.toString()).replace("{before}", before.toString())
        }
    }
}

/**
 * Chinese mobile phone number constraint.
 *
 * Validates that string matches Chinese mobile phone format.
 */
public class ChMobilePhoneConstraint <: JoyConstraint {
    /**
     * Error message describing constraint violation.
     */
    public let message: String

    /**
     * Regex pattern for Chinese mobile phone numbers.
     */
    public static let REGEX: Regex = Regex(#"^(?:\+86[\s-]?)?1[3456789]\d{9}$"#)

    /**
     * Create ChMobilePhoneConstraint.
     *
     * @param msg custom error message
     */
    public ChMobilePhoneConstraint(let msg: String) {
        if (msg.isEmpty()) {
            this.message = "this constraint of value is chinese mobile phone number"
        } else {
            this.message = msg
        }
    }
}

/**
 * Email format constraint.
 *
 * Validates that string matches email format.
 */
public class EmailConstraint <: JoyConstraint {
    /**
     * Error message describing constraint violation.
     */
    public let message: String

    /**
     * Regex pattern for email validation.
     */
    public static let REGEX: Regex = Regex(#"^[a-zA-Z0-9_-]+@[a-zA-Z0-9_-]+(\.[a-zA-Z0-9_-]+)+$"#)

    /**
     * Create EmailConstraint.
     *
     * @param msg custom error message
     */
    public EmailConstraint(let msg: String) {
        if (msg.isEmpty()) {
            this.message = "this constraint of value is email"
        } else {
            this.message = msg
        }
    }
}

/**
 * IPv4 address format constraint.
 *
 * Validates that string matches IPv4 address format.
 */
public class IPV4Constraint <: JoyConstraint {
    /**
     * Error message describing constraint violation.
     */
    public let message: String

    /**
     * Regex pattern for IPv4 address validation.
     */
    public static let REGEX: Regex = Regex(
        #"^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"#)

    /**
     * Create IPV4Constraint.
     *
     * @param msg custom error message
     */
    public IPV4Constraint(let msg: String) {
        if (msg.isEmpty()) {
            this.message = "this constraint of value is IP V4"
        } else {
            this.message = msg
        }
    }
}

/**
 * Enum string constraint.
 *
 * Validates that string is one of the allowed enum values.
 */
public class EnumStrConstraint <: JoyConstraint {
    /**
     * Error message describing constraint violation.
     */
    public let message: String

    /**
     * Create EnumStrConstraint.
     *
     * @param values allowed string values
     * @param msg custom error message
     */
    public EnumStrConstraint(public let values: Array<String>, let msg: String) {
        if (msg.isEmpty()) {
            this.message = "this constraint of value is ${values}"
        } else {
            this.message = msg
        }
    }
}

/**
 * Enum integer constraint.
 *
 * Validates that integer is one of the allowed enum values.
 */
public class EnumIntConstraint <: JoyConstraint {
    /**
     * Error message describing constraint violation.
     */
    public let message: String

    /**
     * Create EnumIntConstraint.
     *
     * @param values allowed integer values
     * @param msg custom error message
     */
    public EnumIntConstraint(public let values: Array<Int>, let msg: String) {
        if (msg.isEmpty()) {
            this.message = "this constraint of value is ${values}"
        } else {
            this.message = msg
        }
    }
}

/**
 * Validation exception for constraint violation.
 *
 * Thrown when a constraint validation fails.
 */
public class JoyValidationException <: Exception {
    /**
     * Field name that failed validation.
     */
    public let field: String

    /**
     * Constraint that was violated.
     */
    public let constraint: JoyConstraint

    /**
     * Create JoyValidationException.
     *
     * @param message error message
     * @param field field name
     * @param constraint violated constraint
     */
    public init(message: String, field: String, constraint: JoyConstraint) {
        super(message)
        this.field = field
        this.constraint = constraint
    }

    /**
     * Convert exception to map for JSON response.
     *
     * @return map containing field and error message
     */
    public func toMap(): HashMap<String, String> {
        let res: HashMap<String, String> = HashMap()
        res.add("field", field)
        res.add("errMsg", message)
        res
    }
}
