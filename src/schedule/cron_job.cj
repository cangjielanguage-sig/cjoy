/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.schedule

import std.collection.{HashSet}
import std.regex.Regex
import std.convert.Parsable
import std.time.DateTime
import cjoy.log.macros.*

public class CronJob <: Equatable<CronJob> & ToString {
    private static let REG_SPACES = Regex(##"\s+"##)
    private static let REG_N = Regex(##"(.*)/(\d+)"##)
    private static let REG_RANGE = Regex(##"^(\d+)-(\d+)$"##)

    private let _fn: ScheduleFunc
    private let _name: String
    private let _context: ScheduleContext = ScheduleContext()

    private var _sec: HashSet<Int>
    private var _min: HashSet<Int>
    private var _hour: HashSet<Int>
    private var _day: HashSet<Int>
    private var _month: HashSet<Int>
    private var _dayOfWeek: HashSet<Int>

    init(name: String, fn: ScheduleFunc, sec!: HashSet<Int> = HashSet(), min!: HashSet<Int> = HashSet(),
        hour!: HashSet<Int> = HashSet(), day!: HashSet<Int> = HashSet(), month!: HashSet<Int> = HashSet(),
        dayOfWeek!: HashSet<Int> = HashSet()) {
        _name = name
        _fn = fn
        _sec = sec
        _min = min
        _hour = hour
        _day = day
        _month = month
        _dayOfWeek = dayOfWeek
    }

    public operator func ==(rhs: CronJob): Bool {
        _name == rhs._name && _sec == rhs._sec && _min == rhs._min && _hour == rhs._hour && _day == rhs._day &&
            _month == rhs._month && _dayOfWeek == rhs._dayOfWeek
    }

    public func toString(): String {
        "${_name}, sec:${_sec}, min:${_min}, hour:${_hour}, day:${_day}, month:${_month}, dayOfWeek:${_dayOfWeek}"
    }

    /**
     * @throws ScheduleException
     */
    public static func parse(name: String, exp: String, fn: ScheduleFunc): CronJob {
        let job = CronJob(name, fn)
        var s = REG_SPACES.replaceAll(exp, " ")
        s = s.trimStart(" ")
        s = s.trimEnd(" ")

        var partsIdx = 0

        let parts = s.split(" ")
        match (parts.size) {
            case 6 =>
                job._sec = parsePart(parts[0], 0, 59)
                partsIdx++
            case 5 => partsIdx = 0
            case _ => throw ScheduleException(BAD_CRON_FORMAT)
        }

        job._min = parsePart(parts[partsIdx], 0, 59)
        job._hour = parsePart(parts[partsIdx + 1], 0, 23)
        job._day = parsePart(parts[partsIdx + 2], 1, 31)
        job._month = parsePart(parts[partsIdx + 3], 1, 12)
        job._dayOfWeek = parsePart(parts[partsIdx + 4], 0, 6)

        job.mergeDays()
        job
    }

    func tick(t: CronTick): Bool {
        if (!_min.contains(t.min)) {
            return false
        }

        if (!_hour.contains(t.hour)) {
            return false
        }

        let day = _day.contains(t.day)
        let dayOfWeek = _dayOfWeek.contains(t.dayOfWeek)
        if (!day && !dayOfWeek) {
            return false
        }

        if (!_month.contains(t.month)) {
            return false
        }

        if (_sec.isEmpty()) {
            if (t.sec != 0) {
                return false
            }
        } else {
            if (!_sec.contains(t.sec)) {
                return false
            }
        }

        return true
    }

    public func run(start: DateTime): Unit {
        @LogInfo("[Schedule] starting cron job: ${_name}")
        try {
            _fn(_context)
        } finally {
            let dt: Duration = (DateTime.now().toUnixTimeStamp() - start.toUnixTimeStamp())
            @LogInfo("[Schedule] fininish cron job: ${_name} in ${dt}")
        }
    }

    private static func parsePart(str: String, min: Int, max: Int): HashSet<Int> {
        // wildcard pattern
        if (str == "*") {
            return getDefaultJobField(min, max, 1)
        }

        // */2 1-59/5 pattern
        let matches = REG_N.findAll(str, group: true)
        if (matches.size == 1 && matches[0].groupCount() == 2) {
            return parseSteps(str, matches[0].matchString(1), matches[0].matchString(2), min, max)
        }

        // 1,2,4 or 1,2,10-15,20,30-45 pattern
        return parseRange(str, min, max)
    }

    /**
     * @throws ScheduleException
     */
    private static func parseSteps(str: String, match1: String, match2: String, min: Int, max: Int): HashSet<Int> {
        var lmin = min
        var lmax = max

        if (match1 != "" && match1 != "*") {
            let rng = REG_RANGE.findAll(match1, group: true)
            if (rng.size != 1) {
                throw ScheduleException(ParsingErr(match1, base: str).toString())
            }

            lmin = Int.tryParse(rng[0].matchString(1)) ?? throw ScheduleException(
                "parse step failed, ${match1} in ${str}")
            lmax = Int.tryParse(rng[0].matchString(2)) ?? throw ScheduleException(
                "parse step failed, ${match1} in ${str}")
            if (lmin < min || lmax > max) {
                throw ScheduleException(OutOfRange(rangeVal: match1, input: str, min: min, max: max).toString())
            }
        }

        let n = Int.tryParse(match2).getOrThrow({=> ScheduleException("parse step failed, ${match2} in ${str}")})
        getDefaultJobField(lmin, lmax, n)
    }

    /**
     * @throws ScheduleException
     */
    private static func parseRange(str: String, min: Int, max: Int): HashSet<Int> {
        let res = HashSet<Int>()
        let parts = str.split(",")
        for (part in parts) {
            parseSingleOrRange(part, min, max, res)
        }

        if (res.isEmpty()) {
            throw ScheduleException(ParsingErr(str).toString())
        }
        res
    }

    /**
     * @throws ScheduleException
     */
    private static func parseSingleOrRange(part: String, min: Int, max: Int, res: HashSet<Int>): Unit {
        let rng = REG_RANGE.findAll(part, group: true)
        if (rng.size == 1 && rng[0].groupCount() == 2) {
            let lmin = Int.tryParse(rng[0].matchString(1)) ?? throw ScheduleException(
                "parse single or range failed, ${part}")
            let lmax = Int.tryParse(rng[0].matchString(2)) ?? throw ScheduleException(
                "parse single or range failed, ${part}")
            if (lmin < min || lmax > max) {
                throw ScheduleException(OutOfRange(rangeVal: part, input: part, min: min, max: max).toString())
            }
            for (i in lmin..=lmax) {
                res.add(i)
            }
        } else {
            let n = Int.tryParse(part) ?? throw ScheduleException(ParsingErr(part, base: part).toString())
            if (n < min || n > max) {
                throw ScheduleException(OutOfRange(rangeVal: part, input: part, min: min, max: max).toString())
            }
            res.add(n)
        }
    }

    static func getDefaultJobField(min: Int, max: Int, incr: Int): HashSet<Int> {
        let res = HashSet<Int>()
        for (i in min..=max : incr) {
            res.add(i)
        }
        res
    }

    private func mergeDays() {
        match {
            case _day.size < 31 && _dayOfWeek.size == 7 => _dayOfWeek.clear()
            case _dayOfWeek.size < 7 && _day.size == 31 => _day.clear()
            case _ => ()
        }
    }
}
