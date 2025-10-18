/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.session

/**
 * the memory session
 */
class MemorySession <: AbstractSession {
    private let _storage: JoySessionStorage
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
 * create memory session storage
 */
public class MemorySessionStorage <: AbstractSessionStorage {
    /*
     * @param maxLifetime: max life time. Default is 1hour.
     */
    public init(maxLifetime!: Duration = Duration.hour) {
        super(maxLifetime)
    }

    protected func createSession(sid: String): AbstractSession {
        MemorySession(sid, this)
    }
}
