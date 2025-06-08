/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.multipart

import std.io.{ByteBuffer, SeekPosition}
import std.collection.*
import std.fs.remove
import std.unittest.*
import std.unittest.testmacro.*
import stdx.net.http.*

@Test
public class MultiPartWriterTestCaseSuit {
    @TestCase
    public func testWriteField() {
        var b = ByteBuffer()
        var w = JoyMultiPartWriter(b)
        w.writeField("k1", 'v1')
        w.writeField("k2", 'v2')
        w.writeField("k3", 'v3')
        w.close()

        let config = JoyMultiPartConfig()
        let handler = JoyMemoryMultiPartHandler(config)
        let parser = JoyMultiPartParser(config, handler, b, w.boundary)
        parser.parseParts()

        MultiPartParserTestCaseSuit.checkPart("k1", "v1", parser, handler)
        MultiPartParserTestCaseSuit.checkPart("k2", "v2", parser, handler)
        MultiPartParserTestCaseSuit.checkPart("k3", "v3", parser, handler)
    }

    @TestCase
    public func testWriteFile() {
        var b = ByteBuffer()
        var w = JoyMultiPartWriter(b)
        w.createFromFile("k1", 'file1.txt')
        w.writePartData("file1 contents".toArray())
        w.createFromFile("k2", 'file2.txt')
        w.writePartData("file2 contents".toArray())
        w.close()

        let config = JoyMultiPartConfig()
        let handler = JoyMemoryMultiPartHandler(config)
        let parser = JoyMultiPartParser(config, handler, b, w.boundary)
        parser.parseParts()

        var part = MultiPartParserTestCaseSuit.checkPart("k1", "file1 contents", parser, handler)
        MultiPartParserTestCaseSuit.checkPartProp(part, "file1.txt", "application/octet-stream")
        part = MultiPartParserTestCaseSuit.checkPart("k2", "file2 contents", parser, handler)
        MultiPartParserTestCaseSuit.checkPartProp(part, "file2.txt", "application/octet-stream")
    }
}
