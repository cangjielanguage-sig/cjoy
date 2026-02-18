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
import std.fs.{Path, File, FileInfo, Directory, exists, removeIfExists, canonicalize, OpenMode}
import std.sync.Mutex
import std.io.{ByteBuffer, readToEnd}
import stdx.encoding.json.stream.{JsonDeserializable, JsonSerializable, JsonReader, JsonWriter}

/**
 * 文件会话
 */
class FileSession <: AbstractSession {
    let _path: Path // root path
    private let _updates: HashSet<String> = HashSet()
    private let _removes: HashSet<String> = HashSet()
    private let _lock: Mutex = Mutex()
    private let _storage: JoySessionStorage

    public init(sid: String, path: Path, storage: JoySessionStorage) {
        super(sid)
        _path = path.join(sid)
        _storage = storage
        if (!exists(_path)) {
            Directory.create(_path, recursive: true)
        }
    }

    public func set<T>(key: String, value: T): Unit where T <: JsonSerializable & JsonDeserializable<T> {
        synchronized(_lock) {
            _updates.add(key)
        }
        super.set(key, value)
    }

    public func remove<T>(key: String): ?T where T <: JsonSerializable & JsonDeserializable<T> {
        synchronized(_lock) {
            _removes.add(key)
        }
        super.remove(key)
    }

    public func get<T>(key: String): ?T where T <: JsonSerializable & JsonDeserializable<T> {
        var v = super.get<T>(key)
        if (v.isNone()) {
            // load from disk
            let filePath = _path.join(key)
            if (exists(filePath)) {
                try (file = File(filePath, OpenMode.Read)) {
                    var stream = ByteBuffer()
                    stream.write(readToEnd(file))
                    let reader = JsonReader(stream)
                    v = T.fromJson(reader)
                    super.set(key, v)
                }
            }
        }
        v
    }

    public func flush(): Unit {
        // save to disk
        synchronized(_lock) {
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

            for (it in _removes) {
                let p = _path.join(it)
                removeIfExists(p)
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
        if (!exists(p)) {
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
        if (exists(_path.join(sid))) {
            return FileSession(sid, _path, this)
        }
        None
    }

    public func delete(sid: String): Unit {
        super.delete(sid)
        removeIfExists(_path.join(sid), recursive: true)
    }
}
