/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

macro package cjoy.bind.macros

import std.ast.Tokens

/**
 * apply to class or structure to bind mapping of parameters
 */
public macro Bind(input: Tokens): Tokens {
    BindClassInfo.parse("Bind", input)
}

/**
 * set bind info of this member class or structure
 *
 * @attribute name: the field mapping name
 * @attribute default: the default value when parameter does not exist
 * @attribute timeformat: the format for Datetime field
 */
public macro BindField(attr: Tokens, input: Tokens): Tokens {
    BindFieldInfo.parse(attr, input)
    input
}
