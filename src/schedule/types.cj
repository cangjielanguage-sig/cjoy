/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.schedule

import cjoy.context.MapContext
import cjoy.framework.Joy

/**
 * Schedule context for scheduled task execution
 */
public class ScheduleContext <: MapContext {
    public func getService<T>(name: String): ?T {
        Joy.default().getService<T>(name)
    }
}

/**
 * Function type for scheduled task execution
 */
public type ScheduleFunc = (ctx: ScheduleContext) -> Unit

/**
 * Schedule exception for scheduling errors
 */
public class ScheduleException <: Exception {
    public ScheduleException(msg: String) {
        super(msg)
    }
}

const BAD_CRON_FORMAT: String = "schedule string must have five components like * * * * *"

/**
 * Out of range error for cron field values
 */
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

/**
 * Parsing error for cron expressions
 */
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
