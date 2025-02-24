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

import std.io.ByteBuffer
import std.collection.HashMap

/**
* the interface to process mutli part content
*/
public interface JoyMultiPartHandler {
    /**
    * call the function when read mutli part content
    */
    func onPart(part: JoyMultiPart, data: Array<Byte>): Unit
}

public class JoyMultiPartFuncHandler <: JoyMultiPartHandler {
    public JoyMultiPartFuncHandler(let handler: (JoyMultiPart) -> Unit) {}

    public func onPart(part: JoyMultiPart, data: Array<Byte>): Unit {
        this.onPart(part, data)
    }
}

public class JoyMemoryMultiPartHandler <: JoyMultiPartHandler {
    private let cache = HashMap<String, ByteBuffer>()

    public func onPart(part: JoyMultiPart, data: Array<Byte>): Unit {
        let content = cache.get(part.name)
        if (let Some(c) <- content) {
            c.write(data)
        } else {
            let buffer = ByteBuffer()
            buffer.write(data)
            cache.add(part.name, buffer)
        }
    }

    public func getPartContent(name: String): ?ByteBuffer{
        cache.get(name)
    }
}
