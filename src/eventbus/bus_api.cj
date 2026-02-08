/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.eventbus

import cjoy.context.{Context, MapContext}

/**
 * implements the EventSubscriber interface to handle event
 */
public interface EventSubscriber {
    /**
     * handle the event
     *
     * @param ctx: the context
     * @param evt: the event
     */
    func handle(ctx: Context, evt: Event): Unit
}

/**
 * Type alias for event subscriber function
 */
public type EventSubscriberFunc = (ctx: Context, evt: Event) -> Unit

/**
 * the event subscriber that wraps a function
 */
public class EventFuncSubscriber <: EventSubscriber {
    /**
     * create a new EventFuncSubscriber
     *
     * @param fn: the event subscriber function
     */
    public EventFuncSubscriber(let fn: EventSubscriberFunc) {
    }

    /**
     * handle the event by calling the function
     *
     * @param ctx: the context
     * @param evt: the event
     */
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

    /**
     * register a subscriber function to handle events
     *
     * @param pattern: the match pattern
     * @param name: the sucriber name
     * @param subcriber: the subscriber function
     * @param priority: the priority of handle event
     * @throws EventBusException if the pattern is invalid
     */
    func onEvent(pattern: String, name: String, subcriber: EventSubscriberFunc, priority: Array<Int>): Unit {
        onEvent(pattern, name, EventFuncSubscriber(subcriber), priority)
    }

    /**
     * register a subscriber to handle events, only trigger once
     *
     * @param pattern: the match pattern
     * @param name: the sucriber name
     * @param listener: the subscriber
     * @param priority: the priority of handle event
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

    /**
     * register a subscriber function to handle events, only trigger once
     *
     * @param pattern: the match pattern
     * @param name: the sucriber name
     * @param subcriber: the subscriber function
     * @param priority: the priority of handle event
     */
    func onceEvent(pattern: String, name: String, subcriber: EventSubscriberFunc, priority: Array<Int>): Unit {
        onceEvent(pattern, name, EventFuncSubscriber(subcriber), priority)
    }

    /**
     * remove the subscriber by pattern and name
     *
     * @param pattern: the match pattern
     * @param name: the subscriber name
     */
    func removeSubscriber(pattern: String, name: String): Unit

    /**
     * fire event by queue
     *
     * @param cxt: the context
     * @param evts: the events to fire
     */
    func fireEventAsync(cxt: Context, evts: Array<Event>): Unit

    /**
     * fire event sync
     *
     * @param cxt: the context
     * @param evts: the events to fire
     */
    func fireEvent(cxt: Context, evts: Array<Event>): Unit

    /**
     * async fire event by thread
     *
     * @param evts: the events to fire
     */
    func asyncFireEvent(_: Context, evts: Array<Event>): Unit {
        spawn {
            fireEvent(MapContext(), evts)
        }
    }

    /**
     * close queue and wait for all async events done.
     *
     * @throws InterruptedException if interrupted while waiting
     */
    func closeAndWait(): Unit
}

public class EventBusException <: Exception {
    /**
     * create a new event bus exception
     *
     * @param message: the error message
     */
    public EventBusException(message: String) {
        super(message)
    }
}

/**
 * Constants for event bus configuration
 */
public struct EventConsts {
    /**
     * Minimum priority level (-1000)
     */
    public static const PRIORITY_MIN: Int = -1000
    /**
     * Low priority level (-500)
     */
    public static const PRIORITY_LOW: Int = -500
    /**
     * Normal priority level (0)
     */
    public static const PRIORITY_NORMAL: Int = 0
    /**
     * High priority level (500)
     */
    public static const PRIORITY_HIGH: Int = 500
    /**
     * Maximum priority level (1000)
     */
    public static const PRIORITY_MAX: Int = 1000

    /**
     * Wildcard matching any single node (*)
     */
    public static const ANY_NODE: String = "*"
    /**
     * Wildcard matching all nodes to end (**)
     */
    public static const ALL_NODE: String = "**"
}
