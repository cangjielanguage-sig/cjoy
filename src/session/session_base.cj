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

import std.collection.concurrent.ConcurrentHashMap
import std.time.DateTime
import std.sync.Mutex
import stdx.encoding.json.stream.{JsonDeserializable, JsonSerializable}
import cjoy.utils.secureRandStr

/**
 * abstract base class for session implementations
 *
 * provides session data storage with thread-safe concurrent map,
 * tracks last access time for expiration, and supports invalidation
 */
public abstract class AbstractSession <: JoySession {
    let _sid: String
    let _data: ConcurrentHashMap<String, Any> = ConcurrentHashMap()
    var _lastAccessTime: DateTime = DateTime.now()
    var _invalidated: Bool = false

    /**
     * creates a new session
     *
     * @param sid: session identifier
     */
    public init(sid: String) {
        _sid = sid
    }

    /**
     * session identifier (read-only)
     *
     * @return: the session ID
     */
    public prop id: String {
        get() {
            _sid
        }
    }

    /**
     * whether session is invalidated (read-only)
     *
     * @return: true if session is invalidated
     */
    public prop isInvalidated: Bool {
        get() {
            _invalidated
        }
    }

    /**
     * stores a value in session data
     *
     * @param key: the key
     * @param value: the value to store, must be JSON serializable
     */
    public open func set<T>(key: String, value: T): Unit where T <: JsonSerializable & JsonDeserializable<T> {
        _data.add(key, value)
    }

    /**
     * retrieves a value from session data
     *
     * @param key: the key
     * @return: the value if exists, None otherwise
     */
    public open func get<T>(key: String): ?T where T <: JsonSerializable & JsonDeserializable<T> {
        (_data.get(key) ?? Option<T>.None) as T
    }

    /**
     * removes and returns a value from session data
     *
     * @param key: the key to remove
     * @return: the removed value if existed, None otherwise
     */
    public open func remove<T>(key: String): ?T where T <: JsonSerializable & JsonDeserializable<T> {
        (_data.remove(key) ?? Option<T>.None) as T
    }

    /**
     * persists session data to storage (override in subclasses)
     */
    public open func flush(): Unit {
    }

    /**
     * invalidates the session, marking it as no longer valid
     */
    public open func invalidate(): Unit {
        _invalidated = true
    }

    func updateAccessTime() {
        _lastAccessTime = DateTime.now()
    }
}

/**
 * abstract base class for session storage implementations
 *
 * manages a collection of sessions with automatic expiration cleanup,
 * provides thread-safe session creation, retrieval, and deletion
 */
public abstract class AbstractSessionStorage <: JoySessionStorage {
    let _sessions: ConcurrentHashMap<String, AbstractSession> = ConcurrentHashMap()
    let _lock: Mutex = Mutex()
    private let _maxLifetime: Duration

    /**
     * creates a new session storage
     *
     * @param maxLifetime: maximum session lifetime before expiration
     */
    public init(maxLifetime: Duration) {
        _maxLifetime = maxLifetime
    }

    /**
     * number of active sessions (read-only)
     *
     * @return: count of sessions in memory
     */
    public prop size: Int {
        get() {
            _sessions.size
        }
    }

    /**
     * deletes a session from storage
     *
     * @param sid: session ID to delete
     */
    public open func delete(sid: String): Unit {
        _sessions.remove(sid)
    }

    /**
     * gets existing session or creates new one
     *
     * @param sid: requested session ID (if not found, new random ID will be generated)
     * @param idLen: length for new session ID if creation is needed
     * @return: session instance (existing or newly created)
     */
    public func getOrCreate(sid: String, idLen: Int32): JoySession {
        var s = _sessions.get(sid)
        if (s.isNone()) {
            synchronized(_lock) {
                s = _sessions.get(sid)
                if (s.isNone()) {
                    // try load from storage
                    s = loadSession(sid)
                }
                if (let Some(ss) <- s) {
                    _sessions.add(ss.id, ss)
                    return ss
                } else {
                    // should create new session id when not existed
                    let newSid = secureRandStr(idLen)
                    let ns = createSession(newSid)
                    _sessions.add(newSid, ns)
                    return ns
                }
            }
        }

        let session = s.getOrThrow()
        session.updateAccessTime()
        session
    }

    /**
     * checks if session exists in memory
     *
     * @param sid: session ID to check
     * @return: true if session exists
     */
    public func exists(sid: String): Bool {
        _sessions.contains(sid)
    }

    /**
     * creates a new session instance (must be implemented by subclass)
     *
     * @param sid: session ID for the new session
     * @return: new session instance
     */
    protected func createSession(sid: String): AbstractSession

    /**
     * loads session from persistent storage (override in subclasses)
     *
     * @param sid: session ID to load
     * @return: loaded session if exists, None otherwise
     */
    protected open func loadSession(_: String): ?AbstractSession {
        None
    }

    /**
     * cleans up expired sessions from memory
     *
     * removes sessions that haven't been accessed within maxLifetime
     */
    public func clean() {
        let iter = _sessions.iterator()
        let now = DateTime.now()
        while (let Some(entry) <- iter.next()) {
            let (k, v) = entry
            if ((v._lastAccessTime + _maxLifetime) < now) {
                delete(k)
            }
        }
    }
}
