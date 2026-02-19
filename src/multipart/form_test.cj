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
import std.fs.{remove, Path, exists}
import std.collection.ArrayList
import std.unittest.testmacro.*
import stdx.net.http.*

@Test
public class MultiPartFormTestCaseSuit {
    /**
     * 测试 POST 表单解析 - 验证从 HTTP 请求中正确解析包含文本字段和文件的 multipart 表单数据
     */
    @TestCase
    public func testPostForm() {
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
        let byteBuffer = ByteBuffer()
        byteBuffer.write(str.replace("\n", "\r\n").toArray())
        let request = HttpRequestBuilder()
            .post()
            .url("http://127.0.0.1:18881/test")
            .body(byteBuffer)
            .header("Content-type", "multipart/form-data; boundary=WebKitFormBoundaryrGKCBY7qhFd3TrwA")
            .build()
        var config = JoyMultiPartConfig()
        config.fileCacheDir = "./test_tmp"
        try (form = JoyMultiPartForm.create(request, config)) {
            form.parse()
            let text = form.getPart("text")?.text
            if (text != "title") {
                @Fail("the text is not match, expect=title, real=${text}")
            }
            let file = form.getPart("file")?.file
            if (file.isNone()) {
                @Fail("the file is not match")
            }
        } finally {
            if (exists(Path(config.fileCacheDir))) {
                remove(config.fileCacheDir, recursive: true)
            }
        }
    }

    /**
     * 测试非 multipart 表单 - 验证当 Content-Type 为 application/x-www-form-urlencoded 时 isFormData 为 false
     */
    @TestCase
    public func testNonMultipartForm() {
        let byteBuffer = ByteBuffer()
        byteBuffer.write("name=value&key=test".toArray())
        let request = HttpRequestBuilder()
            .post()
            .url("http://127.0.0.1:18881/test")
            .body(byteBuffer)
            .header("Content-type", "application/x-www-form-urlencoded")
            .build()
        let config = JoyMultiPartConfig()
        let form = JoyMultiPartForm.create(request, config)

        if (form.isFormData) {
            @Fail("should not be form data when content type is application/x-www-form-urlencoded")
        }
    }

    /**
     * 测试缺少边界字符串 - 验证当 Content-Type 头部缺少 boundary 参数时抛出 MultiPartParseException 异常
     */
    @TestCase
    public func testMissingBoundary() {
        let byteBuffer = ByteBuffer()
        byteBuffer.write("content".toArray())
        let request = HttpRequestBuilder()
            .post()
            .url("http://127.0.0.1:18881/test")
            .body(byteBuffer)
            .header("Content-type", "multipart/form-data")
            .build()
        let config = JoyMultiPartConfig()

        try {
            let form = JoyMultiPartForm.create(request, config)
            @Fail("should throw MultiPartParseException when boundary is missing")
        } catch (e: MultiPartParseException) {
        }
    }

    /**
     * 测试自定义分块处理器 - 验证可通过 handlePart 方法为特定字段注册自定义的数据处理回调函数
     */
    @TestCase
    public func testCustomPartHandler() {
        let str = #"
--WebKitFormBoundaryrGKCBY7qhFd3TrwA
Content-Disposition: form-data; name="custom"

custom value
--WebKitFormBoundaryrGKCBY7qhFd3TrwA--
"#
        let byteBuffer = ByteBuffer()
        byteBuffer.write(str.replace("\n", "\r\n").toArray())
        let request = HttpRequestBuilder()
            .post()
            .url("http://127.0.0.1:18881/test")
            .body(byteBuffer)
            .header("Content-type", "multipart/form-data; boundary=WebKitFormBoundaryrGKCBY7qhFd3TrwA")
            .build()
        var config = JoyMultiPartConfig()
        config.fileCacheDir = "./test_tmp"

        let capturedValue = StringBuilder()
        try (form = JoyMultiPartForm.create(request, config)) {
            form.handlePart("custom", {
                part: JoyMultiPart, data: Array<Byte> => capturedValue.append(String.fromUtf8(data))
            })
            form.parse()

            if (capturedValue.toString() != "custom value") {
                @Fail("custom handler should capture the part value")
            }
        } finally {
            if (exists(Path(config.fileCacheDir))) {
                remove(config.fileCacheDir, recursive: true)
            }
        }
    }

    /**
     * 测试表单迭代 - 验证可以通过迭代器遍历表单中的所有分块
     */
    @TestCase
    public func testFormIteration() {
        let str = #"
--WebKitFormBoundaryrGKCBY7qhFd3TrwA
Content-Disposition: form-data; name="field1"

value1
--WebKitFormBoundaryrGKCBY7qhFd3TrwA
Content-Disposition: form-data; name="field2"

value2
--WebKitFormBoundaryrGKCBY7qhFd3TrwA
Content-Disposition: form-data; name="field3"

value3
--WebKitFormBoundaryrGKCBY7qhFd3TrwA--
"#
        let byteBuffer = ByteBuffer()
        byteBuffer.write(str.replace("\n", "\r\n").toArray())
        let request = HttpRequestBuilder()
            .post()
            .url("http://127.0.0.1:18881/test")
            .body(byteBuffer)
            .header("Content-type", "multipart/form-data; boundary=WebKitFormBoundaryrGKCBY7qhFd3TrwA")
            .build()
        var config = JoyMultiPartConfig()
        config.fileCacheDir = "./test_tmp"

        try (form = JoyMultiPartForm.create(request, config)) {
            form.parse()

            let parts = ArrayList<JoyMultiPart>()
            for (p in form) {
                parts.add(p)
            }

            if (parts.size != 3) {
                @Fail("should have 3 parts, got ${parts.size}")
            }

            let expectedNames = ["field1", "field2", "field3"]
            for (i in 0..parts.size) {
                if (parts[i].name != expectedNames[i]) {
                    @Fail("part name mismatch at index ${i}, expected ${expectedNames[i]}, got ${parts[i].name}")
                }
            }
        } finally {
            if (exists(Path(config.fileCacheDir))) {
                remove(config.fileCacheDir, recursive: true)
            }
        }
    }
}
