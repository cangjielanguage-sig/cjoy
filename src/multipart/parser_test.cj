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
import std.collection.ArrayList
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

    @TestCase
    func testMaxPartsLimit() {
        let boundary = "WebKitFormBoundaryrGKCBY7qhFd3TrwA"
        var str = ""
        for (i in 0..3) {  // 3 parts (0, 1, 2)
            
            let x = #"--WebKitFormBoundaryrGKCBY7qhFd3TrwA
Content-Disposition: form-data; name="field{num}"

value{num}
"#
        str += x.replace("{num}", "${i}")
        }
        str += #"--WebKitFormBoundaryrGKCBY7qhFd3TrwA--
"#

        var config = JoyMultiPartConfig()
        config.maxParts = 2
        let handler = JoyMemoryMultiPartHandler(config)
        let byteBuffer = ByteBuffer()
        byteBuffer.write(str.replace("\n", "\r\n").toArray())

        let parser = JoyMultiPartParser(config, handler, byteBuffer, boundary)
        try {
            parser.parseParts()
            @Fail("should throw MultiPartLimitReachedException when parts exceed max limit")
        } catch (e: MultiPartLimitReachedException) {
        }
    }

    @TestCase
    func testMaxHeadersLimit() {
        let boundary = "WebKitFormBoundaryrGKCBY7qhFd3TrwA"
        let str = #"--WebKitFormBoundaryrGKCBY7qhFd3TrwA
Content-Disposition: form-data; name="test"
Header1: value1
Header2: value2
Header3: value3
Header4: value4
Header5: value5
Header6: value6

content
--WebKitFormBoundaryrGKCBY7qhFd3TrwA--
"#

        var config = JoyMultiPartConfig()
        config.maxHeaders = 5
        let handler = JoyMemoryMultiPartHandler(config)
        let byteBuffer = ByteBuffer()
        byteBuffer.write(str.replace("\n", "\r\n").toArray())

        let parser = JoyMultiPartParser(config, handler, byteBuffer, boundary)
        try {
            parser.parseParts()
            @Fail("should throw MultiPartLimitReachedException when headers exceed max limit")
        } catch (e: MultiPartLimitReachedException) {
        }
    }

    @TestCase
    @Skip
    func testInvalidBoundary() {
        let str = #"--InvalidBoundary
Content-Disposition: form-data; name="test"

content
--InvalidBoundary2--
"#

        let config = JoyMultiPartConfig()
        let handler = JoyMemoryMultiPartHandler(config)
        let byteBuffer = ByteBuffer()
        byteBuffer.write(str.replace("\n", "\r\n").toArray())

        let parser = JoyMultiPartParser(config, handler, byteBuffer, "ValidBoundary")
        try {
            parser.parseParts()
            @Fail("should throw MultiPartParseException when boundary does not match")
        } catch (e: MultiPartParseException) {
        }
    }

    @TestCase
    func testIncompleteMultipart() {
        let str = #"--WebKitFormBoundaryrGKCBY7qhFd3TrwA
Content-Disposition: form-data; name="test"

content
--WebKitFormBoundaryrGKCBY7qhFd3TrwA
"#

        let config = JoyMultiPartConfig()
        let handler = JoyMemoryMultiPartHandler(config)
        let byteBuffer = ByteBuffer()
        byteBuffer.write(str.replace("\n", "\r\n").toArray())

        let parser = JoyMultiPartParser(config, handler, byteBuffer, "WebKitFormBoundaryrGKCBY7qhFd3TrwA")
        try {
            parser.parseParts()
            @Fail("should throw MultiPartParseException when multipart is incomplete")
        } catch (e: MultiPartParseException) {
        }
    }

    @TestCase
    func testEmptyMultipart() {
        let str = #"--WebKitFormBoundaryrGKCBY7qhFd3TrwA--
"#

        let config = JoyMultiPartConfig()
        let handler = JoyMemoryMultiPartHandler(config)
        let byteBuffer = ByteBuffer()
        byteBuffer.write(str.replace("\n", "\r\n").toArray())

        let parser = JoyMultiPartParser(config, handler, byteBuffer, "WebKitFormBoundaryrGKCBY7qhFd3TrwA")
        parser.parseParts()

        let parts = ArrayList<JoyMultiPart>()
        for (p in parser) {
            parts.add(p)
        }

        if (parts.size != 0) {
            @Fail("should have no parts when parsing empty multipart")
        }
    }

    @TestCase
    func testSinglePart() {
        let str = #"--WebKitFormBoundaryrGKCBY7qhFd3TrwA
Content-Disposition: form-data; name="single"

single value
--WebKitFormBoundaryrGKCBY7qhFd3TrwA--
"#

        let config = JoyMultiPartConfig()
        let handler = JoyMemoryMultiPartHandler(config)
        let byteBuffer = ByteBuffer()
        byteBuffer.write(str.replace("\n", "\r\n").toArray())

        let parser = JoyMultiPartParser(config, handler, byteBuffer, "WebKitFormBoundaryrGKCBY7qhFd3TrwA")
        parser.parseParts()

        let part = parser.getPart("single")
        if (part.isNone()) {
            @Fail("should find the single part")
        }

        let content = handler.getContent("single")
        let rc = String.fromUtf8(content.getOrThrow().bytes())
        if (rc != "single value") {
            @Fail("the part content is not match, expect=single value, real=${rc}")
        }
    }

    @TestCase
    func testPartWithSpecialCharacters() {
        let str = #"--WebKitFormBoundaryrGKCBY7qhFd3TrwA
Content-Disposition: form-data; name="field with spaces"

value with spaces and special chars: !@#$%^&*()_+
--WebKitFormBoundaryrGKCBY7qhFd3TrwA--
"#

        let config = JoyMultiPartConfig()
        let handler = JoyMemoryMultiPartHandler(config)
        let byteBuffer = ByteBuffer()
        byteBuffer.write(str.replace("\n", "\r\n").toArray())

        let parser = JoyMultiPartParser(config, handler, byteBuffer, "WebKitFormBoundaryrGKCBY7qhFd3TrwA")
        parser.parseParts()

        let part = parser.getPart("field with spaces")
        if (part.isNone()) {
            @Fail("should find the part with spaces in name")
        }

        let content = handler.getContent("field with spaces")
        let rc = String.fromUtf8(content.getOrThrow().bytes())
        if (rc != "value with spaces and special chars: !@#$%^&*()_+") {
            @Fail("the part content is not match, expect=value with spaces and special chars: !@#$%^&*()_+, real=${rc}")
        }
    }
}
