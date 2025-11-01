/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.httpx

import std.deriving.Derive
import std.convert.Parsable
import cjoy.log.*

@Derive[ToString]
public struct JoySSEvent {
    var _id: String = ""
    var _event: String = ""
    var _data: String = ""
    var _retry: UInt = 0
    var _comment: String = ""

    public prop id: String {
        get() {
            _id
        }
    }

    public prop event: String {
        get() {
            _event
        }
    }

    public prop data: String {
        get() {
            _data
        }
    }

    public prop retry: UInt {
        get() {
            _retry
        }
    }

    public prop comment: String {
        get() {
            _comment
        }
    }
}

public class JoySSEventStream <: Iterator<JoySSEvent> {
    JoySSEventStream(private let httpStream: JoyHttpStream) {}

    /**
     * @throws IllegalArgumentException
     * @throws IllegalStateException
     */
    public func next(): Option<JoySSEvent> {
        var data = JoySSEvent()
        while (true) {
            if (let Some(line) <- this.httpStream.next()) {
                let text = line.trimAscii()
                match {
                    case text.startsWith(":") => data._comment = text.trimStart(":").trimAscii()
                    case text.startsWith("data:") => data._data = text.trimStart("data:").trimAscii()
                    case text.startsWith("id:") => data._id = text.trimStart("id:").trimAscii()
                    case text.startsWith("event:") => data._event = text.trimStart("event:").trimAscii()
                    case text.startsWith("retry:") => data._retry = UInt
                        .tryParse(text.trimStart("retry:").trimAscii())
                        .getOrDefault({=> 0})
                    case text.isEmpty() =>
                        @LogDebug("SSE stream event: ${data}")
                        return data
                    case _ => throw IllegalArgumentException("invalid SSE message ${text}")
                }
            } else {
                @LogDebug("SSE stream finished")
                return None
            }
        }

        throw IllegalStateException("Unreachable")
    }

    public func close(): Unit {
        this.httpStream.close()
    }
}
