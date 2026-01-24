/*
 * Copyright (c) 2026 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 *
 */

package cjoy.fs

import std.collection.ArrayList
import std.convert.Parsable
import std.fs.{Path, exists, File, OpenMode, FileInfo, Directory}
import std.io.SeekPosition
import std.time.{DateTime, DateTimeFormat}
import stdx.net.http.{HttpStatusCode, HttpResponseWriter}
import cjoy.framework.{JoyContext, JoyHttpConsts}
import cjoy.multipart.{getMimeTypeByExt}

/**
 * HTTP conditional result
 */
enum JoyCondResult {
    | MatchNone
    | MatchTrue
    | MatchFalse
}

/**
 * File server for serving static files
 *
 */
public class JoyFileServer {
    // 默认缓冲区大小
    private static const BUFFER_SIZE: Int = 32 * 1024 // 32KB

    // index.html 文件名
    private static const INDEX_PAGE: String = "index.html"

    /**
     * Serve file from local filesystem
     *
     * @param ctx: joy context
     * @param filePath: path of file which will to serve
     * @throws IOException if file is not existed
     */
    public static func serveFile(ctx: JoyContext, filePath: Path): Unit {
        if (!exists(filePath)) {
            writeError(ctx, "404 page not found", HttpStatusCode.STATUS_NOT_FOUND)
            return
        }

        let fileInfo = FileInfo(filePath)
        // 检查是否是目录
        if (fileInfo.isDirectory()) {
            serveDirectory(ctx, filePath, fileInfo)
            return
        }

        serveContent(ctx, filePath, None, None)
    }

    /**
     * Serve content from provided read seeker
     *
     * @param ctx: joy context
     * @param filePath: path of file which will to serve
     * @param modTime: modification time of content, None means use file modification time
     * @param eTag: ETag of content, None means auto generate
     * @throws IOException if file is not existed
     */
    public static func serveContent(ctx: JoyContext, filePath: Path, modTime: ?DateTime, eTag: ?String): Unit {
        if (!exists(filePath)) {
            writeError(ctx, "404 page not found", HttpStatusCode.STATUS_NOT_FOUND)
            return
        }

        let fileInfo = FileInfo(filePath)

        // 获取文件大小
        let size = fileInfo.size
        if (size < 0) {
            writeError(ctx, "500 Internal Server Error", HttpStatusCode.STATUS_INTERNAL_SERVER_ERROR)
            return
        }

        // 获取修改时间
        let fileModTime = fileInfo.lastModificationTime
        let realModTime = modTime ?? fileModTime

        // 生成ETag
        let realETag = eTag ?? generateETag(filePath, size, fileModTime)

        // 设置Last-Modified头
        if (let Some(mt) <- modTime) {
            setLastLastModified(ctx, mt)
        } else {
            setLastLastModified(ctx, fileModTime)
        }

        // 设置ETag头
        ctx.header(JoyHttpConsts.HEADER_ETAG, realETag)

        // 检查预条件
        let (done, _) = checkPreconditions(ctx, realModTime, realETag)
        if (done) {
            return
        }

        // 设置Content-Type
        let contentType = getMimeTypeByExt(".${filePath.extensionName}") ?? JoyHttpConsts.MIME_APP_OCTET_STREAM
        ctx.header(JoyHttpConsts.HEADER_CONTENT_TYPE, contentType)

        // 处理Range请求
        let rangeHeader = ctx.getHeader(JoyHttpConsts.HEADER_RANGE)
        let rangeStr = if (let Some(r) <- rangeHeader) {
            r
        } else {
            ""
        }

        if (rangeStr.isEmpty()) {
            // 没有Range请求，发送整个文件
            ctx.header(JoyHttpConsts.HEADER_TRANSFER_ENCODING, "chunked")
            sendFile(ctx, filePath, 0, size, contentType)
        } else {
            // 处理Range请求
            handleRangeRequest(ctx, filePath, rangeStr, size, contentType)
        }
    }

    /**
     * Serve directory with index.html or directory listing
     *
     * @param ctx: joy context
     * @param dirPath: path of directory
     * @param fileInfo: directory file info
     * @throws IOException if directory is not existed
     */
    private static func serveDirectory(ctx: JoyContext, dirPath: Path, fileInfo: FileInfo): Unit {
        // 检查URL路径是否以/结尾
        let requestPath = ctx.path
        if (!requestPath.endsWith("/")) {
            // 重定向到带斜杠的路径
            let newPath = if (requestPath.isEmpty()) {
                "/"
            } else {
                "${requestPath}/"
            }
            let query = ctx.url.query
            let location = if (query.isNone()) {
                newPath
            } else {
                "${newPath}?${query.getOrThrow()}"
            }
            ctx.header(JoyHttpConsts.HEADER_LOCATION, location)
            ctx.status(HttpStatusCode.STATUS_MOVED_PERMANENTLY)
            return
        }

        // 尝试查找index.html
        let indexPath = Path("${dirPath}/${INDEX_PAGE}")
        if (exists(indexPath)) {
            let indexFileInfo = FileInfo(indexPath)
            if (!indexFileInfo.isDirectory()) {
                serveContent(ctx, indexPath, None, None)
                return
            }
        }

        // 没有index.html，显示目录列表
        let fileModTime = fileInfo.lastModificationTime

        // 检查If-Modified-Since
        let condResult = checkIfIfModifiedSince(ctx, fileModTime)
        match (condResult) {
            case MatchFalse =>
                writeNotModified(ctx)
                return
            case _ => ()
        }

        setLastLastModified(ctx, fileModTime)
        ctx.header(JoyHttpConsts.HEADER_CONTENT_TYPE, "text/html; charset=utf-8")

        let writer = HttpResponseWriter(ctx.httpContext)
        let html = buildDirList(dirPath, requestPath)
        writer.write(html.toArray())
    }

    /**
     * Handle range request
     *
     * @param ctx: joy context
     * @param filePath: path of file
     * @param rangeStr: range header string
     * @param size: file size
     * @param contentType: content type
     */
    private static func handleRangeRequest(ctx: JoyContext, filePath: Path, rangeStr: String, size: Int64,
        contentType: String): Unit {
        // 解析Range头
        var ranges: JoyHttpRangs
        try {
            ranges = JoyHttpRange.parse(rangeStr, size)
        } catch (e: IllegalArgumentException) {
            // Range解析失败，返回整个文件
            ctx.header(JoyHttpConsts.HEADER_ACCEPT_RANGES, "bytes")
            ctx.header(JoyHttpConsts.HEADER_TRANSFER_ENCODING, "chunked")
            sendFile(ctx, filePath, 0, size, contentType)
            return
        }

        ctx.header(JoyHttpConsts.HEADER_TRANSFER_ENCODING, "chunked")
        if (ranges.size == 1) {
            // 单个Range请求
            let r = ranges[0]
            ctx.header(JoyHttpConsts.HEADER_ACCEPT_RANGES, "bytes")
            ctx.header(JoyHttpConsts.HEADER_CONTENT_RANGE, r.contentRange(size))
            ctx.status(HttpStatusCode.STATUS_PARTIAL_CONTENT)
            sendFile(ctx, filePath, r.start, r.length, contentType)
        } else {
            // 多个Range请求，返回multipart/byteranges
            // 简化处理，暂不支持multipart range，返回416错误
            ctx.header(JoyHttpConsts.HEADER_CONTENT_RANGE, "bytes */${size}")
            writeError(ctx, "Requested Range Not Satisfiable", HttpStatusCode.STATUS_REQUESTED_RANGE_NOT_SATISFIABLE)
        }
    }

    /**
     * Send file content
     *
     * @param ctx: joy context
     * @param filePath: path of file
     * @param offset: offset to start reading
     * @param length: length to read
     * @param contentType: content type
     */
    private static func sendFile(ctx: JoyContext, filePath: Path, offset: Int64, length: Int64, contentType: String): Unit {
        let writer = HttpResponseWriter(ctx.httpContext)
        let buf = Array<UInt8>(BUFFER_SIZE, repeat: 0)

        try (file = File(filePath, OpenMode.Read)) {
            // 跳转到offset
            if (offset > 0) {
                file.seek(SeekPosition.Current(offset))
            }

            var remaining = length
            while (remaining > 0) {
                let readLen = if (remaining > BUFFER_SIZE) {
                    BUFFER_SIZE
                } else {
                    remaining
                }

                let actualRead = file.read(buf[..readLen])
                if (actualRead <= 0) {
                    break
                }
                writer.write(buf[..actualRead])
                remaining -= actualRead
            }
        }
    }

    /**
     * Check preconditions (If-Match, If-None-Match, If-Modified-Since, etc.)
     *
     * @param ctx: joy context
     * @param modTime: modification time
     * @param eTag: ETag
     * @return (done, rangeHeader) - done means response already sent
     */
    private static func checkPreconditions(ctx: JoyContext, modTime: DateTime, eTag: String): (Bool, String) {
        // 检查If-Match
        let ifMatchResult = checkIfMatch(ctx, eTag)
        match (ifMatchResult) {
            case MatchNone =>
                // 检查If-Unmodified-Since
                let ifUnmodifiedSinceResult = checkIfUnmodifiedSince(ctx, modTime)
                match (ifUnmodifiedSinceResult) {
                    case MatchFalse =>
                        ctx.status(HttpStatusCode.STATUS_PRECONDITION_FAILED)
                        return (true, "")
                    case _ => ()
                }
            case MatchFalse =>
                ctx.status(HttpStatusCode.STATUS_PRECONDITION_FAILED)
                return (true, "")
            case _ => ()
        }

        // 检查If-None-Match
        let ifNoneMatchResult = checkIfNoneMatch(ctx, eTag)
        match (ifNoneMatchResult) {
            case MatchFalse =>
                if (ctx.method == JoyHttpConsts.METHOD_GET || ctx.method == JoyHttpConsts.METHOD_HEAD) {
                    writeNotModified(ctx)
                    return (true, "")
                } else {
                    ctx.status(HttpStatusCode.STATUS_PRECONDITION_FAILED)
                    return (true, "")
                }
            case MatchNone =>
                // 检查If-Modified-Since
                let ifModifiedSinceResult = checkIfIfModifiedSince(ctx, modTime)
                match (ifModifiedSinceResult) {
                    case MatchFalse =>
                        writeNotModified(ctx)
                        return (true, "")
                    case _ => ()
                }
            case _ => ()
        }

        // 检查If-Range
        let rangeHeader = ctx.getHeader(JoyHttpConsts.HEADER_RANGE) ?? ""
        if (!rangeHeader.isEmpty()) {
            let ifRangeResult = checkIfRange(ctx, modTime, eTag)
            match (ifNoneMatchResult) {
                case MatchFalse => return (false, "") // 忽略Range头
                case _ => ()
            }
        }
        return (false, rangeHeader)
    }

    /**
     * Check If-Match header
     *
     * @param ctx: joy context
     * @param eTag: ETag to check
     * @return cond result
     */
    private static func checkIfMatch(ctx: JoyContext, eTag: String): JoyCondResult {
        let ifMatch = ctx.getHeader(JoyHttpConsts.HEADER_IF_MATCH)
        if (ifMatch.isNone() || ifMatch.getOrThrow().isEmpty()) {
            return JoyCondResult.MatchNone
        }

        let headerValue = ifMatch.getOrThrow()

        // 检查是否为*
        if (headerValue.trimAscii() == "*") {
            return JoyCondResult.MatchTrue
        }

        // 解析ETag列表
        var i = 0
        let trimmed = headerValue.trimAscii()
        while (i < trimmed.size) {
            // 跳过逗号和空格
            while (i < trimmed.size && (trimmed[i] == b',' || trimmed[i] == b' ' || trimmed[i] == b'\t')) {
                i++
            }

            if (i >= trimmed.size) {
                break
            }

            // 扫描ETag
            let (tag, remain) = JoyETag.scan(trimmed[i..])
            if (tag.isEmpty()) {
                break
            }

            if (JoyETag.strongMatch(tag, eTag)) {
                return JoyCondResult.MatchTrue
            }

            i += tag.size
        }

        return JoyCondResult.MatchFalse
    }

    /**
     * Check If-None-Match header
     *
     * @param ctx: joy context
     * @param eTag: ETag to check
     * @return cond result
     */
    private static func checkIfNoneMatch(ctx: JoyContext, eTag: String): JoyCondResult {
        let ifNoneMatch = ctx.getHeader(JoyHttpConsts.HEADER_IF_NONE_MATCH)
        if (ifNoneMatch.isNone() || ifNoneMatch.getOrThrow().isEmpty()) {
            return JoyCondResult.MatchNone
        }

        let headerValue = ifNoneMatch.getOrThrow()

        // 检查是否为*
        if (headerValue.trimAscii() == "*") {
            return JoyCondResult.MatchFalse
        }

        // 解析ETag列表
        var i = 0
        let trimmed = headerValue.trimAscii()
        while (i < trimmed.size) {
            // 跳过逗号和空格
            while (i < trimmed.size && (trimmed[i] == b',' || trimmed[i] == b' ' || trimmed[i] == b'\t')) {
                i++
            }

            if (i >= trimmed.size) {
                break
            }

            // 扫描ETag
            let (tag, remain) = JoyETag.scan(trimmed[i..])
            if (tag.isEmpty()) {
                break
            }

            if (JoyETag.weakMatch(tag, eTag)) {
                return JoyCondResult.MatchFalse
            }

            i += tag.size
        }

        return JoyCondResult.MatchTrue
    }

    /**
     * Check If-Modified-Since header
     *
     * @param ctx: joy context
     * @param modTime: modification time
     * @return cond result
     */
    private static func checkIfIfModifiedSince(ctx: JoyContext, modTime: DateTime): JoyCondResult {
        if (ctx.method != JoyHttpConsts.METHOD_GET && ctx.method != JoyHttpConsts.METHOD_HEAD) {
            return JoyCondResult.MatchNone
        }

        let ifModifiedSince = ctx.getHeader(JoyHttpConsts.HEADER_IF_MODIFIED_SINCE)
        if (ifModifiedSince.isNone()) {
            return JoyCondResult.MatchNone
        }

        let headerValue = ifModifiedSince.getOrThrow()
        if (headerValue.isEmpty()) {
            return JoyCondResult.MatchNone
        }

        // 解析HTTP时间格式
        let parsedTime = tryParseHttpTime(headerValue)
        if (parsedTime.isNone()) {
            return JoyCondResult.MatchNone
        }

        // 比较时间（忽略秒以下精度）
        let pt = parsedTime.getOrThrow()
        if (modTime <= pt) {
            return JoyCondResult.MatchFalse
        }

        return JoyCondResult.MatchTrue
    }

    /**
     * Check If-Unmodified-Since header
     *
     * @param ctx: joy context
     * @param modTime: modification time
     * @return cond result
     */
    private static func checkIfUnmodifiedSince(ctx: JoyContext, modTime: DateTime): JoyCondResult {
        let ifUnmodifiedSince = ctx.getHeader(JoyHttpConsts.HEADER_IF_UNMODIFIED_SINCE)
        if (ifUnmodifiedSince.isNone()) {
            return JoyCondResult.MatchNone
        }

        let headerValue = ifUnmodifiedSince.getOrThrow()
        if (headerValue.isEmpty()) {
            return JoyCondResult.MatchNone
        }

        // 解析HTTP时间格式
        let parsedTime = tryParseHttpTime(headerValue)
        if (parsedTime.isNone()) {
            return JoyCondResult.MatchNone
        }

        // 比较时间
        let pt = parsedTime.getOrThrow()
        if (modTime <= pt) {
            return JoyCondResult.MatchTrue
        }

        return JoyCondResult.MatchFalse
    }

    /**
     * Check If-Range header
     *
     * @param ctx: joy context
     * @param modTime: modification time
     * @param eTag: ETag
     * @return cond result
     */
    private static func checkIfRange(ctx: JoyContext, modTime: DateTime, eTag: String): JoyCondResult {
        if (ctx.method != JoyHttpConsts.METHOD_GET && ctx.method != JoyHttpConsts.METHOD_HEAD) {
            return JoyCondResult.MatchNone
        }

        let ifRange = ctx.getHeader(JoyHttpConsts.HEADER_IF_RANGE)
        if (ifRange.isNone() || ifRange.getOrThrow().isEmpty()) {
            return JoyCondResult.MatchNone
        }

        let headerValue = ifRange.getOrThrow()

        // 尝试解析为ETag
        let (tag, _) = JoyETag.scan(headerValue)
        if (!tag.isEmpty()) {
            if (JoyETag.strongMatch(tag, eTag)) {
                return JoyCondResult.MatchTrue
            } else {
                return JoyCondResult.MatchFalse
            }
        }

        // 尝试解析为时间
        let parsedTime = tryParseHttpTime(headerValue)
        if (parsedTime.isNone()) {
            return JoyCondResult.MatchFalse
        }

        let pt = parsedTime.getOrThrow()
        if (modTime == pt) {
            return JoyCondResult.MatchTrue
        }

        return JoyCondResult.MatchFalse
    }

    /**
     * Set Last-Modified header
     *
     * @param ctx: joy context
     * @param modTime: modification time
     */
    private static func setLastLastModified(ctx: JoyContext, modTime: DateTime): Unit {
        let timeStr = formatHttpTime(modTime)
        ctx.header(JoyHttpConsts.HEADER_LAST_MODIFIED, timeStr)
    }

    /**
     * Format DateTime to HTTP time format
     *
     * @param time: local date time
     * @return formatted HTTP time string
     */
    private static func formatHttpTime(time: DateTime): String {
        time.format(DateTimeFormat.RFC1123)
    }

    /**
     * Generate ETag for file
     *
     * @param filePath: path of file
     * @param size: file size
     * @param modTime: modification time
     * @return ETag string
     */
    private static func generateETag(filePath: Path, size: Int64, modTime: DateTime): String {
        // 使用文件大小、修改时间和文件名生成ETag
        let sizeStr = size.toString()
        let timeStr = modTime.toUnixTimeStamp().toMilliseconds().toString()
        "\"${sizeStr}-${timeStr}\""
    }

    /**
     * Write 304 Not Modified response
     *
     * @param ctx: joy context
     */
    private static func writeNotModified(ctx: JoyContext): Unit {
        // RFC 7232 section 4.1:
        // a sender SHOULD NOT generate representation metadata other than
        // above listed fields unless said metadata exists for purpose of
        // guiding cache updates (e.g., Last-Modified might be useful if
        // response does not have an ETag field).

        // 清除Content-Type, Content-Length, Content-Encoding
        // 注意：仓颉的HTTP响应可能不允许直接删除头，这里需要特殊处理
        // 简化实现：直接返回304状态码

        ctx.status(HttpStatusCode.STATUS_NOT_MODIFIED)
    }

    /**
     * Write error response
     *
     * @param ctx: joy context
     * @param text: error text
     * @param code: HTTP status code
     */
    private static func writeError(ctx: JoyContext, text: String, code: UInt16): Unit {
        ctx.status(code)
        ctx.string(JoyHttpConsts.MIME_TEXT_PLAIN_UTF8, text)
    }

    /**
     * Build directory listing HTML
     *
     * @param dirPath: directory path
     * @param requestPath: request URL path
     * @return HTML string
     */
    private static func buildDirList(dirPath: Path, requestPath: String): String {
        let sb = StringBuilder()

        // HTML头部
        sb.append("<!doctype html>\n")
        sb.append("<html>\n")
        sb.append("<head>\n")
        sb.append("<meta name=\"viewport\" content=\"width=device-width\">\n")
        sb.append("<title>Directory listing</title>\n")
        sb.append("</head>\n")
        sb.append("<body>\n")
        sb.append("<h1>Directory listing: ${escapeHtml(requestPath)}</h1>\n")
        sb.append("<pre>\n")

        // 添加父目录链接（如果不是根目录）
        if (requestPath != "/") {
            let parentPath = getParentPath(requestPath)
            sb.append("<a href=\"${parentPath}\">../</a>\n")
        }

        // 列出目录内容
        let files = Directory.readFrom(dirPath)
        let parentPath = getParentPath(requestPath)
        for (file in files) {
            let name = file.name
            var path = parentPath + '/' + name
            if (file.isDirectory()) {
                path += "/"
            }
            sb.append("<a href=\"${path}\">${name}/</a>\n")
        }

        sb.append("</pre>\n")
        sb.append("</body>\n")
        sb.append("</html>\n")

        sb.toString()
    }

    /**
     * Get parent path from URL path
     *
     * @param path: URL path
     * @return parent path
     */
    private static func getParentPath(path: String): String {
        if (path.isEmpty()) {
            return "/"
        }

        let trimmed = path.trimEnd("/")
        if (trimmed.isEmpty()) {
            return "/"
        }

        if (let Some(lastSlash) <- trimmed.lastIndexOf("/")) {
            if (lastSlash == 0) {
                return "/"
            }
            trimmed[..lastSlash]
        } else {
            "/"
        }
    }

    /**
     * Escape HTML special characters
     *
     * @param str: string to escape
     * @return escaped string
     */
    private static func escapeHtml(str: String): String {
        str.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;")
    }
}
