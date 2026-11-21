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
 * 会话实现的抽象基类
 *
 * 提供线程安全的并发映射存储会话数据，
 * 跟踪最后访问时间以便过期处理，并支持失效操作
 */
public abstract class AbstractSession <: JoySession {
    let _sid: String
    let _data: ConcurrentHashMap<String, Any> = ConcurrentHashMap()
    var _lastAccessTime: DateTime = DateTime.now()
    var _invalidated: Bool = false

    /**
     * 创建新会话
     *
     * @param sid 会话标识符
     */
    public init(sid: String) {
        _sid = sid
    }

    /**
     * 会话标识符（只读）
     *
     * @return 会话 ID
     */
    public prop id: String {
        get() {
            _sid
        }
    }

    /**
     * 会话是否已失效（只读）
     *
     * @return 如果会话已失效则返回 true
     */
    public prop isInvalidated: Bool {
        get() {
            _invalidated
        }
    }

    /**
     * 在会话数据中存储值
     *
     * @param key 键
     * @param value 要存储的值，必须是 JSON 可序列化的
     */
    public open func set<T>(key: String, value: T): Unit where T <: JsonSerializable & JsonDeserializable<T> {
        _data.add(key, value)
    }

    /**
     * 从会话数据中检索值
     *
     * @param key 键
     * @return 值（如果存在），否则返回 None
     */
    public open func get<T>(key: String): ?T where T <: JsonSerializable & JsonDeserializable<T> {
        (_data.get(key) ?? Option<T>.None) as T
    }

    /**
     * 从会话数据中删除并返回值
     *
     * @param key 要删除的键
     * @return 删除的值（如果存在），否则返回 None
     */
    public open func remove<T>(key: String): ?T where T <: JsonSerializable & JsonDeserializable<T> {
        (_data.remove(key) ?? Option<T>.None) as T
    }

    /**
     * 将会话数据持久化到存储中（子类可以重写）
     */
    public open func flush(): Unit {
    }

    /**
     * 使会话失效，标记为不再有效
     */
    public open func invalidate(): Unit {
        _invalidated = true
    }

    func updateAccessTime() {
        _lastAccessTime = DateTime.now()
    }
}

/**
 * 会话存储实现的抽象基类
 *
 * 管理会话集合并自动清理过期会话，
 * 提供线程安全的会话创建、检索和删除
 */
public abstract class AbstractSessionStorage <: JoySessionStorage {
    let _sessions: ConcurrentHashMap<String, AbstractSession> = ConcurrentHashMap()
    let _lock: Mutex = Mutex()
    private let _maxLifetime: Duration

    /**
     * 创建新的会话存储
     *
     * @param maxLifetime 会话过期前的最大存活时间
     */
    public init(maxLifetime: Duration) {
        _maxLifetime = maxLifetime
    }

    /**
     * 活动会话数量（只读）
     *
     * @return 内存中的会话计数
     */
    public prop size: Int {
        get() {
            _sessions.size
        }
    }

    /**
     * 从存储中删除会话
     *
     * @param sid 要删除的会话 ID
     */
    public open func delete(sid: String): Unit {
        _sessions.remove(sid)
    }

    /**
     * 获取现有会话或创建新会话
     *
     * @param sid 请求的会话 ID（如果未找到，将生成新的随机 ID）
     * @param idLen 需要创建新会话 ID 时的长度
     * @return 会话实例（现有或新创建的）
     */
    public func getOrCreate(sid: String, idLen: Int32): JoySession {
        var s = _sessions.get(sid)
        if (s.isNone()) {
            synchronized(_lock) {
                s = _sessions.get(sid)
                if (s.isNone()) {
                    // 尝试从存储加载
                    s = loadSession(sid)
                }
                if (let Some(ss) <- s) {
                    _sessions.add(ss.id, ss)
                    return ss
                } else {
                    // 不存在时应创建新的会话 ID
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
     * 检查会话是否在内存中存在
     *
     * @param sid 要检查的会话 ID
     * @return 如果会话存在返回 true
     */
    public open func exists(sid: String): Bool {
        _sessions.contains(sid)
    }

    /**
     * 创建新的会话实例（必须由子类实现）
     *
     * @param sid 新会话的会话 ID
     * @return 新的会话实例
     */
    protected func createSession(sid: String): AbstractSession

    /**
     * 从持久存储加载会话（子类可以重写）
     *
     * @param sid 要加载的会话 ID
     * @return 加载的会话（如果存在），否则返回 None
     */
    protected open func loadSession(_: String): ?AbstractSession {
        None
    }

    /**
     * 清理内存中的过期会话
     *
     * 删除在 maxLifetime 内未访问的会话
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
