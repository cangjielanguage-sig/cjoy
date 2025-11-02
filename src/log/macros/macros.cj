/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

macro package cjoy.log.macros

import std.ast.Tokens

public import cjoy.log.LogTool

public macro LogDebug(input: Tokens): Tokens {
    quote(LogTool.debug($input, @sourceFile(), @sourceLine()))
}

public macro LogInfo(input: Tokens): Tokens {
    quote(LogTool.info($input, @sourceFile(), @sourceLine()))
}

public macro LogWarn(input: Tokens): Tokens {
    quote(LogTool.warn($input, @sourceFile(), @sourceLine()))
}

public macro LogError(input: Tokens): Tokens {
    quote(LogTool.error($input, @sourceFile(), @sourceLine()))
}
