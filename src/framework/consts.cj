/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.framework

/**
 * HTTP 常量，包括方法名称、内容类型和头名称
 */
public struct JoyHttpConsts {
    // method
    public static const METHOD_POST: String = "POST"
    public static const METHOD_GET: String = "GET"
    public static const METHOD_PUT: String = "PUT"
    public static const METHOD_PATCH: String = "PATCH"
    public static const METHOD_DELETE: String = "DELETE"
    public static const METHOD_HEAD: String = "HEAD"
    public static const METHOD_OPTIONS: String = "OPTIONS"

    // content-type
    public static const MIME_APP_JSON: String = "application/json"
    public static const MIME_APP_JSON_UTF8: String = "application/json; charset=utf-8"
    public static const MIME_TEXT_EVENT_STREAM: String = "text/event-stream"
    public static const MIME_TEXT_PLAIN: String = "text/plain"
    public static const MIME_TEXT_PLAIN_UTF8: String = "text/plain; charset=utf-8"
    public static const MIME_APP_OCTET_STREAM: String = "application/octet-stream"
    public static const MIME_APP_FORM_URL_ENCODED: String = "application/x-www-form-urlencoded"

    // header
    public static const HEADER_ACCEPT: String = "Accept"
    public static const HEADER_ACCEPT_CH: String = "Accept-CH"
    public static const HEADER_ACCEPT_CHARSET: String = "Accept-Charset"
    public static const HEADER_ACCEPT_ENCODING: String = "Accept-Encoding"
    public static const HEADER_ACCEPT_LANGUAGE: String = "Accept-Language"
    public static const HEADER_ACCEPT_CH_LIFETIME: String = "Accept-CH-Lifetime"
    public static const HEADER_ACCEPT_PATCH: String = "Accept-Patch"
    public static const HEADER_ACCEPT_PUSH_POLICY: String = "Accept-Push-Policy"
    public static const HEADER_ACCEPT_SIGNATURE: String = "Accept-Signature"
    public static const HEADER_ACCEPT_RANGES: String = "Accept-Ranges"
    public static const HEADER_ACCESS_CONTROL_ALLOW_PRIVATE_NETWORK: String = "Access-Control-Allow-Private-Network"
    public static const HEADER_ACCESS_CONTROL_REQUEST_PRIVATE_NETWORK: String = "Access-Control-Request-Private-Network"
    public static const HEADER_ACCESS_CONTROL_ALLOW_CREDENTIALS: String = "Access-Control-Allow-Credentials"
    public static const HEADER_ACCESS_CONTROL_ALLOW_HEADERS: String = "Access-Control-Allow-Headers"
    public static const HEADER_ACCESS_CONTROL_ALLOW_METHODS: String = "Access-Control-Allow-Methods"
    public static const HEADER_ACCESS_CONTROL_ALLOW_ORIGIN: String = "Access-Control-Allow-Origin"
    public static const HEADER_ACCESS_CONTROL_EXPOSE_HEADERS: String = "Access-Control-Expose-Headers"
    public static const HEADER_ACCESS_CONTROL_MAX_AGE: String = "Access-Control-Max-Age"
    public static const HEADER_ACCESS_CONTROL_REQUEST_HEADERS: String = "Access-Control-Request-Headers"
    public static const HEADER_ACCESS_CONTROL_REQUEST_METHOD: String = "Access-Control-Request-Method"
    public static const HEADER_ALT_SVC: String = "Alt-Svc"
    public static const HEADER_ALLOW: String = "Allow"
    public static const HEADER_AGE: String = "Age"
    public static const HEADER_AUTHORIZATION: String = "Authorization"

    public static const HEADER_CACHE_CONTROL: String = "Cache-Control"
    public static const HEADER_CONTENT_DPR: String = "Content-DPR"
    public static const HEADER_CONNECTION: String = "Connection"
    public static const HEADER_CONTENT_DISPOSITION: String = "Content-Disposition"
    public static const HEADER_CONTENT_ENCODING: String = "Content-Encoding"
    public static const HEADER_CONTENT_LANGUAGE: String = "Content-Language"
    public static const HEADER_CONTENT_LENGTH: String = "Content-Length"
    public static const HEADER_CONTENT_LOCATION: String = "Content-Location"
    public static const HEADER_CONTENT_TYPE: String = "Content-Type"
    public static const HEADER_CONTENT_RANGE: String = "Content-Range"
    public static const HEADER_COOKIE: String = "Cookie"
    public static const HEADER_CONTENT_SECURITY_POLICY: String = "Content-Security-Policy"
    public static const HEADER_CONTENT_SECURITY_POLICY_REPORT_ONLY: String = "Content-Security-Policy-Report-Only"
    public static const HEADER_CLEAR_SITE_DATA: String = "Clear-Site-Data"
    public static const HEADER_CROSS_ORIGIN_RESOURCE_POLICY: String = "Cross-Origin-Resource-Policy"

    public static const HEADER_DPR: String = "DPR"
    public static const HEADER_DNT: String = "DNT"
    public static const HEADER_DATE: String = "Date"

    public static const HEADER_EXPIRES: String = "Expires"
    public static const HEADER_EARLY_DATA: String = "Early-Data"
    public static const HEADER_ETAG: String = "ETag"
    public static const HEADER_EXPECT_CT: String = "Expect-CT"
    public static const HEADER_EXPECT: String = "Expect"

    public static const HEADER_FROM: String = "From"
    public static const HEADER_FORWARDED: String = "Forwarded"

    public static const HEADER_KEEP_ALIVE: String = "Keep-Alive"
    public static const HEADER_ORIGIN: String = "Origin"
    public static const HEADER_HOST: String = "Host"

    public static const HEADER_IF_MATCH: String = "If-Match"
    public static const HEADER_IF_MODIFIED_SINCE: String = "If-Modified-Since"
    public static const HEADER_IF_NONE_MATCH: String = "If-None-Match"
    public static const HEADER_IF_UNMODIFIED_SINCE: String = "If-Unmodified-Since"
    public static const HEADER_IF_RANGE: String = "If-Range"
    public static const HEADER_INDEX: String = "Index"

    public static const HEADER_LAST_MODIFIED: String = "Last-Modified"
    public static const HEADER_LARGE_ALLOCATION: String = "Large-Allocation"
    public static const HEADER_LINK: String = "Link"
    public static const HEADER_LAST_EVENT_ID: String = "Last-Event-ID"
    public static const HEADER_LOCATION: String = "Location"

    public static const HEADER_REFERER: String = "Referer"
    public static const HEADER_REFERRER_POLICY: String = "Referrer-Policy"
    public static const HEADER_PRAGMA: String = "Pragma"
    public static const HEADER_PROXY_AUTHENTICATE: String = "Proxy-Authenticate"
    public static const HEADER_PROXY_AUTHORIZATION: String = "Proxy-Authorization"
    public static const HEADER_PING_FROM: String = "Ping-From"
    public static const HEADER_PING_TO: String = "Ping-To"
    public static const HEADER_PUSH_POLICY: String = "Push-Policy"
    public static const HEADER_PERMISSIONS_POLICY: String = "Permissions-Policy"
    public static const HEADER_PUBLIC_KEY_PINS: String = "Public-Key-Pins"
    public static const HEADER_PUBLIC_KEY_PINS_REPORT_ONLY: String = "Public-Key-Pins-Report-Only"
    public static const HEADER_REPORT_TO: String = "Report-To"
    public static const HEADER_RETRY_AFTER: String = "Retry-After"
    public static const HEADER_RANGE: String = "Range"

    public static const HEADER_USER_AGENT: String = "User-Agent"
    public static const HEADER_UPGRADE: String = "Upgrade"
    public static const HEADER_UPGRADE_INSECURE_REQUESTS: String = "Upgrade-Insecure-Requests"
    public static const HEADER_VIEWPORT_WIDTH: String = "Viewport-Width"
    public static const HEADER_VIA: String = "Via"
    public static const HEADER_VARY: String = "Vary"
    public static const HEADER_WWW_AUTHENTICATE: String = "WWW-Authenticate"
    public static const HEADER_WARNING: String = "Warning"
    public static const HEADER_WIDTH: String = "Width"

    public static const HEADER_NEL: String = "NEL"
    public static const HEADER_MAX_FORWARDS: String = "Max-Forwards"

    public static const HEADER_TE: String = "TE"
    public static const HEADER_TK: String = "Tk"
    public static const HEADER_TRAILER: String = "Trailer"
    public static const HEADER_TRANSFER_ENCODING: String = "Transfer-Encoding"
    public static const HEADER_TIMING_ALLOW_ORIGIN: String = "Timing-Allow-Origin"

    public static const HEADER_SEC_WEBSOCKET_ACCEPT: String = "Sec-WebSocket-Accept"
    public static const HEADER_SEC_WEBSOCKET_EXTENSIONS: String = "Sec-WebSocket-Extensions"
    public static const HEADER_SEC_WEBSOCKET_KEY: String = "Sec-WebSocket-KeY"
    public static const HEADER_SEC_WEBSOCKET_PROTOCOL: String = "Sec-WebSocket-Protocol"
    public static const HEADER_SEC_WEBSOCKET_VERSION: String = "Sec-WebSocket-Version"
    public static const HEADER_STRICT_TRANSPORT_SECURITY: String = "Strict-Transport-Security"
    public static const HEADER_SERVER: String = "Server"
    public static const HEADER_SAVE_DATA: String = "Save-Data"
    public static const HEADER_SERVER_TIMING: String = "Server-Timing"
    public static const HEADER_SIGNATURE: String = "Signature"
    public static const HEADER_SIGNED_HEADERS: String = "Signed-HEADER_s"
    public static const HEADER_SOURCE_MAP: String = "SourceMap"
    public static const HEADER_SET_COOKIE: String = "Set-Cookie"

    public static const HEADER_X_CONTENT_TYPE_OPTIONS: String = "X-Content-Type-Options"
    public static const HEADER_X_DOWNLOAD_OPTIONS: String = "X-Download-Options"
    public static const HEADER_X_FRAME_OPTIONS: String = "X-Frame-Options"
    public static const HEADER_X_POWERED_BY: String = "X-Powered-By"
    public static const HEADER_X_XSS_PROTECTION: String = "X-XSS-Protection"
    public static const HEADER_X_FORWARDED_FOR: String = "X-Forwarded-For"
    public static const HEADER_X_FORWARDED_HOST: String = "X-Forwarded-Host"
    public static const HEADER_X_FORWARDED_PROTO: String = "X-Forwarded-Proto"
    public static const HEADER_X_FORWARDED_PROTOCOL: String = "X-Forwarded-Protocol"
    public static const HEADER_X_FORWARDED_SSL: String = "X-Forwarded-Ssl"
    public static const HEADER_X_URL_SCHEME: String = "X-Url-Scheme"
    public static const HEADER_X_DNS_PREFETCH_CONTROL: String = "X-DNS-Prefetch-Control"
    public static const HEADER_X_PINGBACK: String = "X-Pingback"
    public static const HEADER_X_REQUEST_ID: String = "X-Request-ID"
    public static const HEADER_X_REQUESTED_WITH: String = "X-Requested-With"
    public static const HEADER_X_ROBOTS_TAG: String = "X-Robots-Tag"
    public static const HEADER_X_UA_COMPATIBLE: String = "X-UA-Compatible"
    public static const HEADER_X_PERMITTED_CROSS_DOMAIN_POLICIES: String = "X-Permitted-Cross-Domain-Policies"
}
