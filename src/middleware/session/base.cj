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

import std.collection.concurrent.ConcurrentHashMap
import std.time.DateTime
import std.sync.Mutex
import stdx.encoding.json.stream.{JsonDeserializable, JsonSerializable}

abstract sealed class AbstractSession <: JoySession {
    let _sid: String
    let _data: ConcurrentHashMap<String, Any> = ConcurrentHashMap()
    var _lastAccessTime: DateTime = DateTime.now()
    var _invalidated: Bool = false

    public init(sid: String) {
        _sid = sid
    }

    public prop id: String {
        get() {
            _sid
        }
    }

    public prop isInvalidated: Bool {
        get() {
            _invalidated
        }
    }

    public open func set<T>(key: String, value: T): Unit where T <: JsonSerializable & JsonDeserializable<T> {
        _data.add(key, value)
    }

    public open func get<T>(key: String): ?T where T <: JsonSerializable & JsonDeserializable<T> {
        (_data.get(key) ?? Option<T>.None) as T
    }

    public open func remove<T>(key: String): ?T where T <: JsonSerializable & JsonDeserializable<T> {
        (_data.remove(key) ?? Option<T>.None) as T
    }

    public open func flush(): Unit {
    }

    public open func invalidate(): Unit {
        _invalidated = true
    }

    func updateAccessTime() {
        _lastAccessTime = DateTime.now()
    }
}

protected abstract class AbstractSessionStorage <: JoySessionStorage {
    let _sessions: ConcurrentHashMap<String, AbstractSession> = ConcurrentHashMap()
    let _lock: Mutex = Mutex()
    private let _maxLifetime: Int

    /*
     * @param maxLifetime: max life time in seconds.
     */
    public init(maxLifetime: Int) {
        _maxLifetime = maxLifetime
    }

    public prop size: Int {
        get() {
            _sessions.size
        }
    }

    public open func delete(sid: String): Unit {
        _sessions.remove(sid)
    }

    public func getOrCreate(sid: String): JoySession {
        var s = _sessions.get(sid)
        if (s.isNone()) {
            synchronized(_lock) {
                s = _sessions.get(sid)
                if (s.isNone()) {
                    let ns = createSession(sid)
                    _sessions.add(sid, ns)
                    return ns
                }
            }
        }
        
        let session = s.getOrThrow()
        session.updateAccessTime()
        session
    }

    public func exists(sid: String): Bool {
        _sessions.contains(sid)
    }

    protected func createSession(sid: String): AbstractSession

    public func clean() {
        let iter = _sessions.iterator()
        let now = DateTime.now()
        while (let Some(entry) <- iter.next()) {
            let (k, v) = entry
            if (v._lastAccessTime.addSeconds(_maxLifetime) < now) {
                delete(k)
            }
        }
    }
}
