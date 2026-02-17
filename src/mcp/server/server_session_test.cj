/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.mcp.server

import std.collection.ArrayList
import std.io.ByteBuffer
import std.unittest.testmacro.*
import cjoy.mcp.api.*
import cjoy.jsonrpc.JSONRPCTool
import cjoy.jsonrpc.*

/**
 * 测试事件存储和检索功能
 */
@Test
public class McpServerSessionTestCaseSuit {
    /**
     * 测试事件存储功能
     */
    @TestCase
    public func testStoreEvent() {
        let transport = McpStreamableServerTransport(false)
        let session = DefaultMcpServerSession("test-session", transport, false, true)

        // 存储事件
        let data = JSONRPCTool.serialize(JSONRPCNotification(method: "test-event", params: "test-data"))
        let eventId = session.storeEvent(data)

        @Assert(eventId, "1")

        // 再次存储事件
        let data2 = JSONRPCTool.serialize(JSONRPCNotification(method: "test-event-2", params: "test-data-2"))
        let eventId2 = session.storeEvent(data2)

        @Assert(eventId2, "2")
    }

    /**
     * 测试事件检索功能
     */
    @TestCase
    public func testRetrieveEvents() {
        let transport = McpStreamableServerTransport(false)
        let session = DefaultMcpServerSession("test-session", transport, false, true)

        // 存储事件
        let data1 = JSONRPCTool.serialize(JSONRPCNotification(method: "test-event-1", params: "test-data-1"))
        let eventId1 = session.storeEvent(data1)

        let data2 = JSONRPCTool.serialize(JSONRPCNotification(method: "test-event-2", params: "test-data-2"))
        let eventId2 = session.storeEvent(data2)

        let data3 = JSONRPCTool.serialize(JSONRPCNotification(method: "test-event-3", params: "test-data-3"))
        let eventId3 = session.storeEvent(data3)

        // 检索事件
        let events = session.retrieveEvents("1")

        @Assert(events.size, 2)

        let (firstEventId, _) = events[0]
        @Assert(firstEventId, "2")

        let (secondEventId, _) = events[1]
        @Assert(secondEventId, "3")
    }

    /**
     * 测试事件清理功能
     */
    @TestCase
    public func testCleanUpEvents() {
        let transport = McpStreamableServerTransport(false)
        let session = DefaultMcpServerSession("test-session", transport, false, true)

        // 存储大量事件
        var i = 1
        while (i <= 1100) {
            let data = JSONRPCTool.serialize(JSONRPCNotification(method: "test-event-${i}", params: "test-data-${i}"))
            session.storeEvent(data)
            i += 1
        }

        @Assert(session.retrieveEvents("0").size, 1100)

        // 清理事件
        session.cleanUpEvents(maxEvents: 1000)

        let events = session.retrieveEvents("0")
        @Assert(events.size, 1000)
    }

    /**
     * 测试事件过期管理功能
     */
    @TestCase
    public func testEventExpiration() {
        let transport = McpStreamableServerTransport(false)
        let session = DefaultMcpServerSession("test-session", transport, false, true)

        // 存储事件
        var i = 1
        while (i <= 10) {
            let data = JSONRPCTool.serialize(JSONRPCNotification(method: "test-event-${i}", params: "test-data-${i}"))
            session.storeEvent(data)
            i += 1
        }

        // 清理事件
        session.cleanUpEvents(maxEvents: 5)

        let events = session.retrieveEvents("0")
        @Assert(events.size, 5)

        // 验证事件ID是否是从6开始的
        var j = 0
        while (j < 5) {
            let (eventId, _) = events[j]
            @Assert(eventId, "${j + 6}")
            j += 1
        }
    }
}
