/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

macro package cjoy.log.macros

import std.ast.Tokens
public import cjoy.log.{JoyLoggerFactory, JoyLogMDC}

/**
 * 创建日志记录器实例
 *
 * @attribute value 记录器名称，通常是类名或组件名
 */
public macro JoyCreateLogger(input: Tokens): Tokens {
    quote(protected let _JOY_LOGGER = JoyLoggerFactory.createLogger($input))
}

/**
 * 调试日志宏
 *
 * @attribute value 日志消息，可以包含格式化占位符
 */
public macro JoyLogDebug(input: Tokens): Tokens {
    quote(JoyLogMDC.put(("file", @sourceFile()),  ("line", @sourceLine()), ("pkg", @sourcePackage()))
        _JOY_LOGGER.debug($input))
}

/**
 * 信息日志宏
 *
 * @attribute value 日志消息，可以包含格式化占位符
 */
public macro JoyLogInfo(input: Tokens): Tokens {
    quote(JoyLogMDC.put(("file", @sourceFile()), ("line", @sourceLine()), ("pkg", @sourcePackage()))
        _JOY_LOGGER.info($input))
}

/**
 * 警告日志宏
 *
 * @attribute value 日志消息，可以包含格式化占位符
 */
public macro JoyLogWarn(input: Tokens): Tokens {
    quote(JoyLogMDC.put(("file", @sourceFile()), ("line", @sourceLine()), ("pkg", @sourcePackage()))
        _JOY_LOGGER.warn($input))
}

/**
 * 错误日志宏
 *
 * @attribute value 日志消息，可以包含格式化占位符
 */
public macro JoyLogError(input: Tokens): Tokens {
    quote(JoyLogMDC.put(("file", @sourceFile()), ("line", @sourceLine()), ("pkg", @sourcePackage()))
        _JOY_LOGGER.error($input))
}
