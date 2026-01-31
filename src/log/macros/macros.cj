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

@Deprecated["Use JoyLogDebug", since: "v0.90.0", strict: false]
public macro LogDebug(input: Tokens): Tokens {
    quote(LogTool.debug($input, @sourceFile(), @sourceLine()))
}

@Deprecated["Use JoyLogInfo", since: "v0.90.0", strict: false]
public macro LogInfo(input: Tokens): Tokens {
    quote(LogTool.info($input, @sourceFile(), @sourceLine()))
}

@Deprecated["Use JoyLogWarn", since: "v0.90.0", strict: false]
public macro LogWarn(input: Tokens): Tokens {
    quote(LogTool.warn($input, @sourceFile(), @sourceLine()))
}

@Deprecated["Use JoyLogError", since: "v0.90.0", strict: false]
public macro LogError(input: Tokens): Tokens {
    quote(LogTool.error($input, @sourceFile(), @sourceLine()))
}

public macro JoyCreateLogger(input: Tokens): Tokens {
    quote(protected let _JOY_LOGGER = JoyLoggerFactory.createLogger($input))
}

public macro JoyLogDebug(input: Tokens): Tokens {
    quote(_JOY_LOGGER.debug($input, ("%F", @sourceFile()), ("%L", @sourceLine()), ("%T", Thread.currentThread.name), ("%t", Thread.currentThread.id), ("%P", @sourcePackage())))
}

public macro JoyLogInfo(input: Tokens): Tokens {
    quote(_JOY_LOGGER.info($input, ("%F", @sourceFile()), ("%L", @sourceLine()), ("%T", Thread.currentThread.name), ("%t", Thread.currentThread.id), ("%P", @sourcePackage())))
}

public macro JoyLogWarn(input: Tokens): Tokens {
    quote(_JOY_LOGGER.warn($input, ("%F", @sourceFile()), ("%L", @sourceLine()), ("%T", Thread.currentThread.name), ("%t", Thread.currentThread.id), ("%P", @sourcePackage())))
}

public macro JoyLogError(input: Tokens): Tokens {
    quote(_JOY_LOGGER.error($input, ("%F", @sourceFile()), ("%L", @sourceLine()), ("%T", Thread.currentThread.name), ("%t", Thread.currentThread.id), ("%P", @sourcePackage())))
}
