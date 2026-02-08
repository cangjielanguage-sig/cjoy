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
 * Type alias for event data container
 */
type EventData = HashMap<String, Any>

/**
 * Represents an event that can be published to an event bus
 * Events contain a name, arbitrary data, and an abort flag to stop further processing
 */
public class Event {
    private let _name: String
    private let _data: EventData = EventData()
    private var _aborted: Bool = false

    /**
     * Gets the event name
     */
    public prop name: String {
        get() {
            _name
        }
    }

    /**
     * Gets the event data as a key-value map
     */
    public prop data: EventData {
        get() {
            _data
        }
    }

    /**
     * Gets whether the event has been aborted
     * When true, no further subscribers will process this event
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
     * Creates a new event with the specified name
     *
     * @param name: the event name
     * @return a new Event instance
     */
    public static func of(name: String): Event {
        Event(name)
    }

    /**
     * Adds data to the event
     *
     * @param name: the data key
     * @param value: the data value
     * @return this event for method chaining
     */
    public func addData(name: String, value: Any): Event {
        _data.add(name, value)
        this
    }

    /**
     * Aborts the event, preventing all subsequent subscribers from processing it
     *
     * @return this event for method chaining
     */
    public func abort(): Event {
        _aborted = true
        this
    }

    /**
     * Gets event data by key
     *
     * @param T: the expected type of the data
     * @param name: the data key
     * @return the data value if present and can be cast to type T, otherwise null
     */
    public func getData<T>(name: String): ?T {
        (_data.get(name) ?? Option<Any>.None) as T
    }
}
