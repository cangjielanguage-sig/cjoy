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
 * Multipart content writer
 *
 * JoyMultiPartWriter is responsible for writing multipart content to an output stream
 * according to the multipart MIME specification.
 */
public class JoyMultiPartWriter <: Resource {
    private let _buffer: BufferedOutputStream<OutputStream>
    private let _boundary: String
    private var _lastPart: ?TmpPart = None
    private var _closed: Bool = false

    /**
     * Initializes a new instance of JoyMultiPartWriter
     *
     * @param output The output stream to write to
     * @param boundry Optional boundary string (will be generated if not provided)
     */
    public init(output: OutputStream, boundry!: ?String = None) {
        _buffer = BufferedOutputStream(output)
        if (let Some(b) <- boundry) {
            checkBoundary(b)
            _boundary = b
        } else {
            _boundary = secureRandStr(30)
        }
    }

    /**
     * Gets the boundary string
     *
     * @return The boundary string
     */
    public prop boundary: String {
        get() {
            _boundary
        }
    }

    /**
     * Gets the Content-Type header value for multipart form data
     *
     * @return The Content-Type string
     */
    public prop formDataContentType: String {
        get() {
            var b: String = _boundary
            if (b.indexFunc(isTSpecialAndSpace) >= 0) {
                b = #'"${b}"'#
            }
            "multipart/form-data; boundary=" + b
        }
    }

    /**
     * Creates a new part with the specified headers
     *
     * @param headers The headers for the new part
     * @return The current JoyMultiPartWriter instance for method chaining
     * @throws IllegalArgumentException if the writer is closed
     */
    public func createPart(headers: HttpHeaders): JoyMultiPartWriter {
        if (_closed) {
            throw IllegalArgumentException("can't create part after close")
        }

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
     * Writes data to the current part
     *
     * @param bs The data to write
     * @return The current JoyMultiPartWriter instance for method chaining
     * @throws IllegalArgumentException if no part is currently active or if the part is closed
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

    /**
     * Creates a file part with the specified fieldname, filename, and content type
     *
     * @param fieldname The fieldname for the part
     * @param filename The filename
     * @param contentType The content type (default: application/octet-stream)
     * @return The current JoyMultiPartWriter instance for method chaining
     */
    public func createFromFile(fieldname: String, filename: String,
        contentType!: String = JoyHttpConsts.MIME_APP_OCTET_STREAM): JoyMultiPartWriter {
        let headers = HttpHeaders()
        headers.add(JoyHttpConsts.HEADER_CONTENT_DISPOSITION,
            "form-data; name=\"${escapeQuotes(fieldname)}\"; filename=\"${escapeQuotes(filename)}\"")
        headers.add(JoyHttpConsts.HEADER_CONTENT_TYPE, contentType)
        createPart(headers)
    }

    /**
     * Creates a form field part with the specified fieldname
     *
     * @param fieldname The fieldname for the part
     * @return The current JoyMultiPartWriter instance for method chaining
     */
    public func createFormField(fieldname: String): JoyMultiPartWriter {
        let headers = HttpHeaders()
        headers.add(JoyHttpConsts.HEADER_CONTENT_DISPOSITION, "form-data; name=\"${escapeQuotes(fieldname)}\"")
        createPart(headers)
    }

    /**
     * Writes a file part with the specified content
     *
     * @param fieldname The fieldname for the part
     * @param filename The filename
     * @param fileContent The file content bytes
     * @param contentType The content type (default: application/octet-stream)
     * @return The current JoyMultiPartWriter instance for method chaining
     */
    public func writeFile(fieldname: String, filename: String, fileContent: Array<Byte>,
        contentType!: String = JoyHttpConsts.MIME_APP_OCTET_STREAM): JoyMultiPartWriter {
        createFromFile(fieldname, filename, contentType: contentType)
        writePartData(fileContent)
    }

    /**
     * Writes a form field part with the specified value
     *
     * @param fieldname The fieldname for the part
     * @param value The field value
     * @return The current JoyMultiPartWriter instance for method chaining
     */
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

    /**
     * Closes the writer and flushes all data to the output stream
     *
     * This method writes the final boundary to indicate the end of the multipart content
     * and flushes all buffered data to the output stream.
     */
    public func close(): Unit {
        if (_closed) {
            return
        }

        if (let Some(p) <- _lastPart) {
            p.close()
        }
        _lastPart = None
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
