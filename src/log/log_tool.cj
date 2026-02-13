/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
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

/**
 * Legacy logging tool class.
 *
 * @deprecated Use JoyLoggerFactory instead since v0.90.0.
 */
@Deprecated["Use JoyLoggerFactory", since: "v0.90.0", strict: false]
public class LogTool {
    private static var _logger: Logger = SimpleLogger(getStdOut())

    /**
     * Get or set the logger instance.
     *
     * Set your custom logger at program start to customize logging behavior.
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

    /**
     * Enable debug level logging.
     *
     * Sets the logger level to DEBUG, allowing all log messages to be output.
     */
    public static func enableDebugLog(): Unit {
        logger.level = LogLevel.DEBUG
    }

    /**
     * Log a debug message.
     *
     * @param msg the message to log
     */
    public static func debug(msg: String): Unit {
        logger.debug("[${thread()}] ${msg}")
    }

    /**
     * Log a debug message with file and line information.
     *
     * @param msg the message to log
     * @param file the source file name
     * @param line the line number in the source file
     */
    public static func debug(msg: String, file: String, line: Int): Unit {
        logger.debug("[${thread()}][${file}:${line}] ${msg}")
    }

    /**
     * Log an info message.
     *
     * @param msg the message to log
     */
    public static func info(msg: String): Unit {
        logger.info("[${thread()}] ${msg}")
    }

    /**
     * Log an info message with file and line information.
     *
     * @param msg the message to log
     * @param file the source file name
     * @param line the line number in the source file
     */
    public static func info(msg: String, file: String, line: Int): Unit {
        logger.info("[${thread()}][${file}:${line}] ${msg}")
    }

    /**
     * Log an error message.
     *
     * @param msg the message to log
     */
    public static func error(msg: String): Unit {
        logger.error("[${thread()}] ${msg}")
    }

    /**
     * Log an error message with file and line information.
     *
     * @param msg the message to log
     * @param file the source file name
     * @param line the line number in the source file
     */
    public static func error(msg: String, file: String, line: Int): Unit {
        logger.error("[${thread()}][${file}:${line}] ${msg}")
    }

    /**
     * Log a warning message.
     *
     * @param msg the message to log
     */
    public static func warn(msg: String): Unit {
        logger.warn("[${thread()}] ${msg}")
    }

    /**
     * Log a warning message with file and line information.
     *
     * @param msg the message to log
     * @param file the source file name
     * @param line the line number in the source file
     */
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
