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

import std.collection.{ArrayList}
import std.io.{InputStream, BufferedInputStream, ByteBuffer, SeekPosition}

type ParseState = Int

const PS_HEADER: ParseState = 0
const PS_BODY: ParseState = 1
const PS_END: ParseState = 2

/**
 * 多部分内容解析器
 *
 * JoyMultiPartParser 负责根据多部分 MIME 规范解析多部分内容流
 */
public class JoyMultiPartParser <: Iterable<JoyMultiPart> {
    let _config: JoyMultiPartConfig
    let _handler: JoyMultiPartHandler
    private let _buffer: BufferReader
    private let _boundary: String

    private var _nl: Array<Byte> // \r\n
    private var _nldashBoundary: Array<Byte> // nl + "--boundary"
    private let _dashBoundaryDash: Array<Byte> // "--boundary--"
    private let _dashBoundary: Array<Byte> // "--boundary"

    private var _partsRead: Int = 0
    private let _parts = ArrayList<JoyMultiPart>()

    /**
     * 初始化 JoyMultiPartParser 的新实例
     *
     * @param config 多部分配置
     * @param handler 处理部分的处理器
     * @param inputStream 要解析的输入流
     * @param boundary 多部分解析的边界字符串
     */
    public init(config: JoyMultiPartConfig, handler: JoyMultiPartHandler, inputStream: InputStream, boundary: String) {
        _config = config
        _handler = handler
        _buffer = BufferReader(inputStream)
        _boundary = boundary

        let b = "\r\n--${boundary}--".toArray()
        _nl = b[..2]
        _nldashBoundary = b[0..b.size - 2]
        _dashBoundaryDash = b[2..]
        _dashBoundary = b[2..b.size - 2]
    }

    /**
     * 从输入流解析多部分内容
     *
     * 此方法从输入流读取并解析所有多部分部分。
     * 每个部分都由配置的处理器处理。
     */
    public func parseParts(): Unit {
        while (let Some(line) <- _buffer.readUntil(b'\n')) {
            var linebs = line.bytes()
            if (processLine(linebs)) {
                continue
            } else {
                return
            }
        }
    }

    /**
     * @throws MultiPartParseException
     */
    private func processLine(line: Array<Byte>): Bool {
        if (isFinalBoundary(line)) {
            return false
        }

        if (isBoundaryDelimiterLine(line)) {
            _partsRead += 1
            checkParts()
            let part = JoyMultiPart()
            part.read(this, _buffer)
            _parts.add(part)
            return true
        }

        if (_partsRead == 0) {
            return true // skip line
        }

        if (line == _nl) {
            return true
        }

        throw MultiPartParseException("unexpected line in parser, data : ${String.fromUtf8(line)}")
    }

    /**
     * @throws MultiPartLimitReachedException
     */
    private func checkParts() {
        if (_partsRead > _config.maxParts) {
            throw MultiPartLimitReachedException("parts limit reached, ${_partsRead} > ${_config.maxParts}")
        }
    }

    private func isFinalBoundary(line: Array<Byte>) {
        if (line.size < _dashBoundaryDash.size || line[.._dashBoundaryDash.size] != _dashBoundaryDash) {
            return false
        }

        var rest = line[_dashBoundaryDash.size..]
        rest = skipLWSPChar(rest)
        rest.size == 0 || rest == _nl
    }

    private func isBoundaryDelimiterLine(line: Array<Byte>): Bool {
        if (line.size < _dashBoundary.size || line[.._dashBoundary.size] != _dashBoundary) {
            return false
        }

        var rest = line[_dashBoundary.size..]
        rest = skipLWSPChar(rest)

        if (_partsRead == 0 && rest.size == 1 && rest[0] == b'\n') {
            _nl = _nl[1..]
            _nldashBoundary = _nldashBoundary[1..]
        }
        rest == _nl
    }

    func isDashLine(line: Array<Byte>): Bool {
        if (line.size < _dashBoundary.size) {
            return false
        }

        for (i in 0.._dashBoundary.size) {
            if (line[i] != _dashBoundary[i]) {
                return false
            }
        }
        return true
    }

    private func skipLWSPChar(b: Array<Byte>): Array<Byte> {
        var b_ = b
        while (b_.size > 0 && (b_[0] == b' ' || b_[0] == b'\t')) {
            b_ = b_[1..]
        }
        return b_
    }

    /**
     * 获取解析的多部分部分的迭代器
     *
     * @return JoyMultiPart 实例的迭代器
     */
    public func iterator(): Iterator<JoyMultiPart> {
        _parts.iterator()
    }

    /**
     * 根据名称获取特定部分
     *
     * @param name 要获取部分的名称
     * @return JoyMultiPart 实例，如果未找到则返回 None
     */
    public func getPart(name: String): ?JoyMultiPart {
        for (p in _parts) {
            if (p.name == name) {
                return p
            }
        }
        None
    }
}

class BufferReader {
    private let _buffer: BufferedInputStream<InputStream>
    private let _bb = ByteBuffer(1024)
    private var _rewind = false

    init(input: InputStream) {
        _buffer = BufferedInputStream(input)
    }

    func readUntil(r: Byte, maxSize!: Int = 1024): ?ByteBuffer {
        if (_rewind) {
            _rewind = false
            _bb.seek(SeekPosition.Begin(0))
            return _bb
        }

        _bb.clear()
        var count = 0
        while (let Some(b) <- _buffer.readByte()) {
            count++
            _bb.writeByte(b)
            if (b == r || count == maxSize) {
                return _bb
            }
        }
        None
    }

    func rewindLast(): Unit {
        _rewind = true
    }
}
