/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and constraints of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.validation

import std.convert.Parsable
import std.collection.{HashMap, ArrayList}
import std.time.DateTime
import std.unicode.UnicodeStringExtension

/**
 * Interface for types that support validation with constraints.
 *
 * Types implementing this interface can be validated against various constraints
 * such as length, range, pattern, size, date range, etc.
 */
public interface JoyValidatable {
    /**
     * Validate field value with constraints.
     *
     * @param field field name
     * @param nestedValid whether to perform nested validation
     * @param constraints array of constraints to validate against
     * @throws JoyValidationException if validation fails
     */
    func validate(field: String, nestedValid: Bool, constraints: Array<JoyConstraint>): Unit

    /**
     * Validate all fields with constraints.
     *
     * @throws JoyValidationException if validation fails
     */
    func validate(): Unit {
        validate("", false)
    }
}

/**
 * Extend String to implement JoyValidatable.
 */
extend String <: JoyValidatable {
    /**
     * Validate string
 value with constraints.
     *
     * Supports constraints: LengthConstraint, NotEmptyConstraint,
     * NotBlankConstraint, PatternConstraint, ChMobilePhoneConstraint,
     * EmailConstraint, IPV4Constraint, EnumStrConstraint
     *
     * @param field field name
     * @param _ nested validation flag (unused)
     * @param constraints validation constraints
     * @throws JoyValidationException if validation fails
     */
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        for (condition in constraints) {
            match (condition) {
                case c: LengthConstraint =>
                    if (this.size < c.min || this.size > c.max) {
                        throw JoyValidationException(c.message, field, c)
                    }
                case c: NotEmptyConstraint =>
                    if (this.isEmpty()) {
                        throw JoyValidationException(c.message, field, c)
                    }
                case c: NotBlankConstraint =>
                    let val = this.trim()
                    if (val.isEmpty()) {
                        throw JoyValidationException(c.message, field, c)
                    }
                case c: PatternConstraint =>
                    if (!c.regex.matches(this)) {
                        throw JoyValidationException(c.message, field, c)
                    }
                case c: ChMobilePhoneConstraint =>
                    if (!ChMobilePhoneConstraint.REGEX.matches(this)) {
                        throw JoyValidationException(c.message, field, c)
                    }
                case c: EmailConstraint =>
                    if (!EmailConstraint.REGEX.matches(this)) {
                        throw JoyValidationException(c.message, field, c)
                    }
                    let arr = this.split("@")
                    if (arr.size != 2 || arr[0].size > 64 || arr[1].size > 256) {
                        throw JoyValidationException(c.message, field, c)
                    }
                case c: IPV4Constraint =>
                    if (!IPV4Constraint.REGEX.matches(this)) {
                        throw JoyValidationException(c.message, field, c)
                    }
                case c: EnumStrConstraint =>
                    if (!c.values.contains(this)) {
                        throw JoyValidationException(c.message, field, c)
                    }
                case _ => ()
            }
        }
    }
}

/**
 * Extend Option<T> to implement JoyValidatable.
 */
extend<T> Option<T> <: JoyValidatable where T <: JoyValidatable {
    /**
     * Validate optional
 value with constraints.
     *
     * Only validates if the option contains a value.
     *
     * @param field field name
     * @param nestedValid whether to perform nested validation
     * @param constraints validation constraints
     * @throws JoyValidationException if validation fails
     */
    public func validate(field: String, nestedValid: Bool, constraints: Array<JoyConstraint>): Unit {
        match (this) {
            case Some(v) => v.validate(field, nestedValid, constraints)
            case _ => ()
        }
    }
}

/**
 * Validate numeric value with constraints.
 *
 * @param value numeric value to validate
 * @param field field name
 * @param constraints validation constraints
 * @param toFn optional function to convert value to Int64 for enum validation
 * @throws JoyValidationException if validation fails
 */
func validateNumber<T>(value: T, field: String, constraints: Array<JoyConstraint>, toFn: ?() -> Int): Unit where T <: Parsable<T> & Comparable<T> & ToString {
    for (condition in constraints) {
        match (condition) {
            case c: RangeConstraint =>
                if (value < T.parse(c.min) || value > T.parse(c.max)) {
                    throw JoyValidationException(c.message, field, c)
                }
            case c: PatternConstraint =>
                if (!c.regex.matches(value.toString())) {
                    throw JoyValidationException(c.message, field, c)
                }
            case c: EnumIntConstraint =>
                if (let Some(f) <- toFn && !c.values.contains(f())) {
                    throw JoyValidationException(c.message, field, c)
                }
            case c: EnumStrConstraint =>
                if (!c.values.contains(value.toString())) {
                    throw JoyValidationException(c.message, field, c)
                }
            case _ => ()
        }
    }
}

/**
 * Extend Int8 to implement JoyValidatable.
 */
extend Int8 <: JoyValidatable {
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints, {=> Int64(this)})
    }
}

/**
 * Extend Int16 to implement JoyValidatable.
 */
extend Int16 <: JoyValidatable {
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints, {=> Int64(this)})
    }
}

/**
 * Extend Int32 to implement JoyValidatable.
 */
extend Int32 <: JoyValidatable {
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints, {=> Int64(this)})
    }
}

/**
 * Extend Int64 to implement JoyValidatable.
 */
extend Int64 <: JoyValidatable {
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints, {=> this})
    }
}

/**
 * Extend UInt8 to implement JoyValidatable.
 */
extend UInt8 <: JoyValidatable {
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints, {=> Int64(this)})
    }
}

/**
 * Extend UInt16 to implement JoyValidatable.
 */
extend UInt16 <: JoyValidatable {
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints, {=> Int64(this)})
    }
}

/**
 * Extend UInt32 to implement JoyValidatable.
 */
extend UInt32 <: JoyValidatable {
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints, {=> Int64(this)})
    }
}

/**
 * Extend UInt64 to implement JoyValidatable.
 */
extend UInt64 <: JoyValidatable {
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints, {=> Int64(this)})
    }
}

/**
 * Extend Float16 to implement JoyValidatable.
 */
extend Float16 <: JoyValidatable {
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints, None)
    }
}

/**
 * Extend Float32 to implement JoyValidatable.
 */
extend Float32 <: JoyValidatable {
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints, None)
    }
}

/**
 * Extend Float64 to implement JoyValidatable.
 */
extend Float64 <: JoyValidatable {
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints, None)
    }
}

/**
 * Validate collection value with constraints.
 *
 * @param col collection to validate
 * @param field field name
 * @param nestedValid whether to perform nested validation on elements
 * @param constraints validation constraints
 * @throws JoyValidationException if validation fails
 */
func validateCollection<T>(col: Collection<T>, field: String, nestedValid: Bool, constraints: Array<JoyConstraint>): Unit {
    for (condition in constraints) {
        match (condition) {
            case c: SizeConstraint =>
                if (col.size < c.min || col.size > c.max) {
                    throw JoyValidationException(c.message, field, c)
                }
            case _ => ()
        }
    }

    if (nestedValid && !col.isEmpty()) {
        var idx = 0
        for (c in col) {
            match (c) {
                case v: JoyValidatable => v.validate("${field}.${idx}", nestedValid, constraints)
                case _ => ()
            }
            idx++
        }
    }
}

/**
 * Extend Array<T> to implement JoyValidatable.
 */
extend<T> Array<T> <: JoyValidatable {
    public func validate(field: String, nestedValid: Bool, constraints: Array<JoyConstraint>): Unit {
        validateCollection(this, field, nestedValid, constraints)
    }
}

/**
 * Extend ArrayList<T> to implement JoyValidatable.
 */
extend<T> ArrayList<T> <: JoyValidatable {
    public func validate(field: String, nestedValid: Bool, constraints: Array<JoyConstraint>): Unit {
        validateCollection(this, field, nestedValid, constraints)
    }
}

/**
 * Extend HashMap<K, V> to implement JoyValidatable.
 */
extend<K, V> HashMap<K, V> <: JoyValidatable {
    public func validate(field: String, nestedValid: Bool, constraints: Array<JoyConstraint>): Unit {
        validateCollection(this.keys(), field, nestedValid, constraints)
        validateCollection(this.values(), field, nestedValid, constraints)
    }
}

/**
 * Extend DateTime to implement JoyValidatable.
 */
extend DateTime <: JoyValidatable {
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        for (condition in constraints) {
            match (condition) {
                case c: DateTimeRangeConstraint =>
                    if (this < c.after || this > c.before) {
                        throw JoyValidationException(c.message, field, c)
                    }
                case _ => ()
            }
        }
    }
}
