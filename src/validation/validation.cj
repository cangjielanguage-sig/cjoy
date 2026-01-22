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

public interface JoyValidatable {
    /**
     * validate the field value with the constraints
     *
     * @param field: the field name
     * @param nestedValid: whether to nested validate
     * @param constraints: a array of constraints
     * @throws JoyValidationException if validate failed
     */
    func validate(field: String, nestedValid: Bool, constraints: Array<JoyConstraint>): Unit

    /**
     * validate all fields with constraints
     *
     * @throws JoyValidationException if validate failed
     */
    func validate(): Unit {
        validate("", false)
    }
}

extend String <: JoyValidatable {
    /**
     * validate string value with constraints
     *
     * @param field: the field name
     * @param constraints: the validation constraints
     * @throws JoyValidationException if validate failed
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

extend<T> Option<T> <: JoyValidatable where T <: JoyValidatable {
    /**
     * validate optional value with constraints
     *
     * @param field: the field name
     * @param nestedValid: whether to nested validate
     * @param constraints: the validation constraints
     * @throws JoyValidationException if validate failed
     */
    public func validate(field: String, nestedValid: Bool, constraints: Array<JoyConstraint>): Unit {
        match (this) {
            case Some(v) => v.validate(field, nestedValid, constraints)
            case _ => ()
        }
    }
}

/**
 * validate number value with constraints
 *
 * @param value: the number value
 * @param field: the field name
 * @param constraints: the validation constraints
 * @param toFn: the function to convert value to Int64 for enum int validation
 * @throws JoyValidationException if validate failed
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

extend Int8 <: JoyValidatable {
    /**
     * validate int8 value with constraints
     *
     * @param field: the field name
     * @param constraints: the validation constraints
     * @throws JoyValidationException if validate failed
     */
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints, {=> Int64(this)})
    }
}

extend Int16 <: JoyValidatable {
    /**
     * validate int16 value with constraints
     *
     * @param field: the field name
     * @param constraints: the validation constraints
     * @throws JoyValidationException if validate failed
     */
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints, {=> Int64(this)})
    }
}

extend Int32 <: JoyValidatable {
    /**
     * validate int32 value with constraints
     *
     * @param field: the field name
     * @param constraints: the validation constraints
     * @throws JoyValidationException if validate failed
     */
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints, {=> Int64(this)})
    }
}

extend Int64 <: JoyValidatable {
    /**
     * validate int64 value with constraints
     *
     * @param field: the field name
     * @param constraints: the validation constraints
     * @throws JoyValidationException if validate failed
     */
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints, {=> this})
    }
}

extend UInt8 <: JoyValidatable {
    /**
     * validate uint8 value with constraints
     *
     * @param field: the field name
     * @param constraints: the validation constraints
     * @throws JoyValidationException if validate failed
     */
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints, {=> Int64(this)})
    }
}

extend UInt16 <: JoyValidatable {
    /**
     * validate uint16 value with constraints
     *
     * @param field: the field name
     * @param constraints: the validation constraints
     * @throws JoyValidationException if validate failed
     */
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints, {=> Int64(this)})
    }
}

extend UInt32 <: JoyValidatable {
    /**
     * validate uint32 value with constraints
     *
     * @param field: the field name
     * @param constraints: the validation constraints
     * @throws JoyValidationException if validate failed
     */
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints, {=> Int64(this)})
    }
}

extend UInt64 <: JoyValidatable {
    /**
     * validate uint64 value with constraints
     *
     * @param field: the field name
     * @param constraints: the validation constraints
     * @throws JoyValidationException if validate failed
     */
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints, {=> Int64(this)})
    }
}

extend Float16 <: JoyValidatable {
    /**
     * validate float16 value with constraints
     *
     * @param field: the field name
     * @param constraints: the validation constraints
     * @throws JoyValidationException if validate failed
     */
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints, None)
    }
}

extend Float32 <: JoyValidatable {
    /**
     * validate float32 value with constraints
     *
     * @param field: the field name
     * @param constraints: the validation constraints
     * @throws JoyValidationException if validate failed
     */
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints, None)
    }
}

extend Float64 <: JoyValidatable {
    /**
     * validate float64 value with constraints
     *
     * @param field: the field name
     * @param constraints: the validation constraints
     * @throws JoyValidationException if validate failed
     */
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints, None)
    }
}

/**
 * validate collection value with constraints
 *
 * @param col: the collection
 * @param field: the field name
 * @param nestedValid: whether to nested validate elements
 * @param constraints: the validation constraints
 * @throws JoyValidationException if validate failed
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

extend<T> Array<T> <: JoyValidatable {
    /**
     * validate array value with constraints
     *
     * @param field: the field name
     * @param nestedValid: whether to nested validate elements
     * @param constraints: the validation constraints
     * @throws JoyValidationException if validate failed
     */
    public func validate(field: String, nestedValid: Bool, constraints: Array<JoyConstraint>): Unit {
        validateCollection(this, field, nestedValid, constraints)
    }
}

extend<T> ArrayList<T> <: JoyValidatable {
    /**
     * validate array list value with constraints
     *
     * @param field: the field name
     * @param nestedValid: whether to nested validate elements
     * @param constraints: the validation constraints
     * @throws JoyValidationException if validate failed
     */
    public func validate(field: String, nestedValid: Bool, constraints: Array<JoyConstraint>): Unit {
        validateCollection(this, field, nestedValid, constraints)
    }
}

extend<K, V> HashMap<K, V> <: JoyValidatable {
    /**
     * validate hashmap value with constraints
     *
     * @param field: the field name
     * @param nestedValid: whether to nested validate keys and values
     * @param constraints: the validation constraints
     * @throws JoyValidationException if validate failed
     */
    public func validate(field: String, nestedValid: Bool, constraints: Array<JoyConstraint>): Unit {
        validateCollection(this.keys(), field, nestedValid, constraints)
        validateCollection(this.values(), field, nestedValid, constraints)
    }
}

extend DateTime <: JoyValidatable {
    /**
     * validate datetime value with constraints
     *
     * @param field: the field name
     * @param constraints: the validation constraints
     * @throws JoyValidationException if validate failed
     */
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
