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

import std.time.DateTime
import std.deriving.Derive

@Derive[ToString]
class CronTick {
    CronTick(let sec!: Int, let min!: Int, let hour!: Int, let day!: Int, let month!: Int, let dayOfWeek!: Int) {
    }

    static func of(dt: DateTime): CronTick {
        CronTick(sec: dt.second, min: dt.minute, hour: dt.hour, day: dt.dayOfMonth, month: dt.month.toInteger(),
            dayOfWeek: dt.dayOfWeek.toInteger())
    }
}
