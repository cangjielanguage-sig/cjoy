/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.schedule.api

import std.collection.concurrent.ConcurrentHashMap
import cjoy.context.Context
import cjoy.framework.Joy

public class ScheduleContext <: Context {
    private let _data: ConcurrentHashMap<String, Any> = ConcurrentHashMap()

    public func set(key: String, value: Any): Unit {
        _data.add(key, value)
    }

    public func get<T>(key: String): ?T {
        (_data.get(key) ?? Option<Any>.None) as T
    }

    public func remove(key: String): Unit {
        _data.remove(key)
    }

    public func getService<T>(name: String): ?T {
        Joy.default().getService<T>(name)
    }
}

public type ScheduleFunc = (ctx: ScheduleContext) -> Unit

public class ScheduleException <: Exception {
    public ScheduleException(msg: String) {
        super(msg)
    }
}

const badScheduleFormat = "schedule string must have five components like * * * * *"

class OutOfRange <: ToString {
    OutOfRange(
        let rangeVal!: String = "",
        let input!: String = "",
        let min!: Int = 0,
        let max!: Int = 0
    ) {
    }

    public func toString(): String {
        "out of range for ${rangeVal} in ${input}. ${rangeVal} must be in range ${min}-${max}"
    }
}

class ParsingErr <: ToString {
    ParsingErr(let invalidPart: String, let base!: String = "") {
    }

    public func toString(): String {
        if (base != "") {
            "unable to parse ${invalidPart} part in ${base}"
        } else {
            "unable to parse ${invalidPart}"
        }
    }
}
