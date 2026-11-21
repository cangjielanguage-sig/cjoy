/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.session

import std.collection.HashSet
import std.fs.{Path, File, FileInfo, Directory, exists as fsExists, removeIfExists as fsRemoveIfExists, canonicalize, OpenMode}
import std.sync.Mutex
import std.io.{ByteBuffer, readToEnd}
import stdx.encoding.json.stream.{JsonDeserializable, JsonSerializable, JsonReader, JsonWriter}

/**
 * 判断会话 ID / 键名是否可作为安全的文件路径片段。
 *
 * 拒绝路径分隔符、相对路径符号和空值，防止会话数据写到存储目录之外。
 *
 * @param name 待检查的名称
 * @return 安全返回 true，否则返回 false
 */
private func isValidPathPart(name: String): Bool {
    if (name.isEmpty() || name == "." || name == "..") {
        return false
    }
    for (c in name.toArray()) {
        if (c == b'/' || c == b'\\' || c == 0) {
            return false
        }
    }
    true
}

/**
 * 检查会话 ID / 键名是否可作为安全的文件路径片段。
 *
 * @param name 待检查的名称
 * @throws IllegalArgumentException 名称不安全时抛出
 */
private func checkPathPart(name: String): Unit {
    if (!isValidPathPart(name)) {
        throw IllegalArgumentException("Invalid session path component: ${name}")
    }
}

/**
 * 文件会话
 *
 * 将会话数据持久化到文件系统的会话实现
 */
class FileSession <: AbstractSession {
    let _path: Path // root path
    private let _updates: HashSet<String> = HashSet()
    private let _removes: HashSet<String> = HashSet()
    private let _lock: Mutex = Mutex()
    private let _storage: JoySessionStorage

    /**
     * 创建文件会话
     *
     * @param sid 会话 ID
     * @param path 会话存储根路径
     * @param storage 会话存储实例
     */
    public init(sid: String, path: Path, storage: JoySessionStorage) {
        super(sid)
        checkPathPart(sid)
        _path = path.join(sid)
        _storage = storage
        if (!fsExists(_path)) {
            Directory.create(_path, recursive: true)
        }
    }

    public func set<T>(key: String, value: T): Unit where T <: JsonSerializable & JsonDeserializable<T> {
        checkPathPart(key)
        synchronized(_lock) {
            // 同一键只保留一种待处理状态，避免刷新时新增的值被删除标记覆盖
            _updates.add(key)
            _removes.remove(key)
        }
        super.set(key, value)
    }

    public func remove<T>(key: String): ?T where T <: JsonSerializable & JsonDeserializable<T> {
        checkPathPart(key)
        // 先从磁盘加载，保证返回被删除的值，且缓存的是具体类型而非 Option
        get<T>(key)
        synchronized(_lock) {
            _removes.add(key)
            _updates.remove(key)
        }
        super.remove(key)
    }

    public func get<T>(key: String): ?T where T <: JsonSerializable & JsonDeserializable<T> {
        checkPathPart(key)
        var v = super.get<T>(key)
        if (v.isNone()) {
            var removed = false
            synchronized(_lock) {
                removed = _removes.contains(key)
            }
            // 本次请求已删除的键不再从磁盘“复活”
            if (removed) {
                return None
            }
            // load from disk
            let filePath = _path.join(key)
            if (fsExists(filePath)) {
                try (file = File(filePath, OpenMode.Read)) {
                    var stream = ByteBuffer()
                    stream.write(readToEnd(file))
                    let reader = JsonReader(stream)
                    // 以具体类型缓存，避免 Option 包装导致后续类型判断失败
                    super.set(key, T.fromJson(reader))
                }
                v = super.get<T>(key)
            }
        }
        v
    }

    public func flush(): Unit {
        // save to disk
        synchronized(_lock) {
            // 删除先于写入，若同一键因并发进入两个集合，最终保留新值
            for (it in _removes) {
                let p = _path.join(it)
                fsRemoveIfExists(p)
            }

            for (it in _updates) {
                if (let Some(d) <- ((_data.get(it) ?? Option<Any>.None) as JsonSerializable)) {
                    let filePath = _path.join(it)
                    try (file = File(filePath, OpenMode.Write)) {
                        let stream = ByteBuffer()
                        let writer = JsonWriter(stream)
                        writer.writeValue(d)
                        writer.flush()
                        file.write(stream.bytes())
                    }
                }
            }

            _updates.clear()
            _removes.clear()
        }
    }

    public func invalidate(): Unit {
        super.invalidate()
        _storage.delete(_sid)
    }
}

/**
 * 文件会话存储
 *
 * 将会话数据持久化到文件系统的存储实现
 */
public class FileSessionStorage <: AbstractSessionStorage {
    let _path: Path // 根路径

    /**
     * 创建 FileSessionStorage
     *
     * @param path 会话存储根路径
     * @param maxLifetime 最大存活时间，默认为 1 小时
     * @throws IllegalArgumentException 如果路径不是目录
     */
    public init(path: String, maxLifetime!: Duration = Duration.hour) {
        super(maxLifetime)
        let p = Path(path)
        if (!fsExists(p)) {
            _path = p
            Directory.create(_path, recursive: true)
        } else {
            _path = canonicalize(p)
            let fileInfo = FileInfo(_path)
            if (!fileInfo.isDirectory()) {
                throw IllegalArgumentException("${path} is not a directory")
            }
        }
    }

    protected func createSession(sid: String): AbstractSession {
        FileSession(sid, _path, this)
    }

    protected func loadSession(sid: String): ?AbstractSession {
        // 非法的会话 ID 视为不存在，让 getOrCreate 生成新的随机 ID
        if (isValidPathPart(sid) && fsExists(_path.join(sid))) {
            return FileSession(sid, _path, this)
        }
        None
    }

    public override func exists(sid: String): Bool {
        // 持久化到磁盘但尚未加载进内存的会话同样存在
        super.exists(sid) || (isValidPathPart(sid) && fsExists(_path.join(sid)))
    }

    public func delete(sid: String): Unit {
        super.delete(sid)
        if (isValidPathPart(sid)) {
            fsRemoveIfExists(_path.join(sid), recursive: true)
        }
    }
}
