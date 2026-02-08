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

import std.io.ByteBuffer
import std.unittest.testmacro.*

@Test
public class MultiPartHandlerTestCaseSuit {
    @TestCase
    public func testMemoryHandler() {
        let config = JoyMultiPartConfig()
        let handler = JoyMemoryMultiPartHandler(config)

        let part = JoyMultiPart()
        handler.onPart(part, "first data".toArray())
        handler.onPart(part, " second data".toArray())

        let content = handler.getContent(part.name)
        if (content.isNone()) {
            @Fail("should find the part content")
        }

        let text = String.fromUtf8(content.getOrThrow().bytes())
        if (text != "first data second data") {
            @Fail("content should be 'first data second data', got ${text}")
        }
    }

    @TestCase
    public func testMemoryHandlerSizeLimit() {
        var config = JoyMultiPartConfig()
        config.maxMemSize = JoyDataSize(10) // 10 bytes limit
        let handler = JoyMemoryMultiPartHandler(config)

        let part = JoyMultiPart()
        try {
            handler.onPart(part, "12345678901".toArray()) // 11 bytes
            @Fail("should throw MultiPartLimitReachedException")
        } catch (e: MultiPartLimitReachedException) {
        }
    }

    @TestCase
    public func testFuncHandler() {
        let capturedData = [""]
        let handler = JoyMultiPartFuncHandler({ part: JoyMultiPart, data: Array<Byte> =>
            capturedData[0] += String.fromUtf8(data)
        })

        let part = JoyMultiPart()
        handler.onPart(part, "hello".toArray())
        handler.onPart(part, " world".toArray())

        if (capturedData[0] != "hello world") {
            @Fail("func handler should capture 'hello world', got ${capturedData[0]}")
        }
    }

    @TestCase
    public func testMemoryHandlerClose() {
        let config = JoyMultiPartConfig()
        let handler = JoyMemoryMultiPartHandler(config)

        let part = JoyMultiPart()
        handler.onPart(part, "data to be closed".toArray())

        handler.close()

        if (!handler.isClosed()) {
            @Fail("handler should be closed")
        }

        let content = handler.getContent(part.name)
        if (content.isSome()) {
            @Fail("content should be cleared after close")
        }
    }

    @TestCase
    public func testMultiplePartsInMemory() {
        let config = JoyMultiPartConfig()
        let handler = JoyMemoryMultiPartHandler(config)

        let part1 = JoyMultiPart()
        part1.setName("part1")
        handler.onPart(part1, "data1".toArray())

        let part2 = JoyMultiPart()
        part2.setName("part2")
        handler.onPart(part2, "data2".toArray())

        let part3 = JoyMultiPart()
        part3.setName("part3")
        handler.onPart(part3, "data3".toArray())

        let content1 = handler.getContent("part1")
        let content2 = handler.getContent("part2")
        let content3 = handler.getContent("part3")

        if (content1.isNone() || content2.isNone() || content3.isNone()) {
            @Fail("should find all parts")
        }

        if (String.fromUtf8(content1.getOrThrow().bytes()) != "data1") {
            @Fail("part1 content mismatch")
        }
        if (String.fromUtf8(content2.getOrThrow().bytes()) != "data2") {
            @Fail("part2 content mismatch")
        }
        if (String.fromUtf8(content3.getOrThrow().bytes()) != "data3") {
            @Fail("part3 content mismatch")
        }
    }
}
