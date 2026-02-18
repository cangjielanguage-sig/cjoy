/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.middleware

import std.collection.{ArrayList, any, filter, count}
import cjoy.{JoyMiddlewareHandler, JoyRequestHandlerChain, JoyContext, JoyHttpConsts}
import cjoy.log.macros.*

/**
 * 用于检查是否允许某个来源的函数类型
 */
public type AllowOriginFunc = (ctx: JoyContext, origin: String) -> Bool

/**
 * 用于来源匹配的 CORS 通配符模式
 */
public class CorsWildcard {
    public CorsWildcard(let prefix: String, let suffix: String) {
    }

    /**
     * 检查字符串是否匹配通配符模式
     *
     * @param str: 要检查的字符串
     * @return: 如果匹配返回 true，否则返回 false
     */
    public func canMatch(str: String): Bool {
        str.size >= prefix.size + suffix.size && str.startsWith(prefix) && str.endsWith(suffix)
    }
}

/**
 * 用于处理跨域请求的 CORS 中间件
 */
public class Cors <: JoyMiddlewareHandler {
    // 当允许的来源包含 "*" 时设为 true
    var _allowedOriginsAll: Bool = false
    // 包含通配符的允许来源列表
    var _allowedWOrigins: ArrayList<CorsWildcard> = ArrayList()

    // AllowedOrigins 是允许跨域请求来源的列表。
    // 如果列表中存在特殊值 "*"，则允许所有来源。
    // 来源可以包含通配符 (*) 来替换 0 个或多个字符
    //（例如：http://*.domain.com）。使用通配符会带来一定的性能损失。
    // 每个来源只能使用一个通配符。
    // 默认值为 ["*"]
    var _allowedOrigins: ArrayList<String> = ArrayList()

    // AllowOriginFunc 是一个自定义函数，用于验证来源。它接受来源作为参数，
    // 如果允许则返回 true，否则返回 false。如果设置此选项，
    // AllowedOrigins 的内容将被忽略。
    let _allowOriginFunc: ?AllowOriginFunc

    // AllowedMethods 是客户端允许在跨域请求中使用的方法列表。
    // 默认值为简单方法（HEAD、GET 和 POST）。
    let _allowedMethods: ArrayList<String>

    // 当允许的头部包含 "*" 时设为 true
    var _allowedHeadersAll: Bool = false

    // AllowedHeaders 是客户端允许在跨域请求中使用的非简单头部列表。
    // 如果列表中存在特殊值 "*"，则允许所有头部。
    // 默认值为 []，但 "Origin" 始终会被添加到列表中。
    let _allowedHeaders: ArrayList<String>

    // ExposedHeaders 表示哪些头部可以安全地公开给 CORS API 规范
    let _exposedHeaders: Array<String>

    // AllowCredentials 表示请求是否可以包含用户凭据，如
    // cookie、HTTP 认证或客户端 SSL 证书。
    let _allowCredentials: Bool

    // MaxAge 表示预检请求的结果可以缓存的时间（秒）
    let _maxAge: Int

    // OptionsPassthrough 指示预检是否让其他潜在的处理程序
    // 处理 OPTIONS 方法。如果应用程序处理 OPTIONS，则打开此选项。
    let _optionsPassthrough: Bool

    public static func allowAll(): Cors {
        Cors(allowedOrigins: ["*"],
            allowedMethods: [JoyHttpConsts.METHOD_HEAD, JoyHttpConsts.METHOD_GET, JoyHttpConsts.METHOD_POST,
                JoyHttpConsts.METHOD_PUT, JoyHttpConsts.METHOD_PATCH, JoyHttpConsts.METHOD_DELETE],
            allowedHeaders: ["*"], allowCredentials: true)
    }

    public Cors(allowedOrigins!: Array<String> = [], allowOriginFunc!: ?AllowOriginFunc = None,
        allowedMethods!: Array<String> = [], allowedHeaders!: Array<String> = [], exposedHeaders!: Array<String> = [],
        allowCredentials!: Bool = false, maxAge!: Int = 0, optionsPassthrough!: Bool = false) {

        // Allowed Origins
        _allowOriginFunc = allowOriginFunc
        if (allowedOrigins.isEmpty()) {
            if (allowOriginFunc.isNone()) {
                _allowedOriginsAll = true
            }
        } else {
            for (it in allowedOrigins) {
                let origin = it.toAsciiLower()
                if ("*" == origin) {
                    _allowedOriginsAll = true
                    _allowedOrigins.clear()
                    _allowedWOrigins.clear()
                    break
                } else if (let Some(idx) <- origin.indexOf(b'*')) {
                    let w = CorsWildcard(origin[0..idx], origin[idx + 1..])
                    _allowedWOrigins.add(w)
                } else {
                    _allowedOrigins.add(origin)
                }
            }
        }

        // Allowed Methods
        if (allowedMethods.isEmpty()) {
            _allowedMethods = ArrayList([JoyHttpConsts.METHOD_GET, JoyHttpConsts.METHOD_POST, JoyHttpConsts.METHOD_HEAD])
        } else {
            _allowedMethods = ArrayList()
            for (it in allowedMethods) {
                _allowedMethods.add(it.toAsciiUpper())
            }
        }

        // Allowed Headers
        if (allowedHeaders.isEmpty()) {
            _allowedHeaders = ArrayList(
                [JoyHttpConsts.HEADER_ORIGIN, JoyHttpConsts.HEADER_ACCEPT, JoyHttpConsts.HEADER_CONTENT_TYPE])
        } else {
            _allowedHeaders = ArrayList()
            for (it in allowedHeaders) {
                if ("*" == it) {
                    _allowedHeadersAll = true
                    _allowedHeaders.clear()
                    break
                }
                _allowedHeaders.add(parseHeaders(it)[0])
            }
            if (!_allowedHeadersAll) {
                _allowedHeaders.add(JoyHttpConsts.HEADER_ORIGIN)
            }
        }

        _exposedHeaders = exposedHeaders
        _allowCredentials = allowCredentials
        _maxAge = maxAge
        _optionsPassthrough = optionsPassthrough
    }

    public func handle(ctx: JoyContext, chain: JoyRequestHandlerChain): Unit {
        let hasOriginHeader = ctx.getHeader(JoyHttpConsts.HEADER_ORIGIN).isSome()
        if (ctx.method == JoyHttpConsts.METHOD_OPTIONS &&
            ctx.getHeader(JoyHttpConsts.HEADER_ACCESS_CONTROL_REQUEST_METHOD).isSome() && hasOriginHeader) {
            handlePreflight(ctx)
            if (_optionsPassthrough) {
                chain.next(ctx)
            } else {
                ctx.ok()
            }
        } else {
            handleActualRequest(ctx)
            chain.next(ctx)
        }
    }

    private func handlePreflight(ctx: JoyContext): Unit {
        let origin = ctx.getHeader(JoyHttpConsts.HEADER_ORIGIN).getOrThrow()
        if (ctx.method != JoyHttpConsts.METHOD_OPTIONS) {
            return
        }

        ctx.header(JoyHttpConsts.HEADER_VARY, JoyHttpConsts.HEADER_ORIGIN)
        ctx.header(JoyHttpConsts.HEADER_VARY, JoyHttpConsts.HEADER_ACCESS_CONTROL_REQUEST_METHOD)
        ctx.header(JoyHttpConsts.HEADER_VARY, JoyHttpConsts.HEADER_ACCESS_CONTROL_REQUEST_HEADERS)

        if (!isOriginAllowed(ctx, origin)) {
            @JoyLogError("[CORS] Preflight aborted, origin '${origin}' not allowed")
            return
        }

        var method = ""
        if (let Some(m) <- ctx.getHeader(JoyHttpConsts.HEADER_ACCESS_CONTROL_REQUEST_METHOD)) {
            method = m
            if (!isMethodAllowed(method)) {
                @JoyLogError("[CORS] Preflight aborted, method  '${method}' not allowed")
                return
            }
        }

        var reqHeader: Array<String> = Array()
        if (let Some(header) <- ctx.getHeader(JoyHttpConsts.HEADER_ACCESS_CONTROL_REQUEST_HEADERS)) {
            let headers = parseHeaders(header)
            if (!areHeadersAllowed(headers)) {
                @JoyLogError("[CORS] Preflight aborted, headers '${header}' not allowed")
                return
            }
            reqHeader = headers.toArray()
        }

        if (_allowedOriginsAll) {
            ctx.header(JoyHttpConsts.HEADER_ACCESS_CONTROL_ALLOW_ORIGIN, "*")
        } else {
            ctx.header(JoyHttpConsts.HEADER_ACCESS_CONTROL_ALLOW_ORIGIN, origin)
        }
        if (method != "") {
            ctx.header(JoyHttpConsts.HEADER_ACCESS_CONTROL_ALLOW_METHODS, method.toAsciiUpper())
        }
        if (!reqHeader.isEmpty()) {
            ctx.header(JoyHttpConsts.HEADER_ACCESS_CONTROL_ALLOW_HEADERS, String.join(reqHeader, delimiter: ", "))
        }
        if (_allowCredentials) {
            ctx.header(JoyHttpConsts.HEADER_ACCESS_CONTROL_ALLOW_CREDENTIALS, "true")
        }
        if (_maxAge > 0) {
            ctx.header(JoyHttpConsts.HEADER_ACCESS_CONTROL_MAX_AGE, "${_maxAge}")
        }
    }

    private func handleActualRequest(ctx: JoyContext): Unit {
        let originOpt = ctx.getHeader(JoyHttpConsts.HEADER_ORIGIN)
        ctx.header(JoyHttpConsts.HEADER_VARY, JoyHttpConsts.HEADER_ORIGIN)
        if (originOpt.isNone()) {
            @JoyLogError("[CORS] Actual request no headers added, missing origin")
            return
        }

        let origin = originOpt.getOrThrow()
        if (!isOriginAllowed(ctx, origin)) {
            @JoyLogError("[CORS] Actual request no headers added, origin '${origin}' not allowed")
            return
        }

        if (!isMethodAllowed(ctx.method)) {
            @JoyLogError("[CORS] Actual request no headers added, method  '${ctx.method}' not allowed")
            return
        }

        if (_allowedOriginsAll) {
            ctx.header(JoyHttpConsts.HEADER_ACCESS_CONTROL_ALLOW_ORIGIN, "*")
        } else {
            ctx.header(JoyHttpConsts.HEADER_ACCESS_CONTROL_ALLOW_ORIGIN, origin)
        }
        if (_exposedHeaders.size > 0) {
            ctx.header(JoyHttpConsts.HEADER_ACCESS_CONTROL_EXPOSE_HEADERS, String.join(_exposedHeaders, delimiter: ", "))
        }
        if (_allowCredentials) {
            ctx.header(JoyHttpConsts.HEADER_ACCESS_CONTROL_ALLOW_CREDENTIALS, "true")
        }
    }

    private func isMethodAllowed(method: String): Bool {
        if (_allowedMethods.isEmpty()) {
            return false
        }

        let m = method.toAsciiUpper()
        if (m == JoyHttpConsts.METHOD_OPTIONS) {
            // Always allow preflight requests
            return true
        }

        _allowedMethods |> any {it => it == m}
    }

    private func isOriginAllowed(ctx: JoyContext, origin: String): Bool {
        if (let Some(fn) <- _allowOriginFunc) {
            return fn(ctx, origin)
        }

        if (_allowedOriginsAll) {
            return true
        }

        let lowerOrigin = origin.toAsciiLower()
        (_allowedOrigins |> any {it => it == lowerOrigin}) || (_allowedWOrigins |> any {it => it.canMatch(lowerOrigin)})
    }

    private func areHeadersAllowed(headers: Collection<String>): Bool {
        if (_allowedHeadersAll || headers.isEmpty()) {
            return true
        }
        for (h in headers) {
            var found = _allowedHeaders |> any {it => it == h}
            if (!found) {
                return false
            }
        }
        true
    }
}

private const TO_LOWER = b'a' - b'A'

private func toUpper(b: Byte): Byte {
    if (b >= b'a' && b <= b'z') {
        return b - TO_LOWER
    }
    b
}

private func toLower(b: Byte): Byte {
    if (b >= b'A' && b <= b'Z') {
        return b + TO_LOWER
    }
    b
}

func parseHeaders(headers: String): ArrayList<String> {
    if (headers.isEmpty()) {
        return ArrayList()
    }

    let h: ArrayList<Byte> = ArrayList(headers.size)
    var upper = true
    let harr = headers.toArray()
    var num = harr |> filter {it => it == b','} |> count
    let res: ArrayList<String> = ArrayList(num)

    for (b in harr) {
        if (b >= b'a' && b <= b'z') {
            if (upper) {
                h.add(toUpper(b))
                upper = false
            } else {
                h.add(b)
            }
        } else if (b >= b'A' && b <= b'Z') {
            if (!upper) {
                h.add(toLower(b))
            } else {
                h.add(b)
                upper = false
            }
        } else if (b == b'-') {
            h.add(b)
            upper = true
        } else if (b == b'_' || b == b'.' || (b >= b'0' && b <= b'9')) {
            h.add(b)
        }

        if (b == b' ' || b == b',') {
            if (h.size > 0) {
                res.add(String.fromUtf8(h.toArray()))
                h.clear()
                upper = true
            }
        }
    }

    if (h.size > 0) {
        res.add(String.fromUtf8(h.toArray()))
    }

    res
}
