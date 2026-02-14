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

import std.collection.HashMap
import std.fs.File
import std.io.{ByteBuffer}
import stdx.net.http.HttpHeaders

/**
 * Represents a multipart content part
 *
 * A JoyMultiPart instance contains all information about a single part of a multipart request,
 * including headers, content type, name, filename, and content data.
 */
public class JoyMultiPart {
    let _headers: HttpHeaders = HttpHeaders()
    private var _dispositionParams: HashMap<String, String> = HashMap()
    private var _isParseDisposition: Bool = false
    private var _nextState: ParseState = PS_HEADER
    private var _headerNum: Int = 0

    var _memoryHandler: ?JoyMemoryMultiPartHandler = None
    var _diskHandler: ?JoyDiskMultiPartHandler = None

    /**
     * Gets the value of a specific header from the part
     *
     * @param name The name of the header to retrieve
     * @return The header value or None if not found
     */
    public func header(name: String): ?String {
        _headers.getFirst(name)
    }

    /**
     * Gets the Content-Type header of the part
     *
     * @return The Content-Type string
     */
    public prop contentType: String {
        get() {
            _headers.getFirst("Content-Type").getOrThrow()
        }
    }

    /**
     * Gets the name of the part from Content-Disposition header
     *
     * @return The part name
     */
    public prop name: String {
        get() {
            parseContentDisposition()
            _dispositionParams.get("name") ?? ""
        }
    }

    /**
     * Sets the name for testing purposes
     */
    func setName(name: String): Unit {
        _dispositionParams["name"] = name
    }

    /**
     * Gets the filename of the part from Content-Disposition header
     *
     * @return The filename or empty string if not a file part
     */
    public prop fileName: String {
        get() {
            parseContentDisposition()
            _dispositionParams.get("filename") ?? ""
        }
    }

    /**
     * Gets the text content of the part from memory
     *
     * @return The text content as string or None if not available
     */
    public prop text: ?String {
        get() {
            _memoryHandler?.getContent(this.name).map({bb => String.fromUtf8(bb.bytes())}) ?? None
        }
    }

    /**
     * Gets the file reference of the part from disk cache
     *
     * @return The File instance or None if not available
     */
    public prop file: ?File {
        get() {
            _diskHandler?.getFile(this.name) ?? None
        }
    }

    /**
     * Gets the file content of the part from memory
     *
     * @return The file content as ByteBuffer or None if not available
     */
    public prop fileContent: ?ByteBuffer {
        get() {
            _memoryHandler?.getContent(this.name) ?? None
        }
    }

    /**
     * @throws MultiPartLimitReachedException
     * @throws MultiPartParseException
     */
    func read(r: JoyMultiPartParser, buffer: BufferReader): Unit {
        var lastCache = ByteBuffer(1024)
        while (let Some(line) <- buffer.readUntil(b'\n')) {
            let linebs = line.bytes()
            if (linebs.isEmpty()) {
                break
            }

            if (isEmptyLine(linebs) && _nextState == PS_HEADER) {
                _nextState = PS_BODY
                continue
            }

            // header line
            if (_nextState == PS_HEADER) {
                readHeader(r, linebs)
                continue
            }

            // end with dash line
            if (r.isDashLine(linebs)) {
                buffer.rewindLast()
                _nextState = PS_END
                break
            }

            // 读取Body内容，但可能中间存在\r\n
            checkIsBody()
            if (lastCache.length > 0) {
                r._handler.onPart(this, lastCache.bytes())
                lastCache.clear()
            }
            if (containEndLetter(linebs)) { // 可能是结束行
                lastCache.write(linebs)
            } else {
                r._handler.onPart(this, linebs)
            }
        }

        checkIsEnd()
        if (lastCache.length > 2) {
            let bs = lastCache.bytes()
            r._handler.onPart(this, bs[..bs.size - 2])
        }
    }

    /**
     * @throws MultiPartParseException
     */
    private func checkIsBody(): Unit {
        if (_nextState != PS_BODY) {
            throw MultiPartParseException("parse multi part failed, invalid state(${_nextState}), shoud be body line")
        }
    }

    /**
     * @throws MultiPartParseException
     */
    private func checkIsEnd(): Unit {
        if (_nextState != PS_END) {
            throw MultiPartParseException("parse multi part failed, invalid state(${_nextState}), shoud have end line")
        }
    }

    /**
     * @throws MultiPartLimitReachedException
     */
    private func readHeader(r: JoyMultiPartParser, line: Array<Byte>): Unit {
        let hKey = readHeaderKey(line)
        if (!hKey.isEmpty()) {
            _headerNum++
            if (_headerNum > r._config.maxHeaders) {
                throw MultiPartLimitReachedException("header limit reached, ${_headerNum} > ${r._config.maxHeaders}")
            }
            _headers.add(String.fromUtf8(hKey), String.fromUtf8(line[(hKey.size + 1)..]))
        }
    }

    private func isEmptyLine(line: Array<Byte>): Bool {
        line.size == 2 && line[0] == b'\r' && line[1] == b'\n'
    }

    private func containEndLetter(line: Array<Byte>): Bool {
        line.size >= 2 && line[line.size - 2] == b'\r' && line[line.size - 1] == b'\n'
    }

    private func readHeaderKey(line: Array<Byte>): Array<Byte> {
        for (i in 0..line.size) {
            if (i > 30) {
                return []
            }
            if (line[i] == b':') {
                return line[0..i]
            }
        }
        return []
    }

    private func parseContentDisposition(): Unit {
        if (_isParseDisposition) {
            return
        }

        if (let Some(h) <- _headers.getFirst("Content-Disposition")) {
            let mt = JoyMediaType.parse(h)
            _dispositionParams = mt.params
            _isParseDisposition = true
        }
    }
}
