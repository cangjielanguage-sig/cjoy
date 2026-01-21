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
 * This macro applies to the struct of class pulish to a bean.
 * When a Bean can be injected by its base class and interface, the extends property needs to be specified
 *
 * @attribute name: the bean name
 * @attribute scope：the bean scope, value is singleton or prototype
 * @attribute extends: a array of the bean base class or interface type
 */
public macro Component(attr: Tokens, input: Tokens): Tokens {
    parseComponent(attr, input)
}

/*
 * This macro applies to the struct of class pulish to a bean.
 */
public macro Component(input: Tokens): Tokens {
    parseComponent(None, input)
}

/**
 * This macro applies to the parameters of the init function, inject beans according to the specified name
 *
 * @attribute name: the depend bean name
 */
public macro Autowired(attr: Tokens, input: Tokens): Tokens {
    parseAutowired(attr, input)
    input
}

/**
 * This macro applies to the parameters of the Init function
 */
public macro Autowired(input: Tokens): Tokens {
    parseAutowired(None, input)
    input
}

/*
 * This macro applies to the struct of class pulish to a bean used for publishing Restful interfaces,
 * with interface methods marked with @Get and other macros.
 * When a Bean can be injected by its base class and interface, the extends property needs to be specified
 *
 * @attribute name: the bean name
 * @attribute scope：the bean scope, value is singleton or prototype
 * @attribute extends: a array of the bean base class or interface type
 * @attribute path: the base path of resutful api
 */
public macro Controller(attr: Tokens, input: Tokens): Tokens {
    parseController(attr, input)
}

/*
 * This macro applies to the struct of class pulish to a bean used for publishing Restful interfaces,
 * with interface methods marked with @Get and other macros.
 */
public macro Controller(input: Tokens): Tokens {
    parseController(None, input)
}

/**
 * This macro applies to the field of struct of class for referring to config value,
 *
 * @attribute value: the express of config
 */
public macro Value(attr: Tokens, input: Tokens): Tokens {
    parseVaue(attr, input)
}
