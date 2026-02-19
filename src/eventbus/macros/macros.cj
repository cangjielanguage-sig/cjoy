/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

macro package cjoy.eventbus.macros

import std.ast.Tokens

/**
 * 订阅事件
 *
 * @attribute name 订阅者名称
 * @attribute pattern 订阅事件名称模式
 * @attribute priority 优先级，默认为 0
 */
public macro SubscribeEvent(attr: Tokens, input: Tokens): Tokens {
    input + parseFunc("SubscribeEvent", attr, input)
}
