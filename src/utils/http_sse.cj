/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.utils

import std.deriving.Derive
import cjoy.log.LogTool

// modified from CangjieMagic

@Derive[ToString]
protected struct SSEvent {
    SSEvent(
        public let event: String,
        public let data: String
    ) {}
}

protected class SSEventStream <: Iterator<SSEvent> {
    SSEventStream(private let httpStream: HttpStream) {}

    private func read(typ: String): Option<String> {
        while (true) {
            // Receive the pair of event and data
            if (let Some(line) <- this.httpStream.next()) {
                if (line.trimAscii().isEmpty() || line.startsWith(":")) {
                    continue
                }
                if (!line.startsWith(typ)) {
                    throw Exception("Invalid sse event: `${line}`")
                }
                return line.removePrefix(typ).trimAscii()
            } else {
                LogTool.debug("SSE stream finished")
                return None
            }
        }
        throw UnsupportedException("Unreachable")
    }

    public override func next(): Option<SSEvent> {
        while (true) {
            // Receive the pair of event and data
            let event = if (let Some(x) <- this.read("event:")) {
                x
            } else {
                return None
            }
            LogTool.debug("SSE stream event: ${event}")
            let data = if (let Some(x) <- this.read("data:")) {
                x
            } else {
                return None
            }
            LogTool.debug("SSE stream event: ${data}")
            return SSEvent(event, data)
        }
        throw UnsupportedException("Unreachable")
    }

    public func close(): Unit {
        this.httpStream.close()
    }
}
