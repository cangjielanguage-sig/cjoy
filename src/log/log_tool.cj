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
 * 遗留的日志工具类。
 *
 * @deprecated 从 v0.90.0 版本开始，请使用 JoyLoggerFactory 替代。
 */
@Deprecated["Use JoyLoggerFactory", since: "v0.90.0", strict: false]
public class LogTool {
    private static var _logger: Logger = SimpleLogger(getStdOut())

    /**
     * 获取或设置日志记录器实例。
     *
     * 在程序启动时设置您的自定义日志记录器，以自定义日志记录行为。
     */
    public mut static prop logger: Logger {
        get() {
            _logger
        }
        set(value) {
            // 非线程安全
            _logger = value
        }
    }

    /**
     * 启用调试级别日志记录。
     *
     * 将日志记录器级别设置为 DEBUG，允许输出所有日志消息。
     */
    public static func enableDebugLog(): Unit {
        logger.level = LogLevel.DEBUG
    }

    /**
     * 记录调试消息。
     *
     * @param msg 要记录的消息
     */
    public static func debug(msg: String): Unit {
        logger.debug("[${thread()}] ${msg}")
    }

    /**
     * 记录包含文件和行号信息的调试消息。
     *
     * @param msg 要记录的消息
     * @param file 源文件名
     * @param line 源文件中的行号
     */
    public static func debug(msg: String, file: String, line: Int): Unit {
        logger.debug("[${thread()}][${file}:${line}] ${msg}")
    }

    /**
     * 记录信息消息。
     *
     * @param msg 要记录的消息
     */
    public static func info(msg: String): Unit {
        logger.info("[${thread()}] ${msg}")
    }

    /**
     * 记录包含文件和行号信息的信息消息。
     *
     * @param msg 要记录的消息
     * @param file 源文件名
     * @param line 源文件中的行号
     */
    public static func info(msg: String, file: String, line: Int): Unit {
        logger.info("[${thread()}][${file}:${line}] ${msg}")
    }

    /**
     * 记录错误消息。
     *
     * @param msg 要记录的消息
     */
    public static func error(msg: String): Unit {
        logger.error("[${thread()}] ${msg}")
    }

    /**
     * 记录包含文件和行号信息的错误消息。
     *
     * @param msg 要记录的消息
     * @param file 源文件名
     * @param line 源文件中的行号
     */
    public static func error(msg: String, file: String, line: Int): Unit {
        logger.error("[${thread()}][${file}:${line}] ${msg}")
    }

    /**
     * 记录警告消息。
     *
     * @param msg 要记录的消息
     */
    public static func warn(msg: String): Unit {
        logger.warn("[${thread()}] ${msg}")
    }

    /**
     * 记录包含文件和行号信息的警告消息。
     *
     * @param msg 要记录的消息
     * @param file 源文件名
     * @param line 源文件中的行号
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
