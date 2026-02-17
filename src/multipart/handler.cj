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

import std.io.ByteBuffer
import std.fs.{File, Path, Directory, OpenMode, exists, removeIfExists}
import std.collection.HashMap

/**
 * The interface to process multipart content
 */
public interface JoyMultiPartHandler {
    /**
     * Called when reading multipart content
     *
     * @param part The multipart part being processed
     * @param data The data bytes of the current part
     */
    func onPart(part: JoyMultiPart, data: Array<Byte>): Unit
}

/**
 * MultiPart handler implementation with function callback
 */
public class JoyMultiPartFuncHandler <: JoyMultiPartHandler {
    /**
     * Initializes a new instance of JoyMultiPartFuncHandler
     *
     * @param handler The function to call when processing parts
     */
    public JoyMultiPartFuncHandler(let handler: (JoyMultiPart, Array<Byte>) -> Unit) {}

    public func onPart(part: JoyMultiPart, data: Array<Byte>): Unit {
        handler(part, data)
    }
}

/**
 * Memory-based multipart handler for caching parts in memory
 */
class JoyMemoryMultiPartHandler <: JoyMultiPartHandler & Resource {
    private let _cache = HashMap<String, ByteBuffer>()
    private var _isClosed = false
    private let _config: JoyMultiPartConfig
    private var _size: Int = 0

    /**
     * Initializes a new instance of JoyMemoryMultiPartHandler
     *
     * @param config The multipart configuration
     */
    init(config: JoyMultiPartConfig) {
        _config = config
    }

    /**
     * Called when reading multipart content
     *
     * @param part The multipart part being processed
     * @param data The data bytes of the current part
     * @throws MultiPartLimitReachedException if memory size limit is reached
     */
    public func onPart(part: JoyMultiPart, data: Array<Byte>): Unit {
        _size += data.size
        if (_size > _config.maxMemSize.value) {
            throw MultiPartLimitReachedException("memory size limit reached, ${_size} > ${_config.maxMemSize.value}")
        }

        if (let Some(c) <- _cache.get(part.name)) {
            c.write(data)
            return
        }

        let buffer = ByteBuffer()
        buffer.write(data)
        part._memoryHandler = this
        _cache.add(part.name, buffer)
    }

    /**
     * Gets the content of a part by name
     *
     * @param name The name of the part
     * @return The content of the part as ByteBuffer or None if not found
     */
    func getContent(name: String): ?ByteBuffer {
        _cache.get(name)
    }

    public func isClosed(): Bool {
        _isClosed
    }

    public func close(): Unit {
        if (_isClosed) {
            return
        }
        for ((k, v) in _cache) {
            v.clear()
        }
        _cache.clear()
        _isClosed = true
    }
}

/**
 * Disk-based multipart handler for saving parts to temporary files
 */
class JoyDiskMultiPartHandler <: JoyMultiPartHandler & Resource {
    private let _cache = HashMap<String, File>()
    private var _isClosed = false
    private let _config: JoyMultiPartConfig
    private let _tempPath: Path
    private var _size: Int = 0

    /**
     * Initializes a new instance of JoyDiskMultiPartHandler
     *
     * @param config The multipart configuration
     */
    init(config: JoyMultiPartConfig) {
        _config = config
        _tempPath = Path(_config.fileCacheDir).normalize()
        if (!exists(_tempPath)) {
            Directory.create(_tempPath, recursive: true)
        }
    }

    /**
     * Called when reading multipart content
     *
     * @param part The multipart part being processed
     * @param data The data bytes of the current part
     * @throws MultiPartLimitReachedException if file size limit is reached
     */
    public func onPart(part: JoyMultiPart, data: Array<Byte>): Unit {
        _size += data.size
        if (_size > _config.maxFileSize.value) {
            throw MultiPartLimitReachedException("file size limit reached, ${_size} > ${_config.maxFileSize.value}")
        }

        if (let Some(f) <- _cache.get(part.name)) {
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
            _cache.add(part.name, file)
        } catch (_: Exception) {
            file.close()
        }
    }

    /**
     * Gets the file reference of a part by name
     *
     * @param name The name of the part
     * @return The File reference or None if not found
     */
    func getFile(name: String): ?File {
        _cache.get(name)
    }

    public func isClosed(): Bool {
        _isClosed
    }

    public func close(): Unit {
        if (_isClosed) {
            return
        }
        for ((k, v) in _cache) {
            if (!v.isClosed()) {
                v.close()
            }
            removeIfExists(v.info.path, recursive: false)
        }
        _cache.clear()
        _isClosed = true
    }
}
