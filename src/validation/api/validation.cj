/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and constraints of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.validation.api

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

    func validate(): Unit {
        validate("", false)
    }
}

extend String <: JoyValidatable {
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
                case c: PattenConstraint =>
                    if (!c.regex.matches(this)) {
                        throw JoyValidationException(c.message, field, c)
                    }
                case _ => ()
            }
        }
    }
}

extend<T> Option<T> <: JoyValidatable where T <: JoyValidatable {
    public func validate(field: String, nestedValid: Bool, constraints: Array<JoyConstraint>): Unit {
        match (this) {
            case Some(v) => v.validate(field, nestedValid, constraints)
            case _ => ()
        }
    }
}

func validateNumber<T>(value: T, field: String, constraints: Array<JoyConstraint>): Unit where T <: Parsable<T> & Comparable<T> & ToString {
    for (condition in constraints) {
        match (condition) {
            case c: RangeConstraint =>
                if (value < T.parse(c.min) || value > T.parse(c.max)) {
                    throw JoyValidationException(c.message, field, c)
                }
            case c: PattenConstraint =>
                if (!c.regex.matches(value.toString())) {
                    throw JoyValidationException(c.message, field, c)
                }
            case _ => ()
        }
    }
}

extend Int8 <: JoyValidatable {
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints)
    }
}

extend Int16 <: JoyValidatable {
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints)
    }
}

extend Int32 <: JoyValidatable {
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints)
    }
}

extend Int64 <: JoyValidatable {
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints)
    }
}

extend UInt8 <: JoyValidatable {
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints)
    }
}

extend UInt16 <: JoyValidatable {
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints)
    }
}

extend UInt32 <: JoyValidatable {
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints)
    }
}

extend UInt64 <: JoyValidatable {
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints)
    }
}

extend Float16 <: JoyValidatable {
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints)
    }
}

extend Float32 <: JoyValidatable {
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints)
    }
}

extend Float64 <: JoyValidatable {
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints)
    }
}

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
    public func validate(field: String, nestedValid: Bool, constraints: Array<JoyConstraint>): Unit {
        validateCollection(this, field, nestedValid, constraints)
    }
}

extend<T> ArrayList<T> <: JoyValidatable {
    public func validate(field: String, nestedValid: Bool, constraints: Array<JoyConstraint>): Unit {
        validateCollection(this, field, nestedValid, constraints)
    }
}

extend<K, V> HashMap<K, V> <: JoyValidatable {
    public func validate(field: String, nestedValid: Bool, constraints: Array<JoyConstraint>): Unit {
        validateCollection(this.keys(), field, nestedValid, constraints)
        validateCollection(this.values(), field, nestedValid, constraints)
    }
}

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
