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

import std.io.ByteBuffer
import std.fs.remove
import std.unittest.testmacro.*
import stdx.net.http.*

@Test
public class MultiPartFormTestCaseSuit {
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
            remove(config.fileCacheDir, recursive: true)
        }
    }
}
