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
 * Event subscriber interface.
 *
 * Implement this interface to handle events published to the event bus.
 */
public interface EventSubscriber {
    /**
     * Handle event.
     *
     * @param ctx application context
     * @param evt event to handle
     */
    func handle(ctx: Context, evt: Event): Unit
}

/**
 * Type alias for event subscriber function.
 *
 * Function type that can be used as a subscriber directly.
 */
public type EventSubscriberFunc = (ctx: Context, evt: Event) -> Unit

/**
 * Event subscriber that wraps a function.
 *
 * Allows a function to be used as an event subscriber.
 */
public class EventFuncSubscriber <: EventSubscriber {
    /**
     * Create a new EventFuncSubscriber.
     *
     * @param fn event subscriber function
     */
    public EventFuncSubscriber(let fn: EventSubscriberFunc) {
    }

    /**
     * Handle event by calling wrapped function.
     *
     * @param ctx application context
     * @param evt event to handle
     */
    public func handle(ctx: Context, evt: Event): Unit {
        fn(ctx, evt)
    }
}

/**
 * Event bus interface.
 *
 * Defines the contract for event bus implementations,
 * providing methods for subscribing to and firing events.
 */
public interface EventBus {
    /**
     * Register a subscriber to handle events.
     *
     * @param pattern the match pattern. Match rules:
     *   - "*" matches any sequence of non-dot characters
     *   - "**" matches all characters to end, only allowed at start or end on pattern
     *   Examples:
     *     - "evt.some.*.*"       -> matches "evt.some.thing.run", "evt.some.thing.do"
     *     - "evt.some.*.run"     -> matches "evt.some.thing.run", but not "evt.some.thing.do"
     *     - "evt.some.**"        -> matches any starting with "evt.some.", e.g., "evt.some.thing.run", "evt.some.thing.do"
     *     - "**.thing.run"       -> matches any ending with ".thing.run", e.g., "evt.some.thing.run"
     * @param name subscriber name
     * @param subscriber event subscriber
     * @param priority priority for handling events (higher values execute first)
     * @throws EventBusException if pattern is invalid
     */
    func onEvent(pattern: String, name: String, subscriber: EventSubscriber, priority: Array<Int>): Unit

    /**
     * Register a subscriber function to handle events.
     *
     * @param pattern the match pattern
     * @param name subscriber name
     * @param subscriber event subscriber function
     * @param priority priority for handling events
     * @throws EventBusException if pattern is invalid
     */
    func onEvent(pattern: String, name: String, subscriber: EventSubscriberFunc, priority: Array<Int>): Unit {
        onEvent(pattern, name, EventFuncSubscriber(subscriber), priority)
    }

    /**
     * Register a subscriber to handle events, only trigger once.
     *
     * Subscriber is automatically removed after first event is handled.
     *
     * @param pattern the match pattern
     * @param name subscriber name
     * @param listener event subscriber
     * @param priority priority for handling events
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
     * Register a subscriber function to handle events, only trigger once once.
     *
     * @param pattern the match pattern
     * @param name subscriber name
     * @param subscriber event subscriber function
     * @param priority priority for handling events
     */
    func onceEvent(pattern: String, name: String, subscriber: EventSubscriberFunc, priority: Array<Int>): Unit {
        onceEvent(pattern, name, EventFuncSubscriber(subscriber), priority)
    }

    /**
     * Remove subscriber by pattern and name.
     *
     * @param pattern the match pattern
     * @param name subscriber name
     */
    func removeSubscriber(pattern: String, name: String): Unit

    /**
     * Fire events asynchronously by queue.
     *
     * Events are queued and processed by consumer threads.
     *
     * @param cxt application context
     * @param evts events to fire
     */
    func fireEventAsync(cxt: Context, evts: Array<Event>): Unit

    /**
     * Fire events synchronously.
     *
     * Events are processed immediately on calling thread.
     *
     * @param cxt application context
     * @param evts events to fire
     */
    func fireEvent(cxt: Context, evts: Array<Event>): Unit

    /**
     * Async fire event by thread.
     *
     * Fires events in a new thread with a new context.
     *
     * @param _ context (ignored, creates new MapContext)
     * @param evts events to fire
     */
    func asyncFireEvent(_: Context, evts: Array<Event>): Unit {
        spawn {
            fireEvent(MapContext(), evts)
        }
    }

    /**
     * Close event bus and wait for all async events to complete.
     *
     * Cancels consumer threads and waits for pending events to be processed.
     *
     * @throws InterruptedException if interrupted while waiting
     */
    func closeAndWait(): Unit
}

/**
 * Event bus exception.
 *
 * Thrown for event bus related errors such as invalid patterns.
 */
public class EventBusException <: Exception {
    /**
     * Create a new event bus exception.
     *
     * @param message error message
     */
    public EventBusException(message: String) {
        super(message)
    }
}

/**
 * Constants for constants configuration.
 */
public struct EventConsts {
    /**
     * Minimum priority level (-1000).
     */
    public static const PRIORITY_MIN: Int = -1000

    /**
     * Low priority level (-500).
     */
    public static const PRIORITY_LOW: Int = -500

    /**
     * Normal priority level (0).
     */
    public static const PRIORITY_NORMAL: Int = 0

    /**
     * High priority level (500).
     */
    public static const PRIORITY_HIGH: Int = 500

    /**
     * Maximum priority level (1000).
     */
    public static const PRIORITY_MAX: Int = 1000

    /**
     * Wildcard matching any single node (*).
     */
    public static const ANY_NODE: String = "*"

    /**
     * Wildcard matching all nodes to end (**).
     */
    public static const ALL_NODE: String = "**"
}
