/*
 * Copyright (c) lanlingx 2025-present. All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.utils

import std.collection.{ArrayList, HashMap}

protected type MapToString = HashMap<String, ToString>

protected type ListToString = ArrayList<ToString>

protected interface MapListGetFunc<T> {
    func getString(name: T): ?String
    func getInt(name: T): ?Int64
    func getFloat(name: T): ?Float64
    func getBool(name: T): ?Bool
    func getList(name: T): ?ListToString
    func getMap(name: T): ?MapToString
}

extend MapToString <: MapListGetFunc<String> {
    public func getString(name: String): ?String {
        let x = this.get(name)
        match (x) {
            case Some(v) => v.toString()
            case _ => None
        }
    }

    public func getInt(name: String): ?Int64 {
        (this.get(name) ?? Option<ToString>.None) as Int64
    }

    public func getFloat(name: String): ?Float64 {
        (this.get(name) ?? Option<ToString>.None) as Float64
    }

    public func getBool(name: String): ?Bool {
        (this.get(name) ?? Option<ToString>.None) as Bool
    }

    public func getList(name: String): ?ListToString {
        (this.get(name) ?? Option<ToString>.None) as ListToString
    }

    public func getMap(name: String): ?MapToString {
        (this.get(name) ?? Option<ToString>.None) as MapToString
    }
}

extend ListToString <: MapListGetFunc<Int64>{
    public func getString(idx: Int64): ?String {
        let x = this.get(idx)
        match (x) {
            case Some(v) => v.toString()
            case _ => None
        }
    }

    public func getInt(idx: Int64): ?Int64 {
        (this.get(idx) ?? Option<ToString>.None) as Int64
    }

    public func getFloat(idx: Int64): ?Float64 {
        (this.get(idx) ?? Option<ToString>.None) as Float64
    }

    public func getBool(idx: Int64): ?Bool {
        (this.get(idx) ?? Option<ToString>.None) as Bool
    }

    public func getList(idx: Int64): ?ListToString {
        (this.get(idx) ?? Option<ToString>.None) as ListToString
    }

    public func getMap(idx: Int64): ?MapToString {
        (this.get(idx) ?? Option<ToString>.None) as MapToString
    }
}
