/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.jwt

import std.collection.{HashMap}
import stdx.encoding.json.stream.{JsonSerializable}

public type MapHeaders = HashMap<String, JsonSerializable>

public interface Headers {
    /**
     * 添加头信息
     *
     * @param name 头名称
     * @param value 头值
     * @return 头信息
     */
    func header(name: String, value: JsonSerializable): Headers

    /**
     * 获取头信息作为字符串
     *
     * @param name 头名称
     * @return 头值或 None
     */
    func getString(name: String): ?String

    /**
     * 获取头值
     *
     * @param name 头名称
     * @return 头值或 None
     */
    func getValue<T>(name: String): ?T

    /**
     * 获取算法头
     *
     * @return 算法
     */
    prop alg: String
}

extend MapHeaders <: Headers {
    public func header(name: String, value: JsonSerializable): Headers {
        add(name, value)
        this
    }

    public func getString(name: String): ?String {
        (get(name) ?? Option<JsonSerializable>.None) as String
    }

    public func getValue<T>(name: String): ?T {
        (get(name) ?? Option<JsonSerializable>.None) as T
        None
    }

    public prop alg: String {
        get() {
            getString("alg") ?? ""
        }
    }
}
