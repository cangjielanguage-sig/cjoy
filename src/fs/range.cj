/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.fs

import std.collection.ArrayList
import std.convert.Parsable
import stdx.net.http.HttpHeaders
import cjoy.utils.StrExt
import cjoy.framework.JoyHttpConsts

class JoyHttpRange {
    private static let PREFIX = "bytes="

    public JoyHttpRange(let start!: Int = 0, let length!: Int = 0) {}

    func contentRange(size: Int): String {
        "bytes ${start}-${start + length - 1}/${size}"
    }

    public func addToHeaders(headers: HttpHeaders, contentType: String, size: Int): Unit {
        headers.add(JoyHttpConsts.HEADER_RANGE, contentRange(size))
        headers.add(JoyHttpConsts.HEADER_CONTENT_TYPE, contentType)
    }

    /**
     * @throws IllegalArgumentException
     */
    public static func parse(str: String, size: Int): JoyHttpRangs {
        let res: JoyHttpRangs = ArrayList()
        if (str.isEmpty()) {
            return res
        }
        if (!str.startsWith(PREFIX)) {
            throw IllegalArgumentException("invalid http range, ${str}")
        }

        let remain = str[PREFIX.size..]
        let array = str.split(",")
        var noOverlap = false
        for (s in array) {
            let x = s.trimAscii()
            if (x.isEmpty()) {
                continue
            }
            var (start, end, ok) = x.cut(b'-')
            if (!ok) {
                throw IllegalArgumentException("invalid http range, ${str}")
            }
            start = start.trimAscii()
            end = end.trimAscii()

            let httpRange = if (start.isEmpty()) {
                if (end.isEmpty() || end[0] == b'-') {
                    throw IllegalArgumentException("invalid http range, ${str}")
                }
                var i = Int.parse(end)
                if (i > size) {
                    i = size
                }
                JoyHttpRange(start: size - i, length: i)
            } else {
                var istart = Int.parse(start)
                var iend = 0
                var ilen = 0
                if (istart < 0) {
                    throw IllegalArgumentException("invalid http range, ${str}")
                }
                if (istart > size) {
                    noOverlap = true
                    continue
                }
                if (end.isEmpty()) {
                    ilen = size - istart
                } else {
                    iend = Int.parse(end)
                    if (istart > iend) {
                        throw IllegalArgumentException("invalid http range, ${str}")
                    }
                    if (iend >= size) {
                        istart = size - 1
                    }
                    ilen = iend - istart + 1
                }
                JoyHttpRange(start: istart, length: ilen)
            }
            res.add(httpRange)
        }

        if (noOverlap && res.isEmpty()) {
            throw IllegalArgumentException("invalid range: failed to overlap")
        }
        res
    }
}

type JoyHttpRangs = ArrayList<JoyHttpRange>

extend JoyHttpRangs {
    func sumSize() {
        var size = 0
        for (hr in this) {
            size += hr.length
        }
        return size
    }
}
