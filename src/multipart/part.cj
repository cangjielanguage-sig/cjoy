/*
 * Copyright (c) lanlingx 2025-present. All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.multipart

import std.collection.HashMap
import std.io.{InputStream, ByteBuffer}
import net.http.HttpHeaders

public class JoyMultiPart {
    let _header: HttpHeaders = HttpHeaders()
    private var _dispositionParams: HashMap<String, String> = HashMap()
    private var _isParseDisposition: Bool = false

    private var _totalSize = 0
    private var _contentSize = 0

    public func header(name: String): ?String {
        _header.getFirst(name)
    }

    public prop contentType: String {
        get() {
            _header.getFirst("Content-Type").getOrThrow()
        }
    }

    public prop name: String {
        get() {
            parseContentDisposition()
            _dispositionParams.get("name").getOrDefault({=> ""})
        }
    }

    public prop fileName: String {
        get() {
            parseContentDisposition()
            _dispositionParams.get("filename").getOrDefault({=> ""})
        }
    }

    public prop size: Int {
        get() {
            _totalSize
        }
    }

    public prop contentSize: Int {
        get() {
            _contentSize
        }
    }

    func read(r: JoyMultiPartParser, buffer: BufferReader): Unit {
        while (let Some(line) <- buffer.readUntil(b'\n')) {
            let linebs = line.bytes()
            if (linebs.isEmpty()) {
                break
            }

            if (isEmptyLine(linebs)) {
                continue
            }

            // header line
            let hKey = readHeaderKey(linebs)
            if (!hKey.isEmpty()) {
                _header.add(String.fromUtf8(hKey), String.fromUtf8(linebs[(hKey.size + 1)..]))
                _totalSize += hKey.size - 2
                continue
            }

            // end with dash line
            if (r.isDashLine(linebs)) {
                buffer.rewindLast()
                return
            }

            // body
            if (isEndLine(linebs)) {
                _contentSize += linebs.size - 2 // remove \r\n
                _totalSize += linebs.size - 2
                r._handler.onPart(this, linebs[..linebs.size - 2])
            } else {
                _contentSize += linebs.size
                _totalSize += linebs.size
                r._handler.onPart(this, linebs)
            }
        }
    }

    private func isEmptyLine(line: Array<Byte>): Bool {
        line.size == 2 && line[0] == b'\r' && line[1] == b'\n'
    }

    private func isEndLine(line: Array<Byte>): Bool {
        line.size > 2 && line[line.size - 2] == b'\r' && line[line.size - 1] == b'\n'
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

        if (let Some(h) <- _header.getFirst("Content-Disposition")) {
            let mt = JoyMediaType.parse(h)
            _dispositionParams = mt.params
            _isParseDisposition = true
        }
    }
}
