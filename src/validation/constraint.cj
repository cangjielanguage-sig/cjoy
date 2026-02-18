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
 * 验证约束的基接口。
 *
 * 所有约束类型都实现此接口。
 */
public interface JoyConstraint {}

/**
 * 集合类型的大小约束。
 *
 * 验证集合大小在 [min, max] 范围内（含）。
 */
public class SizeConstraint <: JoyConstraint {
    /**
     * 描述约束违反的错误消息。
     */
    public let message: String

    /**
     * 创建 SizeConstraint。
     *
     * @param min 最小大小（含）
     * @param max 最大大小（含）
     * @param msg 自定义错误消息（支持 {min} 和 {max} 占位符）
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
 * 字符串类型的长度约束。
 *
 * 验证字符串长度在 [min, max] 范围内（含）。
 */
public class LengthConstraint <: JoyConstraint {
    /**
     * 描述约束违反的错误消息。
     */
    public let message: String

    /**
     * 创建 LengthConstraint。
     *
     * @param min 最小长度（含）
     * @param max 最大长度（含）
     * @param msg 自定义错误消息（支持 {min} 和 {max} 占位符）
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
 * 字符串类型的非空约束。
 *
 * 验证字符串不为空。
 */
public class NotEmptyConstraint <: JoyConstraint {
    /**
     * 描述约束违反的错误消息。
     */
    public let message: String

    /**
     * 创建 NotEmptyConstraint。
     *
     * @param msg 自定义错误消息
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
 * 字符串类型的非空白约束。
 *
 * 验证修剪后的字符串不为空白。
 */
public class NotBlankConstraint <: JoyConstraint {
    /**
     * 描述约束违反的错误消息。
     */
    public let message: String

    /**
     * 创建 NotBlankConstraint。
     *
     * @param msg 自定义错误消息
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
 * 数值类型的范围约束。
 *
 * 验证数字在 [min, max] 范围内（含）。
 */
public class RangeConstraint <: JoyConstraint {
    /**
     * 描述约束违反的错误消息。
     */
    public let message: String

    /**
     * 创建 RangeConstraint。
     *
     * @param min 最小值字符串（含）
     * @param max 最大值字符串（含）
     * @param msg 自定义错误消息（支持 {min} 和 {max} 占位符）
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
 * 字符串类型的正则表达式约束。
 *
 * 验证字符串是否匹配指定的正则表达式。
 */
public class PatternConstraint <: JoyConstraint {
    /**
     * 描述约束违反的错误消息。
     */
    public let message: String

    /**
     * 编译后的正则表达式。
     */
    public let regex: Regex

    /**
     * 创建 PatternConstraint。
     *
     * @param regexStr 正则表达式字符串
     * @param msg 自定义错误消息（支持 {regex} 占位符）
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
 * DateTime 范围约束。
 *
 * 验证 DateTime 是否在 [after, before] 范围内。
 */
public class DateTimeRangeConstraint <: JoyConstraint {
    /**
     * 描述约束违反的错误消息。
     */
    public let message: String

    /**
     * 创建 DateTimeRangeConstraint。
     *
     * @param before 允许的最大日期时间
     * @param after 允许的最小日期时间
     * @param msg 自定义错误消息（支持 {after} 和 {before} 占位符）
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
 * 中国手机号码约束。
 *
 * 验证字符串是否匹配中国手机号码格式。
 */
public class ChMobilePhoneConstraint <: JoyConstraint {
    /**
     * 描述约束违反的错误消息。
     */
    public let message: String

    /**
     * 中国手机号码的正则表达式。
     */
    public static let REGEX: Regex = Regex(#"^(?:\+86[\s-]?)?1[3456789]\d{9}$"#)

    /**
     * 创建 ChMobilePhoneConstraint。
     *
     * @param msg 自定义错误消息
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
 * 邮箱格式约束。
 *
 * 验证字符串是否匹配邮箱格式。
 */
public class EmailConstraint <: JoyConstraint {
    /**
     * 描述约束违反的错误消息。
     */
    public let message: String

    /**
     * 邮箱验证的正则表达式。
     */
    public static let REGEX: Regex = Regex(#"^[a-zA-Z0-9_-]+@[a-zA-Z0-9_-]+(\.[a-zA-Z0-9_-]+)+$"#)

    /**
     * 创建 EmailConstraint。
     *
     * @param msg 自定义错误消息
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
 * IPv4 地址格式约束。
 *
 * 验证字符串是否匹配 IPv4 地址格式。
 */
public class IPV4Constraint <: JoyConstraint {
    /**
     * 描述约束违反的错误消息。
     */
    public let message: String

    /**
     * IPv4 地址验证的正则表达式。
     */
    public static let REGEX: Regex = Regex(
        #"^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"#)

    /**
     * 创建 IPV4Constraint。
     *
     * @param msg 自定义错误消息
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
 * 枚举字符串约束。
 *
 * 验证字符串是否为允许的枚举值之一。
 */
public class EnumStrConstraint <: JoyConstraint {
    /**
     * 描述约束违反的错误消息。
     */
    public let message: String

    /**
     * 创建 EnumStrConstraint。
     *
     * @param values 允许的字符串值数组
     * @param msg 自定义错误消息
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
 * 枚举整数约束。
 *
 * 验证整数是否为允许的枚举值之一。
 */
public class EnumIntConstraint <: JoyConstraint {
    /**
     * 描述约束违反的错误消息。
     */
    public let message: String

    /**
     * 创建 EnumIntConstraint。
     *
     * @param values 允许的整数数组
     * @param msg 自定义错误消息
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
 * 约束验证失败的验证异常。
 *
 * 当约束验证失败时抛出。
 */
public class JoyValidationException <: Exception {
    /**
     * 验证失败的字段名。
     */
    public let field: String

    /**
     * 违反的约束。
     */
    public let constraint: JoyConstraint

    /**
     * 创建 JoyValidationException。
     *
     * @param message 错误消息
     * @param field 字段名
     * @param constraint 违反的约束
     */
    public init(message: String, field: String, constraint: JoyConstraint) {
        super(message)
        this.field = field
        this.constraint = constraint
    }

    /**
     * 将异常转换为映射用于 JSON 响应。
     *
     * @return 包含字段和错误消息的映射
     */
    public func toMap(): HashMap<String, String> {
        let res: HashMap<String, String> = HashMap()
        res.add("field", field)
        res.add("errMsg", message)
        res
    }
}
