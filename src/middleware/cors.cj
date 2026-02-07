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
 * Function type to check if an origin is allowed
 */
public type AllowOriginFunc = (ctx: JoyContext, origin: String) -> Bool

/**
 * CORS wildcard pattern for origin matching
 */
public class CorsWildcard {
    public CorsWildcard(let prefix: String, let suffix: String) {
    }

    /**
     * check if string matches the wildcard pattern
     *
     * @param str: string to check
     * @return: true if matches, false otherwise
     */
    public func canMatch(str: String): Bool {
        str.size >= prefix.size + suffix.size && str.startsWith(prefix) && str.endsWith(suffix)
    }
}

/**
 * CORS middleware for handling cross-origin requests
 */
public class Cors <: JoyMiddlewareHandler {
    // Set to true when allowed origins contains a "*"
    var _allowedOriginsAll: Bool = false
    // List of allowed origins containing wildcards
    var _allowedWOrigins: ArrayList<CorsWildcard> = ArrayList()

    // AllowedOrigins is a list of origins a cross-domain request can be executed from.
    // If the special "*" value is present in the list, all origins will be allowed.
    // An origin may contain a wildcard (*) to replace 0 or more characters
    // (i.e.: http://*.domain.com). Usage of wildcards implies a small performance penalty.
    // Only one wildcard can be used per origin.
    // Default value is ["*"]
    var _allowedOrigins: ArrayList<String> = ArrayList()

    // AllowOriginFunc is a custom function to validate the origin. It takes the origin
    // as argument and returns true if allowed or false otherwise. If this option is
    // set, the content of AllowedOrigins is ignored.
    let _allowOriginFunc: ?AllowOriginFunc

    // AllowedMethods is a list of methods the client is allowed to use with
    // cross-domain requests. Default value is simple methods (HEAD, GET and POST).
    let _allowedMethods: ArrayList<String>

    // Set to true when allowed headers contains a "*"
    var _allowedHeadersAll: Bool = false

    // AllowedHeaders is list of non simple headers the client is allowed to use with
    // cross-domain requests.
    // If the special "*" value is present in the list, all headers will be allowed.
    // Default value is [] but "Origin" is always appended to the list.
    let _allowedHeaders: ArrayList<String>

    // ExposedHeaders indicates which headers are safe to expose to the API of a CORS API specification
    let _exposedHeaders: Array<String>

    // AllowCredentials indicates whether the request can include user credentials like
    // cookies, HTTP authentication or client side SSL certificates.
    let _allowCredentials: Bool

    // MaxAge indicates how long (in seconds) the results of a preflight request can be cached 
    let _maxAge: Int

    // OptionsPassthrough instructs preflight to let other potential next handlers to
    // process the OPTIONS method. Turn this on if your application handles OPTIONS.
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
