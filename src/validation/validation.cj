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
 * 支持约束验证的类型的接口。
 *
 * 实现此接口的类型可以针对各种约束进行验证，
 * 如长度、范围、模式、大小、日期范围等。
 */
public interface JoyValidatable {
    /**
     * 使用约束验证字段值。
     *
     * @param field 字段名
     * @param nestedValid 是否执行嵌套验证
     * @param constraints 要验证的约束数组
     * @throws JoyValidationException 如果验证失败
     */
    func validate(field: String, nestedValid: Bool, constraints: Array<JoyConstraint>): Unit

    /**
     * 使用约束验证所有字段。
     *
     * @throws JoyValidationException 如果验证失败
     */
    func validate(): Unit {
        validate("", false)
    }
}

/**
 * 扩展 String 实现 JoyValidatable。
 */
extend String <: JoyValidatable {
    /**
     * 使用约束验证字符串值。
     *
     * 支持的约束：LengthConstraint、NotEmptyConstraint、
     * NotBlankConstraint、PatternConstraint、ChMobilePhoneConstraint、
     * EmailConstraint、IPV4Constraint、EnumStrConstraint
     *
     * @param field 字段名
     * @param _ 嵌套验证标志（未使用）
     * @param constraints 验证约束
     * @throws JoyValidationException 如果验证失败
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
                    if (arr.size != 2 || arr[0].size > 64 || arr[1].size > 255) {
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
                case c: EqualFieldConstraint =>
                    // 对于 EqualFieldConstraint，我们需要在类级别进行验证，因为它需要访问其他字段
                    // 这里不做处理，因为无法访问其他字段
                    ()
                case _ => ()
            }
        }
    }
}

/**
 * 扩展 Option<T> 实现 JoyValidatable。
 */
extend<T> Option<T> <: JoyValidatable where T <: JoyValidatable {
    /**
     * 使用约束验证可选值。
     *
     * 仅在选项包含值时进行验证。
     *
     * @param field 字段名
     * @param nestedValid 是否执行嵌套验证
     * @param constraints 验证约束
     * @throws JoyValidationException 如果验证失败
     */
    public func validate(field: String, nestedValid: Bool, constraints: Array<JoyConstraint>): Unit {
        match (this) {
            case Some(v) => v.validate(field, nestedValid, constraints)
            case _ => ()
        }
    }
}

/**
 * 使用约束验证数值。
 *
 * @param value 要验证的数值
 * @param field 字段名
 * @param constraints 验证约束
 * @param toFn 可选函数，用于将值转换为 Int64 以进行枚举验证
 * @throws JoyValidationException 如果验证失败
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
 * 扩展 Int8 类型以实现 JoyValidatable 接口。
 */
extend Int8 <: JoyValidatable {
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints, {=> Int64(this)})
    }
}

/**
 * 扩展 Int16 类型以实现 JoyValidatable 接口。
 */
extend Int16 <: JoyValidatable {
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints, {=> Int64(this)})
    }
}

/**
 * 扩展 Int32 类型以实现 JoyValidatable 接口。
 */
extend Int32 <: JoyValidatable {
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints, {=> Int64(this)})
    }
}

/**
 * 扩展 Int64 类型以实现 JoyValidatable 接口。
 */
extend Int64 <: JoyValidatable {
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints, {=> this})
    }
}

/**
 * 扩展 UInt8 类型以实现 JoyValidatable 接口。
 */
extend UInt8 <: JoyValidatable {
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints, {=> Int64(this)})
    }
}

/**
 * 扩展 UInt16 类型以实现 JoyValidatable 接口。
 */
extend UInt16 <: JoyValidatable {
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints, {=> Int64(this)})
    }
}

/**
 * 扩展 UInt32 类型以实现 JoyValidatable 接口。
 */
extend UInt32 <: JoyValidatable {
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints, {=> Int64(this)})
    }
}

/**
 * 扩展 UInt64 类型以实现 JoyValidatable 接口。
 */
extend UInt64 <: JoyValidatable {
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints, {=> Int64(this)})
    }
}

/**
 * 扩展 Float16 类型以实现 JoyValidatable 接口。
 */
extend Float16 <: JoyValidatable {
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints, None)
    }
}

/**
 * 扩展 Float32 类型以实现 JoyValidatable 接口。
 */
extend Float32 <: JoyValidatable {
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints, None)
    }
}

/**
 * 扩展 Float64 类型以实现 JoyValidatable 接口。
 */
extend Float64 <: JoyValidatable {
    public func validate(field: String, _: Bool, constraints: Array<JoyConstraint>): Unit {
        validateNumber(this, field, constraints, None)
    }
}

/**
 * 使用约束验证集合值。
 *
 * @param col 要验证的集合
 * @param field 字段名
 * @param nestedValid 是否对元素执行嵌套验证
 * @param constraints 验证约束
 * @throws JoyValidationException 如果验证失败
 */
func validateCollection<T>(col: Collection<T>, field: String, nestedValid: Bool, constraints: Array<JoyConstraint>): Unit {
    for (condition in constraints) {
        match (condition) {
            case c: SizeConstraint =>
                if (col.size < c.min || col.size > c.max) {
                    throw JoyValidationException(c.message, field, c)
                }
            case c: NotEmptyConstraint =>
                if (col.isEmpty()) {
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
 * 扩展 Array<T> 类型以实现 JoyValidatable 接口。
 */
extend<T> Array<T> <: JoyValidatable {
    public func validate(field: String, nestedValid: Bool, constraints: Array<JoyConstraint>): Unit {
        validateCollection(this, field, nestedValid, constraints)
    }
}

/**
 * 扩展 ArrayList<T> 类型以实现 JoyValidatable 接口。
 */
extend<T> ArrayList<T> <: JoyValidatable {
    public func validate(field: String, nestedValid: Bool, constraints: Array<JoyConstraint>): Unit {
        validateCollection(this, field, nestedValid, constraints)
    }
}

/**
 * 扩展 HashMap<K, V> 类型以实现 JoyValidatable 接口。
 */
extend<K, V> HashMap<K, V> <: JoyValidatable {
    public func validate(field: String, nestedValid: Bool, constraints: Array<JoyConstraint>): Unit {
        validateCollection(this.keys(), field, nestedValid, constraints)
        validateCollection(this.values(), field, nestedValid, constraints)
    }
}

/**
 * 扩展 DateTime 类型以实现 JoyValidatable 接口。
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
