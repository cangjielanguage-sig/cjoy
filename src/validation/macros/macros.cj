/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

macro package cjoy.validation.macros

import std.ast.Tokens

/**
 * 应用于类或结构体，生成代码以实现 'JoyValidatable' 接口
 */
public macro Valid(input: Tokens): Tokens {
    input + ValidClassInfo.parse(input)
}

/**
 * 表示对此成员类或结构体进行嵌套验证
 */
public macro NestedValid(input: Tokens): Tokens {
    parseNestedValid(input)
    input
}

/**
 * 应用于函数，生成代码修改函数体，为调用参数添加 'validate' 方法
 */
public macro Validated(input: Tokens): Tokens {
    parseValidated(input)
}

/**
 * 验证集合的大小
 *
 * @attribute min 最小大小
 * @attribute max 最大大小
 * @attribute msg 验证错误提示
 */
public macro Size(attr: Tokens, input: Tokens): Tokens {
    parseConstraint(CCSize, attr, input)
    input
}

/**
 * 验证字符串的长度
 *
 * @attribute min 最小长度
 * @attribute max 最大长度
 * @attribute msg 验证错误提示
 */
public macro Length(attr: Tokens, input: Tokens): Tokens {
    parseConstraint(CCLength, attr, input)
    input
}

/**
 * 验证字符串不为空
 *
 * @attribute msg 验证错误提示
 */
public macro NotEmpty(attr: Tokens, input: Tokens): Tokens {
    parseConstraint(CCNotEmpty, attr, input)
    input
}

/**
 * 验证字符串不为空白
 *
 * @attribute msg 验证错误提示
 */
public macro NotBlank(attr: Tokens, input: Tokens): Tokens {
    parseConstraint(CCNotBlank, attr, input)
    input
}

/**
 * 验证字符串不为空
 */
public macro NotEmpty(input: Tokens): Tokens {
    parseConstraint(CCNotEmpty, input)
    input
}

/**
 * 验证字符串不为空白
 */
public macro NotBlank(input: Tokens): Tokens {
    parseConstraint(CCNotBlank, input)
    input
}

/**
 * 验证数字（如 int、float 等）的范围
 *
 * @attribute min 最小值
 * @attribute max 最大值
 * @attribute msg 验证错误提示
 */
public macro NumberRange(attr: Tokens, input: Tokens): Tokens {
    parseConstraint(CCNumberRange, attr, input)
    input
}

/**
 * 验证数字或字符串是否匹配正则表达式模式
 *
 * @attribute regex 正则表达式模式
 * @attribute msg 验证错误提示
 */
public macro Pattern(attr: Tokens, input: Tokens): Tokens {
    parseConstraint(CCPattern, attr, input)
    input
}

/**
 * 验证日期时间的范围
 *
 * @attribute before 在此时间之前，支持表达式
 * @attribute after 在此时间之后，支持表达式
 * @attribute msg 验证错误提示
 */
public macro DateTimeRange(attr: Tokens, input: Tokens): Tokens {
    parseConstraint(CCDatetimeRange, attr, input)
    input
}

/**
 * 验证字符串是否是中国手机号码
 *
 * @attribute msg 验证错误提示
 */
public macro ChMobileNumber(attr: Tokens, input: Tokens): Tokens {
    parseConstraint(CCChMobilePhone, attr, input)
    input
}

/**
 * 验证字符串是否是中国手机号码
 */
public macro ChMobileNumber(input: Tokens): Tokens {
    parseConstraint(CCChMobilePhone, input)
    input
}

/**
 * 验证字符串是否是电子邮件地址
 *
 * @attribute msg 验证错误提示
 */
public macro Email(attr: Tokens, input: Tokens): Tokens {
    parseConstraint(CCEmail, attr, input)
    input
}

/**
 * 验证字符串是否是电子邮件地址
 */
public macro Email(input: Tokens): Tokens {
    parseConstraint(CCEmail, input)
    input
}

/**
 * 验证字符串是否是 IPv4 地址
 *
 * @attribute msg 验证错误提示
 */
public macro IPV4(attr: Tokens, input: Tokens): Tokens {
    parseConstraint(CCIPV4, attr, input)
    input
}

/**
 * 验证字符串是否是 IPv4 地址
 */
public macro IPV4(input: Tokens): Tokens {
    parseConstraint(CCIPV4, input)
    input
}

/**
 * 验证字符串是否匹配枚举值
 *
 * @attribute values 枚举值列表
 * @attribute msg 验证错误提示
 */
public macro EnumStr(attr: Tokens, input: Tokens): Tokens {
    parseConstraint(CCEnumStr, attr, input)
    input
}

/**
 * 验证数字是否匹配枚举值
 *
 * @attribute values 枚举值列表
 * @attribute msg 验证错误提示
 */
public macro EnumInt(attr: Tokens, input: Tokens): Tokens {
    parseConstraint(CCEnumInt, attr, input)
    input
}
