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

import std.io.{OutputStream, BufferedOutputStream, ByteBuffer}
import std.time.DateTime

public class JoyMultiPartWriter {
    private let _buffer: BufferedOutputStream<OutputStream>
    private var _boundry: Array<Byte> = Array<Byte>(30, repeat: b'0')

    public init(output: OutputStream) {
        _buffer = BufferedOutputStream(output)
    }

    static func randBoundry(): Array<Byte> {
        Array()
    }
}
