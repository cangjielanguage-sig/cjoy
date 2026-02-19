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
public class MultiPartWriterTestCaseSuit {
    /**
     * 测试写入表单字段 - 验证正确写入多个普通表单字段并可通过解析器读取
     */
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

    /**
     * 测试写入文件 - 验证正确写入文件分块并保留文件名和默认内容类型
     */
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

    /**
     * 测试自定义边界字符串 - 验证使用自定义边界字符串写入 multipart 数据
     */
    @TestCase
    public func testCustomBoundary() {
        var b = ByteBuffer()
        let customBoundary = "MyCustomBoundary12345"
        var w = JoyMultiPartWriter(b, boundry: customBoundary)
        w.writeField("key", "value")
        w.close()

        let config = JoyMultiPartConfig()
        let handler = JoyMemoryMultiPartHandler(config)
        let parser = JoyMultiPartParser(config, handler, b, customBoundary)
        parser.parseParts()

        MultiPartParserTestCaseSuit.checkPart("key", "value", parser, handler)
    }

    /**
     * 测试表单内容类型生成 - 验证 formDataContentType 属性返回正确的 Content-Type 头部值
     */
    @TestCase
    public func testFormDataContentType() {
        var b = ByteBuffer()
        let customBoundary = "MyBoundaryWithSpaces"
        var w = JoyMultiPartWriter(b, boundry: customBoundary)
        let contentType = w.formDataContentType

        if (!contentType.startsWith("multipart/form-data")) {
            @Fail("content type should start with multipart/form-data")
        }

        if (!contentType.contains(customBoundary)) {
            @Fail("content type should contain the boundary")
        }
    }

    /**
     * 测试写入大数据 - 验证正确写入 1MB 大小的字段数据
     */
    @TestCase
    public func testWriteLargeData() {
        var b = ByteBuffer()
        var w = JoyMultiPartWriter(b)
        let largeData = "x" * 1024 * 1024 // 1MB
        w.writeField("largeField", largeData)
        w.close()

        let config = JoyMultiPartConfig()
        let handler = JoyMemoryMultiPartHandler(config)
        let parser = JoyMultiPartParser(config, handler, b, w.boundary)
        parser.parseParts()

        let part = MultiPartParserTestCaseSuit.checkPart("largeField", largeData, parser, handler)
    }

    /**
     * 测试写入带自定义内容类型的文件 - 验证写入文件时可指定自定义的 Content-Type
     */
    @TestCase
    public func testWriteFileWithContentType() {
        var b = ByteBuffer()
        var w = JoyMultiPartWriter(b)
        w.writeFile("image", "photo.jpg", "binary data".toArray(), contentType: "image/jpeg")
        w.close()

        let config = JoyMultiPartConfig()
        let handler = JoyMemoryMultiPartHandler(config)
        let parser = JoyMultiPartParser(config, handler, b, w.boundary)
        parser.parseParts()

        let part = MultiPartParserTestCaseSuit.checkPart("image", "binary data", parser, handler)
        MultiPartParserTestCaseSuit.checkPartProp(part, "photo.jpg", "image/jpeg")
    }

    /**
     * 测试对同一分块多次写入 - 验证可对同一分块分多次写入数据片段
     */
    @TestCase
    public func testMultipleWritesToSamePart() {
        var b = ByteBuffer()
        var w = JoyMultiPartWriter(b)
        w.createFormField("multiWrite")
        w.writePartData("first part".toArray())
        w.writePartData(" second part".toArray())
        w.writePartData(" third part".toArray())
        w.close()

        let config = JoyMultiPartConfig()
        let handler = JoyMemoryMultiPartHandler(config)
        let parser = JoyMultiPartParser(config, handler, b, w.boundary)
        parser.parseParts()

        MultiPartParserTestCaseSuit.checkPart("multiWrite", "first part second part third part", parser, handler)
    }

    /**
     * 测试关闭后写入 - 验证在调用 close() 后尝试写入会抛出 IllegalArgumentException 异常
     */
    @TestCase
    public func testWriteAfterClose() {
        var b = ByteBuffer()
        var w = JoyMultiPartWriter(b)
        w.writeField("key", "value")
        w.close()

        try {
            w.writeField("anotherKey", "anotherValue")
            @Fail("should throw IllegalArgumentException when writing after close")
        } catch (e: IllegalArgumentException) {
        }
    }

    /**
     * 测试未创建分块时写入 - 验证在未先创建分块的情况下直接写入数据会抛出 IllegalArgumentException 异常
     */
    @TestCase
    public func testWriteWithoutCreatingPart() {
        var b = ByteBuffer()
        var w = JoyMultiPartWriter(b)

        try {
            w.writePartData("data without part".toArray())
            @Fail("should throw IllegalArgumentException when writing without creating part")
        } catch (e: IllegalArgumentException) {
        }
    }
}
