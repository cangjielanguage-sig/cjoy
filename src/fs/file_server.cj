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
import std.fs.{Path, exists, File, OpenMode, FileInfo, Directory}
import std.io.{SeekPosition, OutputStream}
import std.time.{DateTime, DateTimeFormat}
import stdx.net.http.{HttpStatusCode, HttpResponseWriter}
import cjoy.framework.{JoyContext, JoyHttpConsts}
import cjoy.multipart.{getMimeTypeByExt, JoyMultiPartWriter}
import cjoy.utils.{trimString}

/**
 * HTTP 条件结果
 */
enum JoyCondResult {
    | MatchNone
    | MatchTrue
    | MatchFalse
}

/**
 * 用于提供静态文件的文件服务器
 *
 */
public class JoyFileServer {
    // 默认缓冲区大小
    private static const BUFFER_SIZE: Int = 32 * 1024 // 32KB

    // index.html 文件名
    private static const INDEX_PAGE: String = "index.html"

    /**
     * 从本地文件系统提供文件
     *
     * @param ctx joy 上下文
     * @param filePath 要提供服务的文件路径
     * @throws IOException 如果文件不存在
     */
    public static func serveFile(ctx: JoyContext, filePath: Path): Unit {
        if (!exists(filePath)) {
            writeError(ctx, "file not found", HttpStatusCode.STATUS_NOT_FOUND)
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
     * 从提供的读取器提供内容
     *
     * @param ctx joy 上下文
     * @param filePath 要提供服务的文件路径
     * @param modTime 内容修改时间，None 表示使用文件修改时间
     * @param eTag 内容的 ETag，None 表示自动生成
     * @throws IOException 如果文件不存在
     */
    public static func serveContent(ctx: JoyContext, filePath: Path, modTime: ?DateTime, eTag: ?String): Unit {
        if (!exists(filePath)) {
            writeError(ctx, "file not found", HttpStatusCode.STATUS_NOT_FOUND)
            return
        }

        let fileInfo = FileInfo(filePath)

        // 获取文件大小
        let size = fileInfo.size
        if (size < 0) {
            writeError(ctx, "negative content size computed", HttpStatusCode.STATUS_INTERNAL_SERVER_ERROR)
            return
        }

        // 获取修改时间
        let fileModTime = fileInfo.lastModificationTime
        let realModTime = modTime ?? fileModTime

        // 生成ETag
        let realETag = eTag ?? JoyHttpEtag.generate(size, fileModTime)

        // 设置Last-Modified头
        if (let Some(mt) <- modTime) {
            setLastLastModified(ctx, mt)
        } else {
            setLastLastModified(ctx, fileModTime)
        }

        // 设置ETag头
        ctx.header(JoyHttpConsts.HEADER_ETAG, realETag)

        // 检查预条件，并取回实际需要处理的 Range 头（If-Range 不匹配时会被置空）
        let (done, rangeStr) = checkPreconditions(ctx, realModTime, realETag)
        if (done) {
            return
        }

        // Content-Type 必须根据文件扩展名判断，不能读取客户端请求头
        let contentType = getMimeTypeByExt(".${filePath.extensionName}") ?? JoyHttpConsts.MIME_APP_OCTET_STREAM

        if (rangeStr.isEmpty()) {
            sendWholeFile(ctx, filePath, size, contentType)
        } else {
            // 处理Range请求
            handleRangeRequest(ctx, filePath, rangeStr, size, contentType)
        }
    }

    /**
     * 使用 index.html 或目录列表服务目录
     *
     * @param ctx joy 上下文
     * @param dirPath 目录路径
     * @param fileInfo 目录文件信息
     * @throws IOException 如果目录不存在
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
     * 忽略 Range 头，返回完整文件
     */
    private static func sendWholeFile(ctx: JoyContext, filePath: Path, size: Int64, contentType: String): Unit {
        ctx.status(HttpStatusCode.STATUS_OK)
        ctx.header(JoyHttpConsts.HEADER_CONTENT_TYPE, contentType)
        ctx.header(JoyHttpConsts.HEADER_CONTENT_LENGTH, "${size}")
        sendFile(ctx, filePath, 0, size)
    }

    /**
     * 处理 Range 请求
     *
     * @param ctx joy 上下文
     * @param filePath 文件路径
     * @param rangeStr Range 头字符串
     * @param size 文件大小
     * @param contentType 内容类型
     */
    private static func handleRangeRequest(ctx: JoyContext, filePath: Path, rangeStr: String, size: Int64,
        contentType: String): Unit {
        // 解析Range头
        var ranges: JoyHttpRangs
        try {
            ranges = JoyHttpRange.parse(rangeStr, size)
        } catch (e: IllegalArgumentException) {
            // Range解析失败
            if (e.message.indexOf("overlap").isSome()) {
                // 一些客户端会在所有请求中添加Range头限制响应大小。如果文件为空忽略范围头部，直接以200响应而非416。
                ranges = JoyHttpRangs()
            } else {
                ctx.header(JoyHttpConsts.HEADER_CONTENT_RANGE, "bytes */${size}")
                writeError(ctx, "Requested Range Not Satisfiable", HttpStatusCode.STATUS_REQUESTED_RANGE_NOT_SATISFIABLE)
                return
            }
        }

        if (ranges.sumSize() > size) {
            // 所有范围的总字节数大于文件的大小本身，因此这很可能是一次攻击，或一次客户端。忽略范围请求。
            ranges = JoyHttpRangs()
        }

        if (ranges.isEmpty()) {
            // 越界范围或总大小异常时按 RFC 忽略 Range，返回 200 完整文件
            sendWholeFile(ctx, filePath, size, contentType)
            return
        }

        if (ranges.size == 1) {
            // 单个Range请求
            // RFC 7233, Section 4.1:
            // 如果仅传输单个部件，服务器生成206响应必须生成一个Content-Range 头部字段，用于描述范围
            // 所选表示的封装内容，以及一个负载包含范围数据。
            // 服务器必须不生成多部分响应请求单个范围，因为客户端不请求多个部分可能不支持多部分响应
            let r = ranges[0]
            ctx.header(JoyHttpConsts.HEADER_CONTENT_TYPE, contentType)
            ctx.header(JoyHttpConsts.HEADER_CONTENT_LENGTH, "${r.length}")
            ctx.header(JoyHttpConsts.HEADER_ACCEPT_RANGES, "bytes")
            ctx.header(JoyHttpConsts.HEADER_CONTENT_RANGE, r.contentRange(size))
            ctx.status(HttpStatusCode.STATUS_PARTIAL_CONTENT)
            if (ctx.method != JoyHttpConsts.METHOD_HEAD) {
                sendFile(ctx, filePath, r.start, r.length)
            }
        } else {
            // 多个Range请求，返回multipart/byteranges
            let sendSize = ranges.mimeSize(contentType, size)
            ctx.header(JoyHttpConsts.HEADER_CONTENT_LENGTH, "${sendSize}")
            ctx.status(HttpStatusCode.STATUS_PARTIAL_CONTENT)
            if (ctx.method != JoyHttpConsts.METHOD_HEAD) {
                ctx.header(JoyHttpConsts.HEADER_ACCEPT_RANGES, "bytes")
               
                let writer = JoyHttpResponseWriter(ctx)
                let mw = JoyMultiPartWriter(writer)
                func write(buf: Array<Byte>): Unit {
                    mw.writePartData(buf)
                }

                ctx.header(JoyHttpConsts.HEADER_CONTENT_TYPE, "multipart/byteranges; boundary=" + mw.boundary)
                try (file = File(filePath, OpenMode.Read)) {
                    for (ra in ranges) {
                        mw.createPart(ra.mimeHeaders(contentType, size))
                        readFileToWriter(file, ra.start, ra.length, write)
                    }
                    // Close multipart writer to write final boundary
                    mw.close()
                }
            }
        }
    }

    /**
     * 发送文件内容
     *
     * @param ctx joy 上下文
     * @param filePath 文件路径
     * @param offset 读取起始偏移量
     * @param length 读取长度
     */
    private static func sendFile(ctx: JoyContext, filePath: Path, offset: Int64, length: Int64): Unit {
        let writer = JoyHttpResponseWriter(ctx)
        func write(buf: Array<Byte>): Unit {
            writer.write(buf)
        }
        try (file = File(filePath, OpenMode.Read)) {
            readFileToWriter(file, offset, length, write)
        }
    }

    private static func readFileToWriter(file: File, offset: Int64, length: Int64, writer: (buf: Array<Byte>) -> Unit): Unit {
        let buf = Array<Byte>(BUFFER_SIZE, repeat: 0)
        // 跳转到offset (from beginning of file)
        if (offset > 0) {
            file.seek(SeekPosition.Begin(offset))
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
            writer(buf[..actualRead])
            remaining -= actualRead
        }
    }

    /**
     * 检查预条件（If-Match、If-None-Match、If-Modified-Since 等）
     *
     * @param ctx joy 上下文
     * @param modTime 修改时间
     * @param eTag ETag
     * @return (done, rangeHeader) - done 表示响应已发送
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
            match (ifRangeResult) {
                case MatchFalse => return (false, "") // If-Range 不匹配，忽略 Range 头
                case _ => ()
            }
        }
        return (false, rangeHeader)
    }

    /**
     * 检查 If-Match 头
     *
     * @param ctx joy 上下文
     * @param eTag 要检查的 ETag
     * @return 条件结果
     */
    private static func checkIfMatch(ctx: JoyContext, eTag: String): JoyCondResult {
        let ifMatch = ctx.getHeader(JoyHttpConsts.HEADER_IF_MATCH)
        if (ifMatch.isNone() || ifMatch.getOrThrow().isEmpty()) {
            return JoyCondResult.MatchNone
        }

        var value = trimString(ifMatch.getOrThrow())
        // 解析ETag列表
        while (true) {
            if (value.isEmpty()) {
                break
            }
            if (value[0] == b',') {
                value = value[1..]
                continue
            }
            // 检查是否为*
            if (value[0] == b'*') {
                return JoyCondResult.MatchTrue
            }
            // 扫描ETag
            let (tag, remain) = JoyHttpEtag.scan(value)
            if (tag.isEmpty()) {
                break
            }
            if (JoyHttpEtag.strongMatch(tag, eTag)) {
                return JoyCondResult.MatchTrue
            }
            value = remain
        }

        return JoyCondResult.MatchFalse
    }

    /**
     * 检查 If-None-Match 头
     *
     * @param ctx joy 上下文
     * @param eTag 要检查的 ETag
     * @return 条件结果
     */
    private static func checkIfNoneMatch(ctx: JoyContext, eTag: String): JoyCondResult {
        let ifNoneMatch = ctx.getHeader(JoyHttpConsts.HEADER_IF_NONE_MATCH)
        if (ifNoneMatch.isNone() || ifNoneMatch.getOrThrow().isEmpty()) {
            return JoyCondResult.MatchNone
        }

        var value = trimString(ifNoneMatch.getOrThrow())
        // 解析ETag列表
        while (true) {
            if (value.isEmpty()) {
                break
            }
            if (value[0] == b',') {
                value = value[1..]
                continue
            }
            // 检查是否为*
            if (value[0] == b'*') {
                return JoyCondResult.MatchFalse
            }

            // 扫描ETag
            let (tag, remain) = JoyHttpEtag.scan(value)
            if (tag.isEmpty()) {
                break
            }
            if (JoyHttpEtag.weakMatch(tag, eTag)) {
                return JoyCondResult.MatchFalse
            }
            value = remain
        }

        return JoyCondResult.MatchTrue
    }

    /**
     * 检查 If-Modified-Since 头
     *
     * @param ctx joy 上下文
     * @param modTime 修改时间
     * @return 条件结果
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
        if (modTime.toUnixTimeStamp().toSeconds() <= pt.toUnixTimeStamp().toSeconds()) {
            return JoyCondResult.MatchFalse
        }

        return JoyCondResult.MatchTrue
    }

    /**
     * 检查 If-Unmodified-Since 头
     *
     * @param ctx joy 上下文
     * @param modTime 修改时间
     * @return 条件结果
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

        // （忽略秒以下精度）
        let pt = parsedTime.getOrThrow()
        if (modTime.toUnixTimeStamp().toSeconds() <= pt.toUnixTimeStamp().toSeconds()) {
            return JoyCondResult.MatchTrue
        }

        return JoyCondResult.MatchFalse
    }

    /**
     * 检查 If-Range 头
     *
     * @param ctx joy 上下文
     * @param modTime 修改时间
     * @param eTag ETag
     * @return 条件结果
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
        let (tag, _) = JoyHttpEtag.scan(headerValue)
        if (!tag.isEmpty()) {
            if (JoyHttpEtag.strongMatch(tag, eTag)) {
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
        // HTTP 日期只有秒级精度，必须使用秒进行比较
        if (modTime.toUnixTimeStamp().toSeconds() == pt.toUnixTimeStamp().toSeconds()) {
            return JoyCondResult.MatchTrue
        }

        return JoyCondResult.MatchFalse
    }

    /**
     * 设置 Last-Modified 头
     *
     * @param ctx joy 上下文
     * @param modTime 修改时间
     */
    private static func setLastLastModified(ctx: JoyContext, modTime: DateTime): Unit {
        let timeStr = formatHttpTime(modTime)
        ctx.header(JoyHttpConsts.HEADER_LAST_MODIFIED, timeStr)
    }

    /**
     * 将 DateTime 格式化为 HTTP 时间格式
     *
     * @param time 本地日期时间
     * @return 格式化的 HTTP 时间字符串
     */
    private static func formatHttpTime(time: DateTime): String {
        time.format(DateTimeFormat.RFC1123)
    }

    /**
     * 写入 304 Not Modified 响应
     *
     * @param ctx joy 上下文
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
     * 写入错误响应
     *
     * @param ctx joy 上下文
     * @param text 错误文本
     * @param code HTTP 状态码
     */
    private static func writeError(ctx: JoyContext, text: String, code: UInt16): Unit {
        ctx.status(code)
        ctx.string(JoyHttpConsts.MIME_TEXT_PLAIN_UTF8, text)
    }

    /**
     * 构建目录列表 HTML
     *
     * @param dirPath 目录路径
     * @param requestPath 请求 URL 路径
     * @return HTML 字符串
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
        let separator = if (parentPath.endsWith("/")) { "" } else { "/" }
        for (file in files) {
            let name = file.name
            var path = parentPath + separator + name
            var label = name
            if (file.isDirectory()) {
                path += "/"
                label += "/"
            }
            sb.append("<a href=\"${escapeHtml(path)}\">${escapeHtml(label)}</a>\n")
        }

        sb.append("</pre>\n")
        sb.append("</body>\n")
        sb.append("</html>\n")

        sb.toString()
    }

    /**
     * 从 URL 路径获取父路径
     *
     * @param path URL 路径
     * @return 父路径
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
     * 转义 HTML 特殊字符
     *
     * @param str 要转义的字符串
     * @return 转义后的字符串
     */
    private static func escapeHtml(str: String): String {
        str.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;")
    }
}

class JoyHttpResponseWriter <: OutputStream {
    let _writer: HttpResponseWriter
    public init(ctx: JoyContext) {
        _writer = HttpResponseWriter(ctx.httpContext)
    }

    public func write(buffer: Array<Byte>): Unit {
        _writer.write(buffer)
    }
}
