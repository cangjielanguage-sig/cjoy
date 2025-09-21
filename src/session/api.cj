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

import stdx.encoding.json.stream.{JsonDeserializable, JsonSerializable}

/**
 * the http session
 */
public interface JoySession {
    /**
     * return the session id
     */
    prop id: String

    /**
     * return the invalidated status
     */
    prop isInvalidated: Bool

    /**
     * set value to given key in session.
     */
    func set<T>(key: String, value: T): Unit where T <: JsonSerializable & JsonDeserializable<T>

    /**
     * get value by given key in session.
     */
    func get<T>(key: String): ?T where T <: JsonSerializable & JsonDeserializable<T>

    /**
     * delete and retune a key from session.
     */
    func remove<T>(key: String): ?T where T <: JsonSerializable & JsonDeserializable<T>

    /**
     * flush to storage when handling http request finished
     */
    func flush(): Unit

    /**
     * delete the session
     */
    func invalidate(): Unit
}

/**
 * Store the sesson to storage
 */
public interface JoySessionStorage {
    /**
     * the size of sessions
     */
    prop size: Int

    /**
     * delete session in storage
     */
    func delete(sid: String): Unit

    /**
     * get or create new session
     */
    func getOrCreate(sid: String, idLen: Int32): JoySession

    /**
     * exist or not
     */
    func exists(sid: String): Bool

    /**
     * clean expired sessions
     */
    func clean(): Unit
}
