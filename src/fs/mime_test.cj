/*
 * Copyright (c) 2026 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.fs

import std.unittest.testmacro.*
import cjoy.multipart.getMimeTypeByExt

@Test
public class MimeTestCaseSuit {
    /**
     * 测试常见扩展名的 MIME 类型 - 验证修正后的类型映射
     */
    @TestCase
    public func testCommonMimeTypes() {
        @Assert(getMimeTypeByExt(".avif") ?? "", "image/avif")
        @Assert(getMimeTypeByExt(".avi") ?? "", "video/x-msvideo")
        @Assert(getMimeTypeByExt(".cda") ?? "", "application/x-cdf")
        @Assert(getMimeTypeByExt(".doc") ?? "", "application/msword")
        @Assert(getMimeTypeByExt(".mpkg") ?? "", "application/vnd.apple.installer+xml")
        @Assert(getMimeTypeByExt(".ogx") ?? "", "application/ogg")
        @Assert(getMimeTypeByExt(".woff") ?? "", "font/woff")
        @Assert(getMimeTypeByExt(".woff2") ?? "", "font/woff2")
    }
}
