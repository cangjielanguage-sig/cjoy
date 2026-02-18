/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */
package cjoy.httpx

import std.collection.concurrent.LinkedBlockingQueue
import std.collection.{ArrayList}
import std.io.{InputStream, StringReader}

enum StreamData {
    | Bytes(Array<Byte>)
    | EOF
    | Error(String)
}

/**
 * HTTP 字节流，支持逐行迭代和原始字节读取
 */
public class JoyHttpStream <: Iterator<String> & InputStream {
    private let _queue = LinkedBlockingQueue<StreamData>()
    private let _byteBuffer = ArrayList<Byte>()
    private let _closeFn: Option<() -> Unit>
    private var _finished = false
    private var _reader: Option<StringReader<JoyHttpStream>> = None

    init(closeFn!: Option<() -> Unit> = None) {
        _closeFn = closeFn
    }

    /**
     * 从流中读取字节
     *
     * @return 如果成功读取字节返回 true，如果到达文件末尾返回 false
     * @throws Exception 如果接收到错误
     */
    private func readBytes(): Bool {
        if (_finished) {
            return false
        }
        match (_queue.remove()) {
            case Error(text) => throw Exception("Http byte stream error, ${text}")
            case EOF =>
                _finished = true
                return false
            case Bytes(bytes) =>
                _byteBuffer.add(all: bytes)
                return true
        }
    }

    /**
     * 从流中读取字节
     *
     * @param buffer 要读取到的字节缓冲区
     * @return 读取的字节数
     */
    public func read(buffer: Array<Byte>): Int64 {
        if (_byteBuffer.isEmpty() && !this.readBytes()) {
            return 0
        }

        let len = if (_byteBuffer.size <= buffer.size) {
            _byteBuffer.size
        } else {
            buffer.size
        }

        unsafe {
            let bytes = _byteBuffer.getRawArray()
            bytes.copyTo(buffer, 0, 0, len)
        }

        if (_byteBuffer.size == len) {
            _byteBuffer.clear()
        } else {
            _byteBuffer.remove(0..len)
        }
        return len
    }

    private prop reader: StringReader<JoyHttpStream> {
        get() {
            if (let Some(r) <- this._reader) {
                return r
            } else {
                let r = StringReader(this)
                this._reader = r
                return r
            }
        }
    }

    /**
     * 从流中读取下一行
     *
     * @return 行字符串，如果到达文件末尾返回 None
     */
    public func next(): Option<String> {
        return this.reader.readln()
    }

    /**
     * 将字节数据放入流
     *
     * @param data 字节数据
     */
    public func put(data: Array<Byte>): Unit {
        _queue.add(StreamData.Bytes(data))
    }

    /**
     * 标记文件结束
     */
    public func markEOF(): Unit {
        _queue.add(StreamData.EOF)
    }

    /**
     * 在流上标记错误
     *
     * @param err 错误消息
     */
    public func markError(err: String): Unit {
        _queue.add(StreamData.Error(err))
    }

    /**
     * 关闭流
     */
    public func close(): Unit {
        this.markEOF()
        if (let Some(fn) <- _closeFn) {
            fn()
        }
    }
}
