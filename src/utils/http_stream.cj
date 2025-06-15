/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.utils

import std.collection.concurrent.LinkedBlockingQueue
import std.collection.{HashMap, ArrayList}
import std.io.{InputStream, StringReader}

// modified from CangjieMagic

enum StreamData {
    | Bytes(Array<Byte>)
    | EOF
    | Error
}

protected class HttpStream <: Iterator<String> & InputStream {
    let _queue = LinkedBlockingQueue<StreamData>()
    let _byteBuffer = ArrayList<Byte>()
    private let _closeFn: Option<() -> Unit>
    var _finished = false
    var _reader: Option<StringReader<HttpStream>> = None

    init(closeFn!: Option<() -> Unit> = None) {
        _closeFn = closeFn
    }

    private func readBytes(): Bool {
        if (_finished) {
            return false
        }
        match (_queue.remove()) {
            case Error => throw Exception("Http byte stream error")
            case EOF =>
                _finished = true
                return false
            case Bytes(bytes) =>
                _byteBuffer.add(all: bytes)
                return true
        }
    }

    public override func read(buffer: Array<Byte>): Int64 {
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

    private prop reader: StringReader<HttpStream> {
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

    public override func next(): Option<String> {
        return this.reader.readln()
    }

    public func put(data: Array<Byte>): Unit {
        _queue.add(StreamData.Bytes(data))
    }

    public func markEOF(): Unit {
        _queue.add(StreamData.EOF)
    }

    public func markError(): Unit {
        _queue.add(StreamData.Error)
    }

    public func close(): Unit {
        this.markEOF()
        if (let Some(fn) <- _closeFn) {
            fn()
        }
    }
}
