/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.multipart

/**
 * Exception thrown when multi part parsing fails
 */
public class MultiPartParseException <: Exception {
    public init(message: String) {
        super(message)
    }
}

/**
 * multipart size limit reached exception
 */
public class MultiPartLimitReachedException <: Exception {
    public init(message: String) {
        super(message)
    }
}

/**
 * data size constants
 */
public struct JoyDataSize {
    private let _value: Int
    const init(value: Int) {
        _value = value
    }

    public static const KB: JoyDataSize = JoyDataSize(1 << 10)
    public static const MB: JoyDataSize = JoyDataSize(1 << 20)
    public static const GB: JoyDataSize = JoyDataSize(1 << 30)

    public operator func *(r: Int): JoyDataSize {
        JoyDataSize(_value * r)
    }

    public prop value: Int {
        get() {
            _value
        }
    }
}

/**
 * configuration for multi part parsing and handling
 */
public struct JoyMultiPartConfig {
    public var maxParts: Int = 10
    public var maxHeaders: Int = 5
    public var maxMemSize: JoyDataSize = JoyDataSize.MB * 32
    public var maxFileSize: JoyDataSize = JoyDataSize.MB * 32
    public var fileCacheDir: String = ""
}
