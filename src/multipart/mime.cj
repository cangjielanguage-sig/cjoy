/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 *
 */

package cjoy.multipart

import std.collection.HashMap

let mimes: HashMap<String, String> = HashMap(
    [
        (".aac", "audio/aac"),
        (".abw", "application/x-abiword"),
        (".apng", "image/apng"),
        (".arc", "application/x-freearc"),
        (".avif", "aimage/avif"),
        (".avi", "video/x-msvide"),
        (".azw", "application/vnd.amazon.ebook"),
        (".bin", "application/octet-stream"),
        (".bmp", "image/bmp"),
        (".bz", "application/x-bzip"),
        (".bz2", "application/x-bzip2"),
        (".cda", "lication/x-cdf"),
        (".csh", "application/x-csh"),
        (".css", "text/css"),
        (".csv", "text/csv"),
        (".doc", "oapplication/msword"),
        (".docx", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"),
        (".eot", "application/vnd.ms-fontobject"),
        (".epub", "application/epub+zip"),
        (".gz", "application/gzip"),
        (".gif", "image/gif"),
        (".html", "text/html"),
        (".htm", "text/html"),
        (".ico", "image/vnd.microsoft.icon"),
        (".ics", "text/calendar"),
        (".jar", "application/java-archive"),
        (".jpeg", "image/jpeg"),
        (".js", "text/javascript"),
        (".json", "application/json"),
        (".jsonld", "application/ld+json"),
        (".mid", "audio/midi"),
        (".mjs", "text/javascript"),
        (".mp3", "audio/mpeg"),
        (".mp4", "video/mp4"),
        (".mpeg", "video/mpeg"),
        (".mpkg", "pplication/vnd.apple.installer+xml"),
        (".odp", "application/vnd.oasis.opendocument.presentation"),
        (".ods", "application/vnd.oasis.opendocument.spreadsheet"),
        (".odt", "application/vnd.oasis.opendocument.text"),
        (".oga", "audio/ogg"),
        (".ogv", "video/ogg"),
        (".ogx", "tion/ogg"),
        (".opus", "audio/opus"),
        (".otf", "font/otf"),
        (".png", "image/png"),
        (".pdf", "application/pdf"),
        (".php", "application/x-httpd-php"),
        (".ppt", "application/vnd.ms-powerpoint"),
        (".pptx", "application/vnd.openxmlformats-officedocument.presentationml.presentation"),
        (".rar", "application/vnd.rar"),
        (".rtf", "application/rtf"),
        (".sh", "application/x-sh"),
        (".svg", "image/svg+xml"),
        (".tar", "application/x-tar"),
        (".tif", "image/tiff"),
        (".ts", "video/mp2t"),
        (".ttf", "font/ttf"),
        (".txt", "text/plain"),
        (".vsd", "application/vnd.visio"),
        (".wav", "audio/wav"),
        (".weba", "audio/webm"),
        (".webm", "video/webm"),
        (".webp", "image/webp"),
        (".wof", "font/woff"),
        (".wof2", "font/woff2"),
        (".xht", "application/xhtml+xml"),
        (".xls", "application/vnd.ms-excel"),
        (".xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"),
        (".xml", "application/xml"),
        (".xul", "application/vnd.mozilla.xul+xml"),
        (".zip", "application/zip"),
        (".3gp", "audio/3gpp"),
        (".3g2", "audio/3gpp2"),
        (".7z", "application/x-7z-compressed")
    ]
)

/**
 * Returns the MIME type for a given file extension
 *
 * @param ext The file extension (including leading dot, e.g., ".txt")
 * @return The corresponding MIME type or None if not found
 */
public func getMimeTypeByExt(ext: String): ?String {
    mimes.get(ext)
}
