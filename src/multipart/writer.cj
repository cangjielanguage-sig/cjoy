/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.multipart

import std.io.{OutputStream, BufferedOutputStream}
import stdx.net.http.HttpHeaders
import cjoy.utils.{StrExt, secureRandStr}
import cjoy.framework.{JoyHttpConsts}

/**
 * multi part writer
 */
public class JoyMultiPartWriter <: Resource {
    private let _buffer: BufferedOutputStream<OutputStream>
    private let _boundary: String
    private var _lastPart: ?TmpPart = None
    private var _closed: Bool = false

    public init(output: OutputStream, boundry!: ?String = None) {
        _buffer = BufferedOutputStream(output)
        if (let Some(b) <- boundry) {
            checkBoundary(b)
            _boundary = b
        } else {
            _boundary = secureRandStr(30)
        }
    }

    public prop boundary: String {
        get() {
            _boundary
        }
    }

    public prop formDataContentType: String {
        get() {
            var b: String = _boundary
            if (b.indexFunc(isTSpecialAndSpace) >= 0) {
                b = #'"${b}"'#
            }
            "multipart/form-data; boundary=" + b
        }
    }

    private func createPart(headers: HttpHeaders): JoyMultiPartWriter {
        if (let Some(p) <- _lastPart) {
            p.close()
        }

        if (_lastPart.isSome()) {
            _buffer.write("\r\n--${_boundary}\r\n".toArray())
        } else {
            _buffer.write("--${_boundary}\r\n".toArray())
        }

        for ((name, values) in headers) {
            _buffer.write("${name}: ${values.toArray()[0]}\r\n".toArray())
        }

        _buffer.write([b'\r', b'\n'])
        _lastPart = TmpPart()
        this
    }

    /**
     * @throws IllegalArgumentException
     */
    public func writePartData(bs: Array<Byte>): JoyMultiPartWriter {
        if (_lastPart.isNone()) {
            throw IllegalArgumentException("part is not exist, must create it firstly.")
        }
        if (let Some(p) <- _lastPart) {
            if (p._closed) {
                throw IllegalArgumentException("can't write to finished part")
            }
        }
        _buffer.write(bs)
        this
    }

    public func createFromFile(fieldname: String, filename: String,
        contentType!: String = JoyHttpConsts.MIME_APP_OCTET_STREAM): JoyMultiPartWriter {
        let headers = HttpHeaders()
        headers.add(JoyHttpConsts.HEADER_CONTENT_DISPOSITION,
            "form-data; name=\"${escapeQuotes(fieldname)}\"; filename=\"${escapeQuotes(filename)}\"")
        headers.add(JoyHttpConsts.HEADER_CONTENT_TYPE, contentType)
        createPart(headers)
    }

    public func createFormField(fieldname: String): JoyMultiPartWriter {
        let headers = HttpHeaders()
        headers.add(JoyHttpConsts.HEADER_CONTENT_DISPOSITION, "form-data; name=\"${escapeQuotes(fieldname)}\"")
        createPart(headers)
    }

    public func writeFile(fieldname: String, filename: String, fileContent: Array<Byte>,
        contentType!: String = JoyHttpConsts.MIME_APP_OCTET_STREAM): JoyMultiPartWriter {
        createFromFile(fieldname, filename, contentType: contentType)
        writePartData(fileContent)
    }

    public func writeField(fieldname: String, value: String): JoyMultiPartWriter {
        createFormField(fieldname)
        writePartData(value.toArray())
    }

    /**
     * @throws IllegalArgumentException
     */
    private static func checkBoundary(boundary: String): Unit {
        if (boundary.size < 1 || boundary.size > 70) {
            throw IllegalArgumentException("invalid boundary length")
        }

        var idx = 0
        for (c in boundary) {
            idx++
            if (b'A' <= c && c <= b'Z' || b'a' <= c && c <= b'z' || b'0' <= c && c <= b'9') {
                continue
            }
            match (c) {
                case b'\'' | b'(' | b')' | b'+' | b'_' | b',' | b'-' | b'.' | b'/' | b':' | b'=' | b'?' => continue
                case ' ' =>
                    if (idx != boundary.size) {
                        continue
                    }
                case _ => ()
            }
            throw IllegalArgumentException("invalid boundary character")
        }
    }

    public func close(): Unit {
        if (_closed) {
            return
        }

        if (let Some(p) <- _lastPart) {
            p.close()
            _lastPart = None
        }
        _buffer.write("\r\n--${_boundary}--\r\n".toArray())
        _buffer.flush()
        _closed = true
    }

    public func isClosed(): Bool {
        _closed
    }
}

private class TmpPart {
    var _closed: Bool = false
    func close() {
        _closed = true
    }
}
