/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

macro package cjoy.ioc.macros

import std.ast.Tokens

/*
 * 此宏适用于要发布为 Bean 的类或结构体。
 * 当一个 Bean 可以通过其基类和接口注入时，需要指定 extends 属性
 *
 * @attribute name Bean 名称
 * @attribute scope Bean 作用域，值为 singleton 或 prototype
 * @attribute extends Bean 基类或接口类型的数组
 */
public macro Component(attr: Tokens, input: Tokens): Tokens {
    parseComponent(attr, input)
}

/*
 * 此宏适用于要发布为 Bean 的类或结构体。
 */
public macro Component(input: Tokens): Tokens {
    parseComponent(None, input)
}

/**
 * 此宏适用于构造函数的参数，根据指定名称注入 Bean
 *
 * @attribute name 依赖的 Bean 名称
 */
public macro Autowired(attr: Tokens, input: Tokens): Tokens {
    parseAutowired(attr, input)
    input
}

/**
 * 此宏适用于构造函数的参数
 */
public macro Autowired(input: Tokens): Tokens {
    parseAutowired(None, input)
    input
}

/*
 * 此宏适用于要发布为用于发布 Restful 接口的 Bean 的类或结构体，
 * 接口方法使用 @Get 等宏标记。
 * 当一个 Bean 可以通过其基类和接口注入时，需要指定 extends 属性
 *
 * @attribute name Bean 名称
 * @attribute scope Bean 作用域，值为 singleton 或 prototype
 * @attribute extends Bean 基类或接口类型的数组
 * @attribute path Restful API 的基路径
 */
public macro Controller(attr: Tokens, input: Tokens): Tokens {
    parseController(attr, input)
}

/*
 * 此宏适用于要发布为用于发布 Restful 接口的 Bean 的类或结构体，
 * 接口方法使用 @Get 等宏标记。
 */
public macro Controller(input: Tokens): Tokens {
    parseController(None, input)
}

/**
 * 此宏适用于类或结构体的字段，用于引用配置值，
 *
 * @attribute value 配置表达式
 */
public macro Value(attr: Tokens, input: Tokens): Tokens {
    parseValue(attr, input)
}
