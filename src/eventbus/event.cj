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
 * 事件数据容器的类型别名。
 *
 * 事件携带任意键值数据。
 */
type EventData = HashMap<String, Any>

/**
 * 表示可以发布到事件总线的事件。
 *
 * 事件包含名称、任意数据和中止标志，
 * 用于停止进一步处理。
 */
public class Event {
    private let _name: String
    private let _data: EventData = EventData()
    private var _aborted: Bool = false

    /**
     * 获取事件名称。
     */
    public prop name: String {
        get() {
            _name
        }
    }

    /**
     * 以键值映射形式获取事件数据。
     */
    public prop data: EventData {
        get() {
            _data
        }
    }

    /**
     * 获取事件是否已被中止。
     *
     * 为 true 时，不再有订阅者处理此事件。
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
     * 创建具有指定名称的新事件。
     *
     * @param name 事件名称
     * @return 新的事件实例
     */
    public static func of(name: String): Event {
        Event(name)
    }

    /**
     * 向事件添加数据。
     *
     * @param name 数据键
     * @param value 数据值
     * @return 此事件，用于方法链式调用
     */
    public func addData(name: String, value: Any): Event {
        _data.add(name, value)
        this
    }

    /**
     * 中止事件，阻止所有后续订阅者处理它。
     *
     * @return 此事件，用于方法链式调用
     */
    public func abort(): Event {
        _aborted = true
        this
    }

    /**
     * 按键获取事件数据。
     *
     * @param T 期望的数据类型
     * @param name 数据键
     * @return 如果存在且可以转换为类型 T 的数据值，否则为 null
     */
    public func getData<T>(name: String): ?T {
        (_data.get(name) ?? Option<Any>.None) as T
    }
}
