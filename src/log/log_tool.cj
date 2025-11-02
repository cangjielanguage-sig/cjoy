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
    private static var _logger: Logger = SimpleLogger(getStdOut())

    /**
     * you can set the logger in program begin
     */
    public mut static prop logger: Logger {
        get() {
            _logger
        }
        set(value) {
            // non thread safe
            _logger = value
        }
    }

    public static func enableDebugLog(): Unit {
        logger.level = LogLevel.DEBUG
    }

    public static func debug(msg: String): Unit {
        logger.debug("[${thread()}] ${msg}")
    }

    public static func debug(msg: String, file: String, line: Int): Unit {
        logger.debug("[${thread()}][${file}:${line}] ${msg}")
    }

    public static func info(msg: String): Unit {
        logger.info("[${thread()}] ${msg}")
    }

    public static func info(msg: String, file: String, line: Int): Unit {
        logger.info("[${thread()}][${file}:${line}] ${msg}")
    }

    public static func error(msg: String): Unit {
        logger.error("[${thread()}] ${msg}")
    }

    public static func error(msg: String, file: String, line: Int): Unit {
        logger.error("[${thread()}][${file}:${line}] ${msg}")
    }

    public static func warn(msg: String): Unit {
        logger.warn("[${thread()}] ${msg}")
    }

    public static func warn(msg: String, file: String, line: Int): Unit {
        logger.warn("[${thread()}][${file}:${line}] ${msg}")
    }

    private static func thread(): String {
        let thread = Thread.currentThread
        if (thread.name != "") {
            thread.name
        } else {
            "${thread.id}"
        }
    }
}
