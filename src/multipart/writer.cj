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
 * 多部分内容写入器
 *
 * JoyMultiPartWriter 负责根据多部分 MIME 规范将多部分内容写入输出流
 */
public class JoyMultiPartWriter <: Resource {
    private let _buffer: BufferedOutputStream<OutputStream>
    private let _boundary: String
    private var _lastPart: ?TmpPart = None
    private var _closed: Bool = false

    /**
     * 初始化 JoyMultiPartWriter 的新实例
     *
     * @param output 要写入的输出流
     * @param boundry 可选的边界字符串（如果未提供将自动生成）
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
     * 获取边界字符串
     *
     * @return 边界字符串
     */
    public prop boundary: String {
        get() {
            _boundary
        }
    }

    /**
     * 获取多部分表单数据的 Content-Type 头值
     *
     * @return Content-Type 字符串
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
     * 使用指定的 header 创建新部分
     *
     * @param headers 新部分的 header
     * @return 当前 JoyMultiPartWriter 实例以支持方法链式调用
     * @throws IllegalArgumentException 如果写入器已关闭
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
     * 向当前部分写入数据
     *
     * @param bs 要写入的数据
     * @return 当前 JoyMultiPartWriter 实例以支持方法链式调用
     * @throws IllegalArgumentException 如果当前没有活动部分或部分已关闭
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
     * 使用指定的字段名、文件名和内容类型创建文件部分
     *
     * @param fieldname 部分的字段名
     * @param filename 文件名
     * @param contentType 内容类型（默认为 application/octet-stream）
     * @return 当前 JoyMultiPartWriter 实例以支持方法链式调用
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
     * 使用指定的字段名创建表单字段部分
     *
     * @param fieldname 部分的字段名
     * @return 当前 JoyMultiPartWriter 实例以支持方法链式调用
     */
    public func createFormField(fieldname: String): JoyMultiPartWriter {
        let headers = HttpHeaders()
        headers.add(JoyHttpConsts.HEADER_CONTENT_DISPOSITION, "form-data; name=\"${escapeQuotes(fieldname)}\"")
        createPart(headers)
    }

    /**
     * 使用指定内容写入文件部分
     *
     * @param fieldname 部分的字段名
     * @param filename 文件名
     * @param fileContent 文件内容字节
     * @param contentType 内容类型（默认为 application/octet-stream）
     * @return 当前 JoyMultiPartWriter 实例以支持方法链式调用
     */
    public func writeFile(fieldname: String, filename: String, fileContent: Array<Byte>,
        contentType!: String = JoyHttpConsts.MIME_APP_OCTET_STREAM): JoyMultiPartWriter {
        createFromFile(fieldname, filename, contentType: contentType)
        writePartData(fileContent)
    }

    /**
     * 使用指定值写入表单字段部分
     *
     * @param fieldname 部分的字段名
     * @param value 字段值
     * @return 当前 JoyMultiPartWriter 实例以支持方法链式调用
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
     * 关闭写入器并将所有数据刷新到输出流
     *
     * 此方法写入最终边界以表示多部分内容的结束，
     * 并将所有缓冲数据刷新到输出流。
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
