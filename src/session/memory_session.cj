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

/**
 * 内存会话
 *
 * 将会话数据存储在内存中的会话实现
 */
class MemorySession <: AbstractSession {
    private let _storage: JoySessionStorage

    /**
     * 创建内存会话
     *
     * @param sid 会话 ID
     * @param storage 会话存储实例
     */
    public init(sid: String, storage: JoySessionStorage) {
        super(sid)
        _storage = storage
    }

    public func invalidate(): Unit {
        super.invalidate()
        _storage.delete(_sid)
    }
}

/**
 * 内存会话存储
 *
 * 将会话数据存储在内存中的存储实现
 */
public class MemorySessionStorage <: AbstractSessionStorage {
    /**
     * 创建内存会话存储
     *
     * @param maxLifetime 会话最大存活时间，默认为 1 小时
     */
    public init(maxLifetime!: Duration = Duration.hour) {
        super(maxLifetime)
    }

    protected func createSession(sid: String): AbstractSession {
        MemorySession(sid, this)
    }
}
