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

import std.env.getStdOut
import std.io.OutputStream
import std.collection.ArrayList
import std.sync.AtomicBool
import std.collection.concurrent.ConcurrentHashMap
import stdx.log.{Logger, LogLevel, Attr, LogRecord}

/**
 * 用于创建日志记录器实例的函数类型。
 *
 * 接受日志记录器名称并返回 Logger 实例。
 */
public type LoggerCreatorFunc = (name: String) -> Logger

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
            ConsoleLogger()
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
 * 默认控制台日志记录器实现。
 *
 * 以格式化方式将日志消息输出到 stdout，
 * 包含时间戳、日志级别、线程名称和文件/行信息。
 */
class ConsoleLogger <: Logger {
    let _attrs = ArrayList<Attr>()
    var _level = LogLevel.INFO
    let _output: OutputStream
    let _closed = AtomicBool(false)

    /**
     * 创建以 stdout 为输出的控制台日志记录器。
     */
    public init() {
        _output = getStdOut()
    }

    /**
     * 获取或设置日志级别。
     *
     * 低于此级别的消息将不会被记录。
     */
    public mut prop level: LogLevel {
        get() {
            _level
        }
        set(v) {
            _level = v
        }
    }

    /**
     * 使用附加属性创建新的日志记录器。
     *
     * @param attrs 要添加的属性数组
     * @return 带有属性的新日志记录器实例，如果 attrs 为空则返回此实例
     */
    public func withAttrs(attrs: Array<Attr>): Logger {
        if (attrs.size > 0) {
            let nl = this.clone()
            nl._attrs.add(all: attrs)
            return nl
        }
        return this
    }

    /**
     * 检查日志记录器是否已关闭。
     *
     * @return 如果日志记录器已关闭返回 true
     */
    public func isClosed(): Bool {
        _closed.load()
    }

    /**
     * 关闭日志记录器并刷新输出。
     */
    public func close(): Unit {
        if (isClosed()) {
            return
        }
        if (_closed.compareAndSwap(false, true)) {
            _output.flush()
        }
    }

    /**
     * 记录日志记录。
     *
     * 将日志记录格式化并写入输出流。
     * 格式：timestamp level [thread][package/file:line] message
     *
     * @param record 要写入的日志记录
     */
    public func log(record: LogRecord): Unit {
        if (record.level < _level) {
            return
        }

        let attrs = record.attrs.toArray()

        _output.write(record.time.toString().toArray())
        _output.write([b' '])
        _output.write(record.level.toString().toArray())
        _output.write([b' '])
        _output.write(thread().toArray())
        _output.write([b' '])
        _output.write([b'['])
        _output.write((getAttr(attrs, "%P") ?? "").toString().toArray())
        _output.write([b'/'])
        _output.write((getAttr(attrs, "%F") ?? "").toString().toArray())
        _output.write([b':'])
        _output.write((getAttr(attrs, "%L") ?? "").toString().toArray())
        _output.write([b']'])
        _output.write([b' '])
        _output.write(record.message.toString().toArray())
        if (attrs.size > 5) {
            for (a in attrs) {
                if (!a[0].startsWith("%")) {
                    _output.write([b' '])
                    _output.write(a[0].toString().toArray())
                    _output.write([b'='].toArray())
                    _output.write((a[1] as ToString).toString().toArray())
                }
            }
        }
        _output.write([b'\n'])
        _output.flush()
    }

    func getAttr(attrs: Array<Attr>, name: String): ?ToString {
        for (a in attrs) {
            if (a[0] == name) {
                return a[1] as ToString
            }
        }
        None
    }

    func clone(): ConsoleLogger {
        let cl = ConsoleLogger()
        cl._level = this._level
        cl._attrs.add(all: this._attrs)
        return cl
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
