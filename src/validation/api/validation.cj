/*
 * Copyright (c) lanlingx 2025-present. All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and constraints of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.validation.api

import std.convert.Parsable
import std.unicode.UnicodeStringExtension
import std.collection.{HashMap, ArrayList}
import std.time.DateTime

public interface Validatable {
    func validate(field: String, nestedValid: Bool, constraints: Array<Constraint>): Unit

    func validate(): Unit {
        validate("", false)
    }
}

extend String <: Validatable {
    public func validate(field: String, nestedValid: Bool, constraints: Array<Constraint>): Unit {
        for (condition in constraints) {
            match (condition) {
                case c: LengthConstraint =>
                    if (this.size > c.min || this.size > c.max) {
                        throw ValidationException(c.message, field, c)
                    }
                case c: NotEmptyConstraint =>
                    if (this.isEmpty()) {
                        throw ValidationException(c.message, field, c)
                    }
                case c: NotBlankConstraint =>
                    let val = this.trim()
                    if (val.isEmpty()) {
                        throw ValidationException(c.message, field, c)
                    }
                case c: PattenConstraint =>
                    if (!c.regex.matches(this)) {
                        throw ValidationException(c.message, field, c)
                    }
                case _ => ()
            }
        }
    }
}

extend<T> Option<T> <: Validatable where T <: Validatable {
    public func validate(field: String, nestedValid: Bool, constraints: Array<Constraint>): Unit {
        match (this) {
            case Some(v) => v.validate(field, nestedValid, constraints)
            case _ => ()
        }
    }
}

func validateNumber<T>(value: T, field: String, constraints: Array<Constraint>): Unit where T <: Parsable<T> & Comparable<T> {
    for (condition in constraints) {
        match (condition) {
            case c: RangeConstraint =>
                if (value < T.parse(c.min) || value > T.parse(c.max)) {
                    throw ValidationException(c.message, field, c)
                }
            case _ => ()
        }
    }
}

extend Int8 <: Validatable {
    public func validate(field: String, nestedValid: Bool, constraints: Array<Constraint>): Unit {
        validateNumber(this, field, constraints)
    }
}

extend Int16 <: Validatable {
    public func validate(field: String, nestedValid: Bool, constraints: Array<Constraint>): Unit {
        validateNumber(this, field, constraints)
    }
}

extend Int32 <: Validatable {
    public func validate(field: String, nestedValid: Bool, constraints: Array<Constraint>): Unit {
        validateNumber(this, field, constraints)
    }
}

extend Int64 <: Validatable {
    public func validate(field: String, nestedValid: Bool, constraints: Array<Constraint>): Unit {
        validateNumber(this, field, constraints)
    }
}

extend UInt8 <: Validatable {
    public func validate(field: String, nestedValid: Bool, constraints: Array<Constraint>): Unit {
        validateNumber(this, field, constraints)
    }
}

extend UInt16 <: Validatable {
    public func validate(field: String, nestedValid: Bool, constraints: Array<Constraint>): Unit {
        validateNumber(this, field, constraints)
    }
}

extend UInt32 <: Validatable {
    public func validate(field: String, nestedValid: Bool, constraints: Array<Constraint>): Unit {
        validateNumber(this, field, constraints)
    }
}

extend UInt64 <: Validatable {
    public func validate(field: String, nestedValid: Bool, constraints: Array<Constraint>): Unit {
        validateNumber(this, field, constraints)
    }
}

extend Float16 <: Validatable {
    public func validate(field: String, nestedValid: Bool, constraints: Array<Constraint>): Unit {
        validateNumber(this, field, constraints)
    }
}

extend Float32 <: Validatable {
    public func validate(field: String, nestedValid: Bool, constraints: Array<Constraint>): Unit {
        validateNumber(this, field, constraints)
    }
}

extend Float64 <: Validatable {
    public func validate(field: String, nestedValid: Bool, constraints: Array<Constraint>): Unit {
        validateNumber(this, field, constraints)
    }
}

func validateCollection<T>(col: Collection<T>, field: String, nestedValid: Bool, constraints: Array<Constraint>): Unit {
    for (condition in constraints) {
        match (condition) {
            case c: SizeConstraint =>
                if (col.size < c.min || col.size > c.max) {
                    throw ValidationException(c.message, field, c)
                }
            case _ => ()
        }
    }

    if (nestedValid && !col.isEmpty()) {
        var idx = 0
        for (c in col) {
            match (c) {
                case v: Validatable => v.validate("${field}.${idx}", nestedValid, constraints)
                case _ => ()
            }
            idx++
        }
    }
}

extend<T> Array<T> <: Validatable {
    public func validate(field: String, nestedValid: Bool, constraints: Array<Constraint>): Unit {
        validateCollection(this, field, nestedValid, constraints)
    }
}

extend<T> ArrayList<T> <: Validatable {
    public func validate(field: String, nestedValid: Bool, constraints: Array<Constraint>): Unit {
        validateCollection(this, field, nestedValid, constraints)
    }
}

extend<K, V> HashMap<K, V> <: Validatable {
    public func validate(field: String, nestedValid: Bool, constraints: Array<Constraint>): Unit {
        validateCollection(this.keys(), field, nestedValid, constraints)
        validateCollection(this.values(), field, nestedValid, constraints)
    }
}

extend DateTime <: Validatable {
    public func validate(field: String, nestedValid: Bool, constraints: Array<Constraint>): Unit {
        for (condition in constraints) {
            match (condition) {
                case c: DateTimeRangeConstraint =>
                    if (this < c.before || this > c.after) {
                        throw ValidationException(c.message, field, c)
                    }
                case _ => ()
            }
        }
    }
}
