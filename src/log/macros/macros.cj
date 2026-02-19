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
public import cjoy.log.{LogTool, JoyLoggerFactory}

/**
 * 调试日志宏（已过时，使用 JoyLogDebug 替代）
 */
@Deprecated["使用 JoyLogDebug 替代", since: "v0.90.0", strict: false]
public macro LogDebug(input: Tokens): Tokens {
    quote(LogTool.debug($input, @sourceFile(), @sourceLine()))
}

/**
 * 信息日志宏（已过时，使用 JoyLogInfo 替代）
 */
@Deprecated["使用 JoyLogInfo 替代", since: "v0.90.0", strict: false]
public macro LogInfo(input: Tokens): Tokens {
    quote(LogTool.info($input, @sourceFile(), @sourceLine()))
}

/**
 * 警告日志宏（已过时，使用 JoyLogWarn 替代）
 */
@Deprecated["使用 JoyLogWarn 替代", since: "v0.90.0", strict: false]
public macro LogWarn(input: Tokens): Tokens {
    quote(LogTool.warn($input, @sourceFile(), @sourceLine()))
}

/**
 * 错误日志宏（已过时，使用 JoyLogError 替代）
 */
@Deprecated["使用 JoyLogError 替代", since: "v0.90.0", strict: false]
public macro LogError(input: Tokens): Tokens {
    quote(LogTool.error($input, @sourceFile(), @sourceLine()))
}

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
    quote(_JOY_LOGGER.debug($input, ("%F", @sourceFile()), ("%L", @sourceLine()), ("%T", Thread.currentThread.name), ("%t", Thread.currentThread.id), ("%P", @sourcePackage())))
}

/**
 * 信息日志宏
 *
 * @attribute value 日志消息，可以包含格式化占位符
 */
public macro JoyLogInfo(input: Tokens): Tokens {
    quote(_JOY_LOGGER.info($input, ("%F", @sourceFile()), ("%L", @sourceLine()), ("%T", Thread.currentThread.name), ("%t", Thread.currentThread.id), ("%P", @sourcePackage())))
}

/**
 * 警告日志宏
 *
 * @attribute value 日志消息，可以包含格式化占位符
 */
public macro JoyLogWarn(input: Tokens): Tokens {
    quote(_JOY_LOGGER.warn($input, ("%F", @sourceFile()), ("%L", @sourceLine()), ("%T", Thread.currentThread.name), ("%t", Thread.currentThread.id), ("%P", @sourcePackage())))
}

/**
 * 错误日志宏
 *
 * @attribute value 日志消息，可以包含格式化占位符
 */
public macro JoyLogError(input: Tokens): Tokens {
    quote(_JOY_LOGGER.error($input, ("%F", @sourceFile()), ("%L", @sourceLine()), ("%T", Thread.currentThread.name), ("%t", Thread.currentThread.id), ("%P", @sourcePackage())))
}
