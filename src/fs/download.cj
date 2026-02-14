/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.fs

import std.fs.{Path, exists, File, OpenMode}
import std.io.IOException
import stdx.net.http.HttpResponseWriter
import cjoy.framework.{JoyContext, JoyHttpConsts}
import cjoy.multipart.{getMimeTypeByExt, escapeQuotes}

/**
 * Downloads a file as an attachment
 *
 * @param ctx The joy context
 * @param filePath The path of file to download
 * @throws IOException if file is not existed
 */
public func downloadAttachment(ctx: JoyContext, filePath: Path): Unit {
    if (!exists(filePath)) {
        throw IOException("the file is not existed")
    }

    let filename = filePath.fileName
    let contentType = getMimeTypeByExt(".${filePath.extensionName}") ?? JoyHttpConsts.MIME_APP_OCTET_STREAM
    ctx.header(JoyHttpConsts.HEADER_CONTENT_DISPOSITION, "attachment; filename=\"${escapeQuotes(filename)}\"")
    ctx.header(JoyHttpConsts.HEADER_CONTENT_TYPE, contentType)
    ctx.header(JoyHttpConsts.HEADER_TRANSFER_ENCODING, "chunked")

    try (file = File(filePath, OpenMode.Read)) {
        let writer = HttpResponseWriter(ctx.httpContext)
        let buf = Array<UInt8>(1024, repeat: 0)
        while (true) {
            let readLen = file.read(buf)
            if (readLen > 0) {
                writer.write(buf[..readLen])
            } else {
                break
            }
        }
    }
}
