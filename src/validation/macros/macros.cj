/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
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
 * apply to a class & struct to generate code to implement the 'JoyValidatable' interface
 */
public macro Valid(input: Tokens): Tokens {
    input + ValidClassInfo.parse(input)
}

/**
 * indicating nested validation of this member class or struct
 */
public macro NestedValid(input: Tokens): Tokens {
    parseNestedValid(input)
    input
}

/**
 * apply to a function to generated code it modify the function body to add a 'validate' method for calling parameters
 */
public macro Validated(input: Tokens): Tokens {
    parseValidated(input)
}

/**
 * Validate the Size of collection
 *
 * @attribute min: the min size
 * @attribute max: the max size
 * @attribute msg: the verification error tip
 */
public macro Size(attr: Tokens, input: Tokens): Tokens {
    parseConstraint(CCSize, attr, input)
    input
}

/**
 * Validate the Length of string
 *
 * @attribute min: the min size
 * @attribute max: the max size
 * @attribute msg: the verification error tip
 */
public macro Length(attr: Tokens, input: Tokens): Tokens {
    parseConstraint(CCLength, attr, input)
    input
}

/**
 * Validate string is Not empty
 *
 * @attribute msg: the verification error tip
 */
public macro NotEmpty(attr: Tokens, input: Tokens): Tokens {
    parseConstraint(CCNotEmpty, attr, input)
    input
}

/**
 * Validate string is Not blank
 *
 * @attribute msg: the verification error tip
 */
public macro NotBlank(attr: Tokens, input: Tokens): Tokens {
    parseConstraint(CCNotBlank, attr, input)
    input
}

/**
 * Validate string is Not empty
 *
 */
public macro NotEmpty(input: Tokens): Tokens {
    parseConstraint(CCNotEmpty, input)
    input
}

/**
 * Validate string is Not blank
 *
 */
public macro NotBlank(input: Tokens): Tokens {
    parseConstraint(CCNotBlank, input)
    input
}

/**
 * Validate the range of number like int, float etc.
 *
 * @attribute min: the min value
 * @attribute max: the max value
 * @attribute msg: the verification error tip
 */
public macro NumberRange(attr: Tokens, input: Tokens): Tokens {
    parseConstraint(CCNumberRange, attr, input)
    input
}

/**
 * Validate number or string match whether the regex pettern
 *
 * @attribute regex: the regex pettern
 * @attribute msg: the verification error tip
 */
public macro Pattern(attr: Tokens, input: Tokens): Tokens {
    parseConstraint(CCPattern, attr, input)
    input
}

/**
 * Validate the range of datetime
 *
 * @attribute before: before this time
 * @attribute after: after this time
 * @attribute msg: the verification error tip
 */
public macro DateTimeRange(attr: Tokens, input: Tokens): Tokens {
    parseConstraint(CCDatetimeRange, attr, input)
    input
}

/**
 * Validate string match whether is a chinese mobile phone number
 *
 * @attribute msg: the verification error tip
 */
public macro ChMobileNumber(attr: Tokens, input: Tokens): Tokens {
    parseConstraint(CCChMobilePhone, attr, input)
    input
}

/**
 * Validate string match whether is a chinese mobile phone number
 *
 */
public macro ChMobileNumber(input: Tokens): Tokens {
    parseConstraint(CCChMobilePhone, input)
    input
}

/**
 * Validate string match whether is a email
 *
 * @attribute msg: the verification error tip
 */
public macro Email(attr: Tokens, input: Tokens): Tokens {
    parseConstraint(CCEmail, attr, input)
    input
}

/**
 * Validate string match whether is a email
 *
 */
public macro Email(input: Tokens): Tokens {
    parseConstraint(CCEmail, input)
    input
}

/**
 * Validate string match whether is a IP V4
 *
 * @attribute msg: the verification error tip
 */
public macro IPV4(attr: Tokens, input: Tokens): Tokens {
    parseConstraint(CCIPV4, attr, input)
    input
}

/**
 * Validate string match whether is a IP V4
 *
 */
public macro IPV4(input: Tokens): Tokens {
    parseConstraint(CCIPV4, input)
    input
}
