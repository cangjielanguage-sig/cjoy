/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.eventbus

import std.collection.{HashMap}

type EventData = HashMap<String, Any>

/**
 * the event data
 */
public class Event {
    private let _name: String
    private let _data: EventData = EventData()
    private var _aborted: Bool = false

    /**
     * return the event name
     */
    public prop name: String {
        get() {
            _name
        }
    }

    /**
     * return the all event data
     */
    public prop data: EventData {
        get() {
            _data
        }
    }

    /**
     * return the event abort state
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
     * create a event by name
     */
    public static func of(name: String): Event {
        Event(name)
    }

    /**
     * add event data
     */
    public func addData(name: String, value: Any): Event {
        _data.add(name, value)
        this
    }

    /**
     * abort it then skip all next subscribers
     */
    public func abort(): Event {
        _aborted = true
        this
    }

    /**
     * get event data
     */
    public func getData<T>(name: String): ?T {
        (_data.get(name) ?? Option<Any>.None) as T
    }
}
