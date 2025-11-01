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

import cjoy.context.{Context, MapContext}

/**
 * implements the EventSubscriber interface to handle event
 */
public interface EventSubscriber {
    func handle(ctx: Context, evt: Event): Unit
}

public type EventSubscriberFunc = (ctx: Context, evt: Event) -> Unit

public class EventFuncSubscriber <: EventSubscriber {
    public EventFuncSubscriber(let fn: EventSubscriberFunc) {
    }

    public func handle(ctx: Context, evt: Event): Unit {
        fn(ctx, evt)
    }
}

public interface EventBus {
    /**
     * register a subscriber to handle events
     *
     * @param pattern：the match pattern，match rule
     *  - "*" matches any sequence of non . characters
     *  - "**" match all characters to end, only allow at start or end on pattern.
     *  like:
     *  - "evt.some.*.*"       -> match "evt.some.thing.run" "evt.some.thing.do"
     *  - "evt.some.*.run"     -> match "evt.some.thing.run", but not match "evt.some.thing.do"
     *  - "evt.some.**"        -> match any start with "evt.some.". eg: "evt.some.thing.run" "evt.some.thing.do"
     *  - "**.thing.run"       -> match any ends with ".thing.run". eg: "evt.some.thing.run"
     * @param name: the sucriber name
     * @param subcriber: the subcriber
     * @param priority: the priority of handle event
     * @throws EventBusException if the pattern is invalid
     */
    func onEvent(pattern: String, name: String, subcriber: EventSubscriber, priority: Array<Int>): Unit

    func onEvent(pattern: String, name: String, subcriber: EventSubscriberFunc, priority: Array<Int>): Unit {
        onEvent(pattern, name, EventFuncSubscriber(subcriber), priority)
    }

    /**
     * register a subscriber to handle events, only trigger once
     */
    func onceEvent(pattern: String, name: String, listener: EventSubscriber, priority: Array<Int>): Unit {
        let onceListener = {
            ctx: Context, evt: Event => try {
                listener.handle(ctx, evt)
            } finally {
                removeSubscriber(pattern, name)
            }
        }
        onEvent(pattern, name, onceListener, priority)
    }

    func onceEvent(pattern: String, name: String, subcriber: EventSubscriberFunc, priority: Array<Int>): Unit {
        onceEvent(pattern, name, EventFuncSubscriber(subcriber), priority)
    }

    /**
     * remove the subscriber by pattern and name
     */
    func removeSubscriber(pattern: String, name: String): Unit

    /**
     * fire event by queue
     */
    func fireEventAsync(cxt: Context, evts: Array<Event>): Unit

    /**
     * fire event sync
     */
    func fireEvent(cxt: Context, evts: Array<Event>): Unit

    /**
     * async fire event by thread
     */
    func asyncFireEvent(_: Context, evts: Array<Event>): Unit {
        spawn {
            fireEvent(MapContext(), evts)
        }
    }

    /**
     * close queue and wait for all async events done.
     */
    func closeAndWait(): Unit
}

public class EventBusException <: Exception {
    public EventBusException(message: String) {
        super(message)
    }
}

public struct EventConsts {
    // Priority
    public static const PRIORITY_MIN: Int = -1000
    public static const PRIORITY_LOW: Int = -500
    public static const PRIORITY_NORMAL: Int = 0
    public static const PRIORITY_HIGH: Int = 500
    public static const PRIORITY_MAX: Int = 1000

    // Wildcard
    public static const ANY_NODE: String = "*"
    public static const ALL_NODE: String = "**"
}
