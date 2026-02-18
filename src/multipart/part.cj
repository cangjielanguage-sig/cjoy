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
 * 表示多部分内容部分
 *
 * JoyMultiPart 实例包含多部分请求单个部分的所有信息，
 * 包括头信息、内容类型、名称、文件名和内容数据。
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
     * 从部分获取特定头信息的值
     *
     * @param name 要检索的头信息名称
     * @return 头值，如果未找到则返回 None
     */
    public func header(name: String): ?String {
        _headers.getFirst(name)
    }

    /**
     * 获取部分的 Content-Type 头信息
     *
     * @return Content-Type 字符串
     */
    public prop contentType: String {
        get() {
            _headers.getFirst("Content-Type").getOrThrow()
        }
    }

    /**
     * 从 Content-Disposition 头信息获取部分名称
     *
     * @return 部分名称
     */
    public prop name: String {
        get() {
            parseContentDisposition()
            _dispositionParams.get("name") ?? ""
        }
    }

    /**
     * 为测试目的设置名称
     */
    func setName(name: String): Unit {
        _dispositionParams["name"] = name
    }

    /**
     * 从 Content-Disposition 头信息获取部分文件名
     *
     * @return 文件名，如果不是文件部分则返回空字符串
     */
    public prop fileName: String {
        get() {
            parseContentDisposition()
            _dispositionParams.get("filename") ?? ""
        }
    }

    /**
     * 从内存获取部分的文本内容
     *
     * @return 文本内容字符串，如果不可用则返回 None
     */
    public prop text: ?String {
        get() {
            _memoryHandler?.getContent(this.name).map({bb => String.fromUtf8(bb.bytes())}) ?? None
        }
    }

    /**
     * 从磁盘缓存获取部分的文件引用
     *
     * @return File 实例，如果不可用则返回 None
     */
    public prop file: ?File {
        get() {
            _diskHandler?.getFile(this.name) ?? None
        }
    }

    /**
     * 从内存获取部分的文件内容
     *
     * @return 文件内容为 ByteBuffer，如果不可用则返回 None
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
