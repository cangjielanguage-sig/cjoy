/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.mcp.server

import std.collection.concurrent.ConcurrentHashMap
import std.sync.{AtomicUInt64, SyncCounter}
import cjoy.framework.{JoyContext, JoySseEmitter, JoyServerEventBuilder}
import cjoy.utils.randStr
import cjoy.mcp.schema.*
import cjoy.mcp.common.*

public class McpSseSererTransport {
    private let _sessions: ConcurrentHashMap<String, McpServerSession> = ConcurrentHashMap()
    private var _messageEndpoint: String = ""

    public func handleSseRequest(ctx: JoyContext): Unit {
        let emitter = ctx.eventEmitter()
        // TODO
        let sessionId = randStr(32)
        let counter = SyncCounter(1)

        sendEvent(emitter, McpConsts.EVENT_ENDPOINT, "${_messageEndpoint}?sessionId=${sessionId}")
        // waiter end
        counter.waitUntilZero()
        emitter.end()
    }

    private func sendEvent(emitter: JoySseEmitter, eventType: String, data: String) {
        emitter.sendEvent(JoyServerEventBuilder().event(eventType).data(data))
    }
}