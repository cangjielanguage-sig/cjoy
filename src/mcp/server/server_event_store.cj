/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the MCP PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.mcp.server

import std.collection.concurrent.ConcurrentHashMap
import std.collection.ArrayList
import std.io.ByteBuffer
import std.time.{DateTime}
import cjoy.log.macros.*
import cjoy.mcp.api.EventStore

/**
 * MCP 服务器的内存实现 EventStore
 *
 * 提供简单的内存事件存储，用于测试和开发目的。
 * 事件存储在内存中，服务器重启时会丢失。
 */
public class InMemoryEventStore <: EventStore {
    /**
     * 事件存储结构：sessionId -> streamId -> (timestamp, data)
     */
    private let _events: ConcurrentHashMap<String, ConcurrentHashMap<String, ArrayList<(DateTime, ByteBuffer)>>> = ConcurrentHashMap()

    /**
     * 事件过期时间（毫秒），默认 24 小时
     */
    private let _expirationMs: Int64

    /**
     * 定期检查过期事件的间隔（毫秒），默认 1 小时
     */
    private let _gcIntervalMs: Int64

    /**
     * 标志位，指示 GC 任务是否正在运行
     */
    private var _gcRunning: Bool = false

    /**
     * 初始化 InMemoryEventStore
     *
     * @param expirationMs 事件过期时间（毫秒），默认 24 小时
     * @param gcIntervalMs GC 检查间隔（毫秒），默认 1 小时
     */
    public init(expirationMs!: Int64 = 24 * 60 * 60 * 1000, gcIntervalMs!: Int64 = 60 * 60 * 1000) {
        _expirationMs = expirationMs
        _gcIntervalMs = gcIntervalMs
        // 启动定期 GC 任务
        startGcTask()
    }

    /**
     * 启动定期 GC 任务
     */
    private func startGcTask(): Unit {
        if (_gcIntervalMs <= 0) {
            @JoyLogInfo("[EventStore] GC interval is <= 0, skipping GC task")
            return
        }
        if (_gcRunning) {
            @JoyLogInfo("[EventStore] GC task already running")
            return
        }
        _gcRunning = true
        spawn {
            while (_gcRunning) {
                sleep(_gcIntervalMs * Duration.millisecond)
                gc()
            }
        }
        @JoyLogInfo("[EventStore] GC task started, interval: ${_gcIntervalMs}ms")
    }

    /**
     * 停止 GC 任务
     */
    public func stopGcTask(): Unit {
        _gcRunning = false
        @JoyLogInfo("[EventStore] GC task stopped")
    }

    /**
     * 执行事件过期检查和清理
     */
    public func gc(): Unit {
        let currentTime = DateTime.now()
        let expiredTime = currentTime - Duration.millisecond * _expirationMs

        @JoyLogDebug("[EventStore] Running GC, current time: ${currentTime}, expired before: ${expiredTime}")

        let sessionIter = _events.iterator()
        while (let Some((sessionId, streamEventsMap)) <- sessionIter.next()) {
            let streamIter = streamEventsMap.iterator()
            while (let Some((streamId, events)) <- streamIter.next()) {
                // 收集过期事件的索引
                var expiredIndices = ArrayList<Int>()
                var i = 0
                while (i < events.size) {
                    let (timestamp, _) = events[i]
                    if (timestamp < expiredTime) {
                        expiredIndices.add(i)
                    }
                    i += 1
                }

                // 移除过期事件
                if (!expiredIndices.isEmpty()) {
                    @JoyLogInfo("[EventStore] Removing ${expiredIndices.size} expired events from session: ${sessionId}, stream: ${streamId}")
                    var j = expiredIndices.size - 1
                    while (j >= 0) {
                        events.remove(at: expiredIndices[j])
                        j -= 1
                    }
                }
            }
        }
    }

    public func open(sessionId: String, streamId: String): Unit {
        match (_events.get(sessionId)) {
            case None =>
                let newSessionEvents = ConcurrentHashMap<String, ArrayList<(DateTime, ByteBuffer)>>()
                let newStreamEvents = ArrayList<(DateTime, ByteBuffer)>()
                newSessionEvents.add(streamId, newStreamEvents)
                _events.add(sessionId, newSessionEvents)
            case Some(sessionEvents) => match (sessionEvents.get(streamId)) {
                case None =>
                    let newStreamEvents = ArrayList<(DateTime, ByteBuffer)>()
                    sessionEvents.add(streamId, newStreamEvents)
                case Some(_) =>
                    // 流已存在，不做处理
                    ()
            }
        }
    }

    public func append(sessionId: String, streamId: String, data: ByteBuffer): Unit {
        let timestamp = DateTime.now()
        match (_events.get(sessionId)) {
            case None =>
                let newSessionEvents = ConcurrentHashMap<String, ArrayList<(DateTime, ByteBuffer)>>()
                let newStreamEvents = ArrayList<(DateTime, ByteBuffer)>()
                newStreamEvents.add((timestamp, data))
                newSessionEvents.add(streamId, newStreamEvents)
                _events.add(sessionId, newSessionEvents)
            case Some(sessionEvents) => match (sessionEvents.get(streamId)) {
                case None =>
                    let newStreamEvents = ArrayList<(DateTime, ByteBuffer)>()
                    newStreamEvents.add((timestamp, data))
                    sessionEvents.add(streamId, newStreamEvents)
                case Some(streamEvents) => streamEvents.add((timestamp, data))
            }
        }
    }

    public func after(sessionId: String, streamId: String, lastIndex: Int64): Iterator<(Int64, ByteBuffer)> {
        match (_events.get(sessionId)) {
            case None => ArrayList<(Int64, ByteBuffer)>().iterator()
            case Some(sessionEvents) => match (sessionEvents.get(streamId)) {
                case None => ArrayList<(Int64, ByteBuffer)>().iterator()
                case Some(streamEvents) =>
                    var result = ArrayList<(Int64, ByteBuffer)>()

                    var i = lastIndex + 1
                    while (i < streamEvents.size) {
                        let (_, data) = streamEvents[i]
                        result.add((i, data))
                        i += 1
                    }

                    result.iterator()
            }
        }
    }

    /**
     * 会话关闭时调用，用于清理资源
     *
     * @param sessionId 唯一会话标识符
     */
    public func sessionClosed(sessionId: String): Unit {
        _events.remove(sessionId)
    }

    /**
     * 获取特定会话和流存储的事件数量
     *
     * @param sessionId 唯一会话标识符
     * @param streamId 唯一流标识符
     * @return 存储的事件数量
     */
    public func getEventCount(sessionId: String, streamId: String): Int64 {
        match (_events.get(sessionId)) {
            case None => 0
            case Some(sessionEvents) => match (sessionEvents.get(streamId)) {
                case None => 0
                case Some(streamEvents) => streamEvents.size
            }
        }
    }

    /**
     * 清除所有存储的事件
     */
    public func clear(): Unit {
        let iter = _events.iterator()
        while (let Some(it) <- iter.next()) {
            _events.remove(it[0])
        }
    }
}
