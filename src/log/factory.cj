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

import std.collection.concurrent.ConcurrentHashMap
import stdx.log.{Logger, LogValue}
import cjlog.{getLogger as cjGetLogger, MDC}

/**
 * 用于创建日志记录器实例的函数类型。
 *
 * 接受日志记录器名称并返回 Logger 实例。
 */
public type LoggerCreatorFunc = (name: String) -> Logger

/**
 * 外部日志框架MDC Hook
 */
public type LoggerMDCHookFunc = (name: String, value: LogValue) -> Unit

/**
 * 外部日志框架的日志记录器工厂适配器。
 *
 * 允许注册自定义日志记录器创建器以与第三方日志框架集成。
 * 如果未注册创建器，则使用默认的 ConsoleLogger。
 */
public class JoyLoggerFactory {
    private static var _creator: ?LoggerCreatorFunc = None
    private static let _loggers: ConcurrentHashMap<String, Logger> = ConcurrentHashMap()

    /**
     * 使用已注册的创建器或默认 ConsoleLogger 创建日志记录器。
     *
     * @param name 日志记录器名称
     * @return 日志记录器实例
     */
    public static func createLogger(name: String): Logger {
        // 尝试从缓存中获取
        if (let Some(logger) <- _loggers.get(name)) {
            return logger
        }

        // 缓存中不存在，创建新的 Logger
        let logger = if (let Some(c) <- _creator) {
            c(name)
        } else {
            // 默认使用cjlog框架
            cjGetLogger(name)
        }

        // 存入缓存
        _loggers.add(name, logger)
        return logger
    }

    /**
     * 根据名称获取已创建的日志记录器实例。
     *
     * @param name 日志记录器名称
     * @return 日志记录器实例，如果未找到则返回 None
     */
    public static func getLogger(name: String): ?Logger {
        _loggers.get(name)
    }

    /**
     * 注册外部日志框架创建器。
     *
     * 调用此方法与您首选的日志框架集成。
     *
     * @param fn 接受名称并返回 Logger 实例的日志记录器创建器函数
     */
    public static func registerCreator(fn: LoggerCreatorFunc): Unit {
        _creator = fn
    }
}

/**
 * MDC（Mapped Diagnostic Context，映射调试上下文）工具类。
 *
 * <p>{@code MDC} 提供了一种在多线程环境中追踪上下文信息的机制。
 * 它为每个线程维护一个独立的键值对映射，可以在日志输出中包含这些上下文信息。</p>
 *
 */
public class JoyLogMDC {
    // 默认使用cjlog框架的MDC
    private static var _HOOK: ?LoggerMDCHookFunc = {name, value => MDC.put(name, value)}

    /**
     * 在当前线程的 MDC 中设置一个键值对。
     *
     * <p>如果当前线程尚未初始化 MDC 存储，会自动创建。</p>
     *
     * @param name 键名
     * @param value 键值
     */
    public static func put(mdcs: Array<(String, LogValue)>): Unit {
        for ((name, value) in mdcs) {
            _HOOK?(name, value)
        }
    }

    /**
     * 注册外部日志框架MDC Hook。
     *
     * 调用此方法与您首选的日志框架集成。
     *
     * @param fn 外部日志框架MDC Hook 函数
     */
    public static func registerCreator(fn: LoggerMDCHookFunc): Unit {
        _HOOK = fn
    }
}
