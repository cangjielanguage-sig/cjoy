/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.middleware.session

import std.collection.HashSet
import std.fs.{Path, File, Directory, exists, removeIfExists, canonicalize, OpenMode}
import std.sync.ReadWriteLock
import std.io.{ByteBuffer, readToEnd}
import stdx.encoding.json.stream.{JsonDeserializable, JsonSerializable, JsonReader, JsonWriter, JsonToken}

/**
 * the file session
 */
class FileSession <: AbstractSession {
    let _path: Path // root path
    private let _updates: HashSet<String> = HashSet()
    private let _removes: HashSet<String> = HashSet()
    private let _lock: ReadWriteLock = ReadWriteLock()

    public init(sid: String, path: Path) {
        super(sid)
        _path = path
    }

    public func set<T>(key: String, value: T): Unit where T <: JsonSerializable & JsonDeserializable<T> {
        synchronized(_lock.writeLock) {
            _updates.add(key)
        }
        super.set(key, value)
    }

    public func remove<T>(key: String): ?T where T <: JsonSerializable & JsonDeserializable<T> {
        synchronized(_lock.writeLock) {
            _removes.add(key)
        }
        super.remove(key)
    }

    public func get<T>(key: String): ?T where T <: JsonSerializable & JsonDeserializable<T> {
        var v = super.get<T>(key)
        if (v.isNone()) {
            // load from disk
            let p = _path.join(_sid).join(key)
            if (exists(p)) {
                try (file = File(p, OpenMode.Read)) {
                    var stream = ByteBuffer()
                    stream.write(readToEnd(file))
                    let reader = JsonReader(stream)
                    v = T.fromJson(reader)
                }
            }
        }
        v
    }

    public func flush(): Unit {
        // save to disk
        synchronized(_lock.readLock) {
            for (it in _updates) {
                if (let Some(d) <- ((_data.get(it) ?? Option<Any>.None) as JsonSerializable)) {
                    let p = _path.join(_sid).join(it)
                    try (file = File(p, OpenMode.Write)) {
                        let stream = ByteBuffer()
                        let writer = JsonWriter(stream)
                        writer.writeValue(d)
                        writer.flush()
                        file.write(stream.bytes())
                    }
                }
            }

            for (it in _removes) {
                let p = _path.join(_sid).join(it)
                removeIfExists(p)
            }
        }

        synchronized(_lock.writeLock) {
            _updates.clear()
            _removes.clear()
        }
    }
}

/**
 * create file session storage
 */
public class FileSessionStorage <: AbstractSessionStorage {
    let _path: Path // root path

    /*
     *
     * @param path: the sessoin store root path
     * @param maxLifetime: max life time in seconds. Default is 3600.
     */
    public init(path: String, maxLifetime!: Int = 3600) {
        super(maxLifetime)
        _path = canonicalize(Path(path))
        if (!exists(_path)) {
            Directory.create(_path, recursive: true)
        } else {
            try (file = File(_path, OpenMode.Read)) {
                if (!file.info.isDirectory()) {
                    throw IllegalArgumentException("${path} is not a directory")
                }
            }
        }
    }

    protected func createSession(sid: String): AbstractSession {
        FileSession(sid, _path)
    }

    public func delete(sid: String): Unit {
        super.delete(sid)
        removeIfExists(_path.join(sid), recursive: true)
    }
}
