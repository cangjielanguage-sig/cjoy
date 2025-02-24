/*
 * Copyright (c) lanlingx 2025-present. All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.multipart

import std.collection.HashMap
import std.io.ByteBuffer

public class MultipartParseException <: Exception {
    public init(message: String) {
        super(message)
    }
}

public class MultipartLimitReachedException <: Exception {
    public init(message: String) {
        super(message)
    }
}

public struct JoyDataSize {
    private var _value: UInt
    const init(value: UInt) {
        _value = value
    }

    public static const KB: JoyDataSize = JoyDataSize(1 << 10)
    public static const MB: JoyDataSize = JoyDataSize(1 << 20)
    public static const GB: JoyDataSize = JoyDataSize(1 << 30)

    public operator func *(r: UInt): JoyDataSize {
        JoyDataSize(_value * r)
    }

    public prop value: UInt {
        get() {
            _value
        }
    }
}

public struct JoyMultiPartConfig {
    public var maxParts: UInt = 10
    public var maxHeaders: UInt = 5
    public var maxMemSize: JoyDataSize = JoyDataSize.MB * 32
    public var maxMemFileSize: JoyDataSize = JoyDataSize.MB * 32
}
