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

import stdx.encoding.json.stream.{JsonDeserializable, JsonSerializable}

/**
 * the http session
 */
public interface JoySession {
    /**
     * return the session id
     *
     * @return the session id
     */
    prop id: String

    /**
     * return the invalidated status
     *
     * @return true if the session is invalidated
     */
    prop isInvalidated: Bool

    /**
     * set value to given key in session.
     *
     * @param key: the session key
     * @param value: the session value
     */
    func set<T>(key: String, value: T): Unit where T <: JsonSerializable & JsonDeserializable<T>

    /**
     * get value by given key in session.
     *
     * @param key: the session key
     * @return the session value
     */
    func get<T>(key: String): ?T where T <: JsonSerializable & JsonDeserializable<T>

    /**
     * delete and return a key from session.
     *
     * @param key: the session key
     * @return the removed session value
     */
    func remove<T>(key: String): ?T where T <: JsonSerializable & JsonDeserializable<T>

    /**
     * flush to storage when handling http request finished
     *
     * @throws IOException if flush fails
     */
    func flush(): Unit

    /**
     * delete the session
     *
     * @throws IOException if delete fails
     */
    func invalidate(): Unit
}

/**
 * Store the sesson to storage
 */
public interface JoySessionStorage {
    /**
     * the size of sessions
     *
     * @return the number of sessions
     */
    prop size: Int

    /**
     * delete session in storage
     *
     * @param sid: the session id
     * @throws IOException if delete fails
     */
    func delete(sid: String): Unit

    /**
     * get or create new session
     *
     * @param sid: the session id
     * @param idLen: the session id length for new sessions
     * @return the session
     * @throws IOException if operation fails
     */
    func getOrCreate(sid: String, idLen: Int32): JoySession

    /**
     * exist or not
     *
     * @param sid: the session id
     * @return true if session exists
     */
    func exists(sid: String): Bool

    /**
     * clean expired sessions
     *
     * @throws IOException if clean fails
     */
    func clean(): Unit
}
