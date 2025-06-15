/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.log

import stdx.log.{LogLevel, Logger}
import stdx.logger.SimpleLogger
import std.env.getStdOut

public class LogTool {
    private static var _logger: ?Logger = None

    public static mut prop logger: Logger {
        get() {
            if (_logger.isNone()) {
                _logger = Some(SimpleLogger(getStdOut()))
            }
            return _logger.getOrThrow()
        }
        set(value) {
            _logger = Some(value)
        }
    }

    public static func debug(msg: String): Unit {
        logger.debug(msg)
    }

    public static func info(msg: String): Unit {
        logger.info(msg)
    }

    public static func error(msg: String): Unit {
        logger.error(msg)
    }
}
