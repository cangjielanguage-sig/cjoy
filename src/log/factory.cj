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
import stdx.log.{Logger, LogLevel, Attr, LogRecord}

public type LoggerCreatorFunc = (name: String) -> Logger

/**
 * the logger facotry adapter for other logger framework
 */
public class JoyLoggerFactory {
    private static var _creator: ?LoggerCreatorFunc = None

    /**
     * create a logger using creator or defualt ConsoleLogger
     *
     * @param name: the logger name
     * @return: a logger instance
     */
    public static func createLogger(name: String): Logger {
        if (let Some(c) <- _creator) {
            c(name)
        } else {
            ConsoleLogger()
        }
    }

    /**
     * register other logger framework
     *
     * @param fn: the other logger framework creator
     */
    public static func registerCreator(fn: LoggerCreatorFunc): Unit {
        _creator = fn
    }
}

class ConsoleLogger <: Logger {
    let _attrs = ArrayList<Attr>()
    var _level = LogLevel.INFO
    let _output: OutputStream
    let _closed = AtomicBool(false)

    public init() {
        _output = getStdOut()
    }

    public mut prop level: LogLevel {
        get() {
            _level
        }
        set(v) {
            _level = v
        }
    }

    public func withAttrs(attrs: Array<Attr>): Logger {
        if (attrs.size > 0) {
            let nl = this.clone()
            nl._attrs.add(all: attrs)
            return nl
        }
        return this
    }

    public func isClosed(): Bool {
        _closed.load()
    }

    public func close(): Unit {
        if (isClosed()) {
            return
        }
        if (_closed.compareAndSwap(false, true)) {
            _output.flush()
        }
    }

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
