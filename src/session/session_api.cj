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
 * HTTP 会话
 */
public interface JoySession {
    /**
     * 返回会话 ID
     *
     * @return 会话 ID
     */
    prop id: String

    /**
     * 返回失效状态
     *
     * @return 如果会话已失效返回 true
     */
    prop isInvalidated: Bool

    /**
     * 在会话中设置键值对。
     *
     * @param key 会话键
     * @param value 会话值
     */
    func set<T>(key: String, value: T): Unit where T <: JsonSerializable & JsonDeserializable<T>

    /**
     * 从会话中获取指定键的值。
     *
     * @param key 会话键
     * @return 会话值
     */
    func get<T>(key: String): ?T where T <: JsonSerializable & JsonDeserializable<T>

    /**
     * 从会话中删除并返回指定键的值。
     *
     * @param key 会话键
     * @return 被删除的会话值
     */
    func remove<T>(key: String): ?T where T <: JsonSerializable & JsonDeserializable<T>

    /**
     * 处理 HTTP 请求完成后刷新到存储
     *
     * @throws IOException 如果刷新失败
     */
    func flush(): Unit

    /**
     * 删除会话
     *
     * @throws IOException 如果删除失败
     */
    func invalidate(): Unit
}

/**
 * 将会话存储到存储介质
 */
public interface JoySessionStorage {
    /**
     * 会话数量
     *
     * @return 会话数量
     */
    prop size: Int

    /**
     * 删除存储中的会话
     *
     * @param sid 会话 ID
     * @throws IOException 如果删除失败
     */
    func delete(sid: String): Unit

    /**
     * 获取或创建新会话
     *
     * @param sid 会话 ID
     * @param idLen 新会话的会话 ID 长度
     * @return 会话
     * @throws IOException 如果操作失败
     */
    func getOrCreate(sid: String, idLen: Int32): JoySession

    /**
     * 是否存在
     *
     * @param sid 会话 ID
     * @return 如果会话存在返回 true
     */
    func exists(sid: String): Bool

    /**
     * 清理过期会话
     *
     * @throws IOException 如果清理失败
     */
    func clean(): Unit
}
