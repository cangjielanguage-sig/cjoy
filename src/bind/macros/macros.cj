/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
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
 * 应用于类或结构体，用于绑定参数映射
 */
public macro Bind(input: Tokens): Tokens {
    BindClassInfo.parse("Bind", input)
}

/**
 * 设置类或结构体成员的绑定信息
 *
 * @attribute name 字段映射名称
 * @attribute default 参数不存在时的默认值
 * @attribute timeformat 日期时间字段的格式
 */
public macro BindField(attr: Tokens, input: Tokens): Tokens {
    BindFieldInfo.parse(attr, input)
    input
}
