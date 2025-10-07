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
import std.sort.sort
import std.sync.Mutex

class EventSubscriberItem {
    EventSubscriberItem(let name: String, let subcriber: EventSubscriber, let priority: Int) {}
}

class EventSubscriberGroup {
    private let _items: ArrayList<EventSubscriberItem> = ArrayList()
    private let _mutex: Mutex = Mutex()

    static func of(item: EventSubscriberItem): EventSubscriberGroup {
        let queue = EventSubscriberGroup()
        queue.add(item)
        queue
    }

    func add(item: EventSubscriberItem): Unit {
        synchronized(_mutex) {
            _items.add(item)
            sortItems()
        }
    }

    func del(name: String): Unit {
        synchronized(_mutex) {
            _items.removeIf({
                it: EventSubscriberItem => it.name == name
            })
        }
    }

    func sortItems(): Unit {
        sort(_items,
            by: {
                a: EventSubscriberItem, b: EventSubscriberItem => if (a.priority < b.priority) {
                    Ordering.GT
                } else if (a.priority > b.priority) {
                    Ordering.LT
                } else {
                    Ordering.EQ
                }
            }, stable: true)
    }

    func forEach(fn: (subcriber: EventSubscriber) -> Bool): Unit {
        synchronized(_mutex) {
            for (it in _items) {
                if (fn(it.subcriber)) {
                    return
                }
            }
        }
    }
}
