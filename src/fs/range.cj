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

/**
 * 表示 HTTP 字节范围请求
 */
class JoyHttpRange {
    private static let PREFIX = "bytes="

    /**
     * 创建新的 HTTP 范围实例
     *
     * @param start 范围的起始位置
     * @param length 范围的长度
     */
    public JoyHttpRange(let start!: Int = 0, let length!: Int = 0) {}

    /**
     * 获取给定大小的内容范围字符串
     *
     * @param size 内容的总大小
     * @return 内容范围字符串
     */
    public func contentRange(size: Int): String {
        "bytes ${start}-${start + length - 1}/${size}"
    }

    /**
     * 获取范围的 MIME 头
     *
     * @param contentType 内容类型
     * @param size 内容的总大小
     * @return 范围的 HTTP 头
     */
    public func mimeHeaders(contentType: String, size: Int): HttpHeaders {
        let headers = HttpHeaders()
        headers.add(JoyHttpConsts.HEADER_CONTENT_TYPE, contentType)
        headers.add(JoyHttpConsts.HEADER_CONTENT_RANGE, contentRange(size))
        headers
    }

    /**
     * 解析 HTTP Range 头字符串
     *
     * @param str 要解析的 Range 头字符串
     * @param size 内容的总大小
     * @return 解析后的 HTTP 范围列表
     * @throws IllegalArgumentException 如果范围字符串无效
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

/**
 * HTTP 范围列表的类型别名
 */
type JoyHttpRangs = ArrayList<JoyHttpRange>

/**
 * JoyHttpRangs 的扩展函数
 */
extend JoyHttpRangs {
    /**
     * 计算所有范围的总大小
     *
     * @return 所有范围的总大小
     */
    func sumSize(): Int {
        var size = 0
        for (hr in this) {
            size += hr.length
        }
        return size
    }

    /**
     * 计算范围作为 multipart/byteranges 时的 MIME 大小
     *
     * @param contentType 响应的内容类型
     * @param size 内容的总大小
     * @return 范围的 MIME 大小
     */
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

/**
 * 追踪写入字节数的计数器
 */
class CountingWriter <: OutputStream {
    var len = 0

    /**
     * 将给定缓冲区写入写入器并增加字节计数
     *
     * @param buffer 要写入的缓冲区
     */
    public func write(buffer: Array<Byte>): Unit {
        len += buffer.size
    }
}
