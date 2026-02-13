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

import std.collection.{HashMap}

/**
 * Type alias for event data container.
 *
 * Events carry arbitrary key-value data.
 */
type EventData = HashMap<String, Any>

/**
 * Represents an event that can be published to an event bus.
 *
 * Events contain a name, arbitrary data, and an abort flag
 * to stop further processing.
 */
public class Event {
    private let _name: String
    private let _data: EventData = EventData()
    private var _aborted: Bool = false

    /**
     * Gets event name.
     */
    public prop name: String {
        get() {
            _name
        }
    }

    /**
     * Gets event data as a key-value map.
     */
    public prop data: EventData {
        get() {
            _data
        }
    }

    /**
     * Gets whether event has been aborted.
     *
     * When true, no further subscribers will process this event.
     */
    public prop isAborted: Bool {
        get() {
            _aborted
        }
    }

    private init(name: String) {
        _name = name
    }

    /**
     * Creates a new event with specified name.
     *
     * @param name event name
     * @return a new Event instance
     */
    public static func of(name: String): Event {
        Event(name)
    }

    /**
     * Adds data to event.
     *
     * @param name data key
     * @param value data value
     * @return this event for method chaining
     */
    public func addData(name: String, value: Any): Event {
        _data.add(name, value)
        this
    }

    /**
     * Aborts event, preventing all subsequent subscribers from processing it.
     *
     * @return this event for method chaining
     */
    public func abort(): Event {
        _aborted = true
        this
    }

    /**
     * Gets event data by key.
     *
     * @param T expected type of data
     * @param name data key
     * @return data value if present and can be cast to type T, otherwise null
     */
    public func getData<T>(name: String): ?T {
        (_data.get(name) ?? Option<Any>.None) as T
    }
}
