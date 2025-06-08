/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.multipart

import std.io.ByteBuffer
import std.fs.{File, Path, Directory, OpenMode, exists, removeIfExists}
import std.collection.HashMap

/**
 * the interface to process mutli part content
 */
public interface JoyMultiPartHandler {
    /**
     * call the function when read mutli part content
     */
    func onPart(part: JoyMultiPart, data: Array<Byte>): Unit
}

public class JoyMultiPartFuncHandler <: JoyMultiPartHandler {
    public JoyMultiPartFuncHandler(let handler: (JoyMultiPart, Array<Byte>) -> Unit) {}

    public func onPart(part: JoyMultiPart, data: Array<Byte>): Unit {
        this.onPart(part, data)
    }
}

class JoyMemoryMultiPartHandler <: JoyMultiPartHandler & Resource {
    private let cache = HashMap<String, ByteBuffer>()
    private var _isClosed = true
    private let _config: JoyMultiPartConfig
    private var _size: Int = 0

    init(config: JoyMultiPartConfig) {
        _config = config
    }

    public func onPart(part: JoyMultiPart, data: Array<Byte>): Unit {
        _size += data.size
        if (_size > _config.maxMemSize.value) {
            throw MultiPartLimitReachedException("memory size limit reached, ${_size} > ${_config.maxMemSize.value}")
        }

        if (let Some(c) <- cache.get(part.name)) {
            c.write(data)
            return
        }

        let buffer = ByteBuffer()
        buffer.write(data)
        part._memoryHandler = this
        cache.add(part.name, buffer)
    }

    func getContent(name: String): ?ByteBuffer {
        cache.get(name)
    }

    public func isClosed(): Bool {
        _isClosed
    }

    public func close() {
        if (_isClosed) {
            return
        }
        for ((k, v) in cache) {
            v.clear()
        }
        cache.clear()
        _isClosed = true
    }
}

class JoyDiskMultiPartHandler <: JoyMultiPartHandler & Resource {
    private let cache = HashMap<String, File>()
    private var _isClosed = true
    private let _config: JoyMultiPartConfig
    private let _tempPath: Path
    private var _size: Int = 0

    init(config: JoyMultiPartConfig) {
        _config = config
        _tempPath = Path(_config.fileCacheDir).normalize()
        if (!exists(_tempPath)) {
            Directory.create(_tempPath, recursive: true)
        }
    }

    public func onPart(part: JoyMultiPart, data: Array<Byte>): Unit {
        _size += data.size
        if (_size > _config.maxFileSize.value) {
            throw MultiPartLimitReachedException("file size limit reached, ${_size} > ${_config.maxFileSize.value}")
        }

        if (let Some(f) <- cache.get(part.name)) {
            f.write(data)
            f.flush()
            return
        }

        let fileName = _tempPath.join(part.fileName)
        let file = File(fileName, OpenMode.ReadWrite)
        try {
            file.write(data)
            file.flush()
            part._diskHandler = this
            cache.add(part.name, file)
        } catch (_: Exception) {
            file.close()
        }
    }

    func getFile(name: String): ?File {
        cache.get(name)
    }

    public func isClosed(): Bool {
        _isClosed
    }

    public func close() {
        if (_isClosed) {
            return
        }
        for ((k, v) in cache) {
            if (!v.isClosed()) {
                v.close()
            }
            removeIfExists(v.info.path, recursive: false)
        }
        cache.clear()
        _isClosed = true
    }
}
