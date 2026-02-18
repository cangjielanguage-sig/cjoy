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
 * 处理多部分内容的接口
 */
public interface JoyMultiPartHandler {
    /**
     * 读取多部分内容时调用
     *
     * @param part 正在处理的多部分
     * @param data 当前部分的数据字节
     */
    func onPart(part: JoyMultiPart, data: Array<Byte>): Unit
}

/**
 * 使用函数回调的 MultiPart 处理器实现
 */
public class JoyMultiPartFuncHandler <: JoyMultiPartHandler {
    /**
     * 初始化 JoyMultiPartFuncHandler 的新实例
     *
     * @param handler 处理部分时调用的函数
     */
    public JoyMultiPartFuncHandler(let handler: (JoyMultiPart, Array<Byte>) -> Unit) {}

    public func onPart(part: JoyMultiPart, data: Array<Byte>): Unit {
        handler(part, data)
    }
}

/**
 * 基于内存的多部分处理器，用于在内存中缓存部分
 */
class JoyMemoryMultiPartHandler <: JoyMultiPartHandler & Resource {
    private let _cache = HashMap<String, ByteBuffer>()
    private var _isClosed = false
    private let _config: JoyMultiPartConfig
    private var _size: Int = 0

    /**
     * 初始化 JoyMemoryMultiPartHandler 的新实例
     *
     * @param config 多部分配置
     */
    init(config: JoyMultiPartConfig) {
        _config = config
    }

    /**
     * 读取多部分内容时调用
     *
     * @param part 正在处理的多部分
     * @param data 当前部分的数据字节
     * @throws MultiPartLimitReachedException 如果达到内存大小限制
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
     * 根据名称获取部分的内容
     *
     * @param name 部分的名称
     * @return 部分的 ByteBuffer 内容，如果未找到则返回 None
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
 * 基于磁盘的多部分处理器，用于将部分保存到临时文件
 */
class JoyDiskMultiPartHandler <: JoyMultiPartHandler & Resource {
    private let _cache = HashMap<String, File>()
    private var _isClosed = false
    private let _config: JoyMultiPartConfig
    private let _tempPath: Path
    private var _size: Int = 0

    /**
     * 初始化 JoyDiskMultiPartHandler 的新实例
     *
     * @param config 多部分配置
     */
    init(config: JoyMultiPartConfig) {
        _config = config
        _tempPath = Path(_config.fileCacheDir).normalize()
        if (!exists(_tempPath)) {
            Directory.create(_tempPath, recursive: true)
        }
    }

    /**
     * 读取多部分内容时调用
     *
     * @param part 正在处理的多部分
     * @param data 当前部分的数据字节
     * @throws MultiPartLimitReachedException 如果达到文件大小限制
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
     * 根据名称获取部分的文件引用
     *
     * @param name 部分的名称
     * @return File 引用，如果未找到则返回 None
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
