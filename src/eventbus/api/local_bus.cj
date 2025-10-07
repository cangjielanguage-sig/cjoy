/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.eventbus.api

import std.collection.{ArrayList}
import std.collection.concurrent.{ArrayBlockingQueue, ConcurrentHashMap}
import std.sync.{SyncCounter, AtomicBool}
import cjoy.framework.DEFAULT_SERVICE_CONTAINER
import cjoy.context.{Context, MapContext}

public class LocalEventBus <: EventBus {
    public static let INSTANCE: EventBus = LocalEventBus()

    private let _queueSize: Int
    private let _consumerNum: Int

    private let _queue: ArrayBlockingQueue<Event>
    private let _subcribers: ConcurrentHashMap<String, EventSubscriberGroup> = ConcurrentHashMap()

    private let _consumers: ArrayList<Future<Unit>> = ArrayList()
    private let _waitCounter: SyncCounter
    private let _inited: AtomicBool = AtomicBool(false)

    public init(
        queueSize!: Int = 500,
        consumerNum!: Int = 20
    ) {
        _queueSize = queueSize
        _consumerNum = consumerNum
        _queue = ArrayBlockingQueue<Event>(_queueSize)
        _waitCounter = SyncCounter(consumerNum)
    }

    private func initConsumers(): Unit {
        if (_inited.compareAndSwap(false, true)) {
            for (_ in 0.._consumerNum) {
                let future = spawn {
                    while (!Thread.currentThread.hasPendingCancellation) {
                        if (let Some(evt) <- _queue.remove(Duration.millisecond)) {
                            fireOneEvent(MapContext(), evt)
                        }
                    }
                    _waitCounter.dec()
                }
                _consumers.add(future)
            }
        }
    }

    public func onEvent(pattern: String, name: String, subcriber: EventSubscriber, priority: Array<Int>): Unit {
        checkPattern(pattern, name)
        let pr = if (priority.size == 0) {
            EventConsts.PRIORITY_NORMAL
        } else {
            priority[0]
        }

        let item = EventSubscriberItem(name, subcriber, pr)
        let existed = _subcribers.addIfAbsent(pattern, EventSubscriberGroup.of(item))
        if (let Some(group) <- existed) {
            group.add(item)
        }
    }

    public func removeSubscriber(pattern: String, name: String): Unit {
        if (let Some(sg) <- _subcribers.get(pattern)) {
            sg.del(name)
        }
    }

    public func fireEventAsync(_: Context, evts: Array<Event>): Unit {
        initConsumers()
        for (e in evts) {
            _queue.add(e)
        }
    }

    public func fireEvent(ctx: Context, evts: Array<Event>): Unit {
        initConsumers()
        for (e in evts) {
            fireOneEvent(ctx, e)
        }
    }

    private func fireOneEvent(ctx: Context, evt: Event): Unit {
        fireEventWildcard(ctx, evt.name, evt)
    }

    private func fireEventWildcard(ctx: Context, name: String, evt: Event): Unit {
        // 后续考虑优化性能
        let iter = _subcribers.iterator()
        while (let Some((pattern, sg)) <- iter.next()) {
            if (pattern == name || matchNode(pattern, name)) {
                sg.forEach() {
                    subcriber: EventSubscriber =>
                    subcriber.handle(ctx, evt)
                    evt.isAborted
                }
                if (evt.isAborted) {
                    return
                }
            }
        }
    }

    public func closeAndWait(): Unit {
        for (f in _consumers) {
            f.cancel()
        }
        _waitCounter.waitUntilZero()
    }
}

/**
 * @throws EventBusException
 */
private func checkPattern(pattern: String, name: String): Unit {
    if (let Some(pos) <- pattern.indexOf(EventConsts.ALL_NODE)) {
        if (pattern.count(EventConsts.ALL_NODE) != 1 || (pos != 0 && pos != pattern.size - 2)) {
            throw EventBusException(
                "invalid pattern ${pattern} in subsriber ${name}, only support start with or end with **")
        }
    } else {
        let patArr = pattern.split(".")
        for (a in patArr) {
            if (a.size != 1 && a.contains("*")) {
                // 节点上的内容中不能包含 *
                throw EventBusException(
                    "invalid pattern ${pattern} in subsriber ${name}, only support * in content node")
            }
        }
    }
}

private func matchNode(pattern: String, name: String): Bool {
    if (pattern == EventConsts.ANY_NODE) {
        return true
    }

    // 以"**"开头，或结尾
    if (let Some(pos) <- pattern.indexOf(EventConsts.ALL_NODE)) {
        if (pos == 0) {
            return name.endsWith(pattern[2..])
        } else {
            return name.startsWith(pattern[..(pattern.size - 2)])
        }
    }

    // eg: "evt.some.*.*" -> match "evt.some.thing.run" "evt.some.thing.do"
    let strArr = name.split(".")
    let patArr = pattern.split(".")

    // 要匹配的字符串比Pattern还短
    if (strArr.size < patArr.size) {
        return false
    }

    for (idx in 0..strArr.size) {
        if (strArr[idx] != patArr[idx] && patArr[idx] != "*") {
            return false
        }
    }
    true
}

let _: Unit = DEFAULT_SERVICE_CONTAINER.addService("eventbus", LocalEventBus.INSTANCE)
