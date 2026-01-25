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
import std.convert.RadixConvertible
import std.io.OutputStream
import stdx.net.http.HttpHeaders
import cjoy.framework.JoyHttpConsts
import cjoy.utils.{StrExt, trimString}
import cjoy.multipart.JoyMultiPartWriter

class JoyHttpRange {
    private static let PREFIX = "bytes="

    public JoyHttpRange(let start!: Int = 0, let length!: Int = 0) {}

    public func contentRange(size: Int): String {
        "bytes ${start}-${start + length - 1}/${size}"
    }

    public func mimeHeaders(contentType: String, size: Int): HttpHeaders {
        let headers = HttpHeaders()
        headers.add(JoyHttpConsts.HEADER_CONTENT_TYPE, contentType)
        headers.add(JoyHttpConsts.HEADER_CONTENT_RANGE, contentRange(size))
        headers
    }

    /**
     * parse http range
     *
     * @throws IllegalArgumentException
     */
    public static func parse(str: String, size: Int): JoyHttpRangs {
        let res: JoyHttpRangs = JoyHttpRangs()
        if (str.isEmpty()) {
            throw IllegalArgumentException("invalid http range, ${str}")
        }

        if (!str.startsWith(PREFIX)) {
            throw IllegalArgumentException("invalid http range, ${str}")
        }

        let remain = trimString(str[PREFIX.size..])
        if (remain.isEmpty()) {
            throw IllegalArgumentException("invalid http range, ${str}")
        }

        let array = remain.split(",")
        var noOverlap = false
        for (s in array) {
            let x = trimString(s)
            if (x.isEmpty()) {
                continue
            }

            var (start, end, ok) = x.cut(b'-')
            if (!ok) {
                throw IllegalArgumentException("invalid http range, ${str}")
            }
            start = trimString(start)
            end = trimString(end)

            let httpRange = if (start.isEmpty()) {
                if (end.isEmpty() || end[0] == b'-') {
                    throw IllegalArgumentException("invalid http range, ${str}")
                }
                var i = Int.parse(end, radix: 10)
                if (i > size) {
                    i = size
                }
                JoyHttpRange(start: size - i, length: i)
            } else {
                var istart = Int.parse(start, radix: 10)
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
                    iend = Int.parse(end, radix: 10)
                    if (istart > iend) {
                        throw IllegalArgumentException("invalid http range, ${str}")
                    }
                    if (iend >= size) {
                        iend = size - 1
                    }
                    ilen = iend - istart + 1
                }
                JoyHttpRange(start: istart, length: ilen)
            }
            res.add(httpRange)
        }

        if (res.isEmpty()) {
            if (noOverlap) {
                throw IllegalArgumentException("invalid range: failed to overlap")
            } else {
                throw IllegalArgumentException("invalid range: ${str}")
            }
        }
        res
    }
}

type JoyHttpRangs = ArrayList<JoyHttpRange>

extend JoyHttpRangs {
    func sumSize(): Int {
        var size = 0
        for (hr in this) {
            size += hr.length
        }
        return size
    }

    func mimeSize(contentType: String, size: Int): Int {
        let writer = CountingWriter()
        var encSize = 0
        try (mw = JoyMultiPartWriter(writer)) {
            for (ra in this) {
                mw.createPart(ra.mimeHeaders(contentType, size))
                encSize += ra.length
            }
        }
        encSize += writer.len
        encSize
    }
}

class CountingWriter <: OutputStream {
    var len = 0
    public func write(buffer: Array<Byte>): Unit {
        len += buffer.size
    }
}
