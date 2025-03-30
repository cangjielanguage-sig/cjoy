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
import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

@Test
public class MultiPartParserTestCaseSuit {
    static func checkPart(name: String, value: String, parser: JoyMultiPartParser, handler: JoyMemoryMultiPartHandler): JoyMultiPart {
        let part = parser.getPart(name).getOrThrow()
        let content = handler.getContent(name)
        let rc = String.fromUtf8(content.getOrThrow().bytes())
        if (rc != value) {
            @Fail("the part content is not match, expect=${value}, real=${rc}")
        }
        part
    }

    static func checkPartProp(part: JoyMultiPart, filename: String, contType: String): Unit {
        if (part.fileName != filename) {
            @Fail("the file name is not match, expect=${filename}, real=${part.fileName}")
        }
        if (part.contentType != contType) {
            @Fail("the content type is not match, expect=${contType}, real=${part.contentType}")
        }
    }

    @TestCase
    func testSmallParts() {
        let str = #"
--WebKitFormBoundaryrGKCBY7qhFd3TrwA
Content-Disposition: form-data; name="text"

title
--WebKitFormBoundaryrGKCBY7qhFd3TrwA
Content-Disposition: form-data; name="file"; filename="abc.png"
Content-Type: image/png

PNG ... content of abc.png
--WebKitFormBoundaryrGKCBY7qhFd3TrwA--
"#
        let config = JoyMultiPartConfig()
        let handler = JoyMemoryMultiPartHandler(config)
        let byteBuffer = ByteBuffer()
        byteBuffer.write(str.replace("\n", "\r\n").toArray())
        let parser = JoyMultiPartParser(config, handler, byteBuffer, "WebKitFormBoundaryrGKCBY7qhFd3TrwA")
        parser.parseParts()
        checkPart("text", "title", parser, handler)
        let part = checkPart("file", "PNG ... content of abc.png", parser, handler)
        checkPartProp(part, "abc.png", "image/png")
    }

    @TestCase
    func testBigParts() {
        let str = #"
--WebKitFormBoundaryrGKCBY7qhFd3TrwA
Content-Disposition: form-data; name="file1"; filename="random.png"
Content-Type: image/png

test_file
--WebKitFormBoundaryrGKCBY7qhFd3TrwA
Content-Disposition: form-data; name="file2"; filename="random.png"
Content-Type: image/png

test_file
--WebKitFormBoundaryrGKCBY7qhFd3TrwA
Content-Disposition: form-data; name="file3"; filename="random.png"
Content-Type: image/png

test_file
--WebKitFormBoundaryrGKCBY7qhFd3TrwA--
"#
        let config = JoyMultiPartConfig()
        let handler = JoyMemoryMultiPartHandler(config)
        let byteBuffer = ByteBuffer()
        let testFile = "abcd" * 1024
        byteBuffer.write(str.replace("\n", "\r\n").replace("test_file", testFile).toArray())
        let parser = JoyMultiPartParser(config, handler, byteBuffer, "WebKitFormBoundaryrGKCBY7qhFd3TrwA")
        parser.parseParts()
        checkPart("file1", testFile, parser, handler)
        checkPart("file2", testFile, parser, handler)
        checkPart("file3", testFile, parser, handler)
    }
}
