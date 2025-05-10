/*
 * Copyright (c) lanlingx 2025-present. All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

macro package cjoy.validation

import std.ast.Tokens
import cjoy.validation.generate.{parseConstraint, parseNestedValid, parseValidated, ConstraintCatgory, ValidClassInfo}
public import cjoy.validation.api.*

/**
 * for class & struct
 */
public macro Valid(input: Tokens): Tokens {
    input + ValidClassInfo.parse(input)
}

/**
 * for field nested valid
 */
public macro NestedValid(input: Tokens): Tokens {
    parseNestedValid(input)
    input
}

/**
 * for method
 */
public macro Validated(input: Tokens): Tokens {
    parseValidated(input)
}

public macro Size(attr: Tokens, input: Tokens): Tokens {
    parseConstraint(ConstraintCatgory.C_SIZE, attr, input)
    input
}

public macro Length(attr: Tokens, input: Tokens): Tokens {
    parseConstraint(ConstraintCatgory.C_LENGTH, attr, input)
    input
}

public macro NotEmpty(attr: Tokens, input: Tokens): Tokens {
    parseConstraint(ConstraintCatgory.C_NOT_EMTPY, attr, input)
    input
}

public macro NotBlank(attr: Tokens, input: Tokens): Tokens {
    parseConstraint(ConstraintCatgory.C_NOT_BLANK, attr, input)
    input
}

public macro NotEmpty(input: Tokens): Tokens {
    parseConstraint(ConstraintCatgory.C_NOT_EMTPY, input)
    input
}

public macro NotBlank(input: Tokens): Tokens {
    parseConstraint(ConstraintCatgory.C_NOT_BLANK, input)
    input
}

public macro NumberRange(attr: Tokens, input: Tokens): Tokens {
    parseConstraint(ConstraintCatgory.C_NUBMER_RANGE, attr, input)
    input
}

public macro Patten(attr: Tokens, input: Tokens): Tokens {
    parseConstraint(ConstraintCatgory.C_PATTERN, attr, input)
    input
}

public macro DateTimeRange(attr: Tokens, input: Tokens): Tokens {
    parseConstraint(ConstraintCatgory.C_DATETIME_RANGE, attr, input)
    input
}