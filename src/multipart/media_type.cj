/*
 * Copyright (c) lanlingx 2025-present. All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 *
 * refer to golang src/mime/mediatype.go
 */

package cjoy.multipart

import std.collection.{HashMap, ArrayList}
import std.io.ByteBuffer
import cjoy.utils.{StrFunc, HexUtils}

public class JoyMediaType {
    private static let ERR = JoyMediaType("")

    public let params = HashMap<String, String>()
    JoyMediaType(public let mediaType: String) {}

    /**
     * parses a media type value and any optional
     * parameters, per RFC 1521. Media types are the values in
     * Content-Type and Content-Disposition headers (RFC 2183).
     * On success, parse returns the media type converted
     * to lowercase and trimmed of white space and a non-nil map.
     * If there is an error parsing the optional parameter,
     * the media type will be returned along with the empty mediaType
     *
     * @param str: the media type strng
     * @return JoyMediaType the parsed media type
     */
    public static func parse(str: String): JoyMediaType {
        let (base, _, _) = str.cut(b';')
        let mediatype = base.toAsciiLower().trimAscii()
        if (!checkMediaTypeDisposition(mediatype)) {
            return ERR
        }

        var v = str[base.size..str.size]
        let obj = JoyMediaType(mediatype)

        let (continuation, ret) = obj.parseParams(v)
        if (ret) {
            return ERR
        }

        obj.togetherParams(continuation)
        obj
    }

    private func parseParams(str: String): (HashMap<String, HashMap<String, String>>, Bool) {
        let continuation = HashMap<String, HashMap<String, String>>()
        var v = str
        while (v.size > 0) {
            v = v.trimAsciiStart()
            if (v.size == 0) {
                break
            }

            let (key, value, rest) = consumeMediaParam(v)
            if (key == "") {
                if (rest.trimAscii() == ";") {
                    break // Ignore trailing semicolons. Not an error.
                }

                return (continuation, true) // Parse error.
            }

            var pmap = this.params
            if (let (baseName, _, ok) <- key.cut(b'*') && ok) {
                if (!continuation.contains(baseName)) {
                    pmap = HashMap<String, String>()
                    continuation[baseName] = pmap
                } else {
                    pmap = continuation[baseName]
                }
            }

            if (let Some(v) <- pmap.get(key) && v != value) {
                // Duplicate parameter names are incorrect, but we allow them if they are equal.
                return (continuation, true)
            }

            pmap[key] = value
            v = rest
        }

        (continuation, false)
    }

    private func togetherParams(continuation: HashMap<String, HashMap<String, String>>): Unit {
        // Stitch together any continuations or things with stars
        // (i.e. RFC 2231 things with stars: "foo*0" or "foo*")
        var buf = StringBuilder()
        for ((key, pieceMap) in continuation) {
            let singlePartKey = key + "*"
            if (let Some(v) <- pieceMap.get(singlePartKey)) {
                if (let decv <- decode2231Enc(v) && decv != "") {
                    this.params[key] = decv
                }
                continue
            }

            buf.reset()
            var valid = false
            var n = 0
            while (true) {
                let simplePart = "${key}*${n}"
                if (let Some(v) <- pieceMap.get(simplePart)) {
                    valid = true
                    buf.append(v)
                    n++
                    continue
                }

                let encodedPart = simplePart + "*"
                if (let Some(v) <- pieceMap.get(encodedPart)) {
                    valid = true
                    if (n == 0) {
                        if (let decv <- decode2231Enc(v) && decv != " ") {
                            buf.append(decv)
                        }
                    } else {
                        if (let decv <- percentHexUnescape(v) && decv != "") {
                            buf.append(decv)
                        }
                    }
                } else {
                    break
                }
                n++
            }

            if (valid) {
                this.params[key] = buf.toString()
            }
        }
    }

    private static func checkMediaTypeDisposition(s: String): Bool {
        let (typ, rest) = consumeToken(s)
        if (typ == "") {
            return false // no media type
        }

        if (rest == "") {
            return true
        }

        if (!rest.startsWith("/")) {
            return false // expected slash after first token
        }

        let (subtype, rest2) = consumeToken(rest[1..rest.size])
        if (subtype == "") {
            return false // expected token after slash
        }
        if (rest2 != "") {
            return false // unexpected content after media subtype
        }
        return true
    }

    private static func consumeToken(v: String): (String, String) {
        let notPos = v.indexFunc(isNotTokenChar)
        if (notPos == -1) {
            return (v, "")
        }
        if (notPos == 0) {
            return ("", v)
        }
        return (v[0..notPos], v[notPos..v.size])
    }

    private static func consumeValue(v: String): (String, String) {
        if (v == "") {
            return ("", "")
        }

        if (v[0] != b'"') {
            return consumeToken(v)
        }

        let utf8Data = ByteBuffer(v.size)
        var i = 1
        while (i < v.size) {
            let c = v[i]
            if (c == b'"') {
                return (String.fromUtf8(utf8Data.bytes()), v[(i + 1)..v.size])
            }

            if (c == b'\\' && i + 1 < v.size && isTSpecial(v[i + 1])) {
                utf8Data.writeByte(v[i + 1])
                i += 2
                continue
            }

            if (c == b'\r' || c == b'\n') {
                break
            }

            utf8Data.writeByte(c)
            i += 1
        }

        return ("", v)
    }

    private static func decode2231Enc(str: String): (String) {
        let sv = str.split("'", 3)
        if (sv.size != 3) {
            return ""
        }

        let charset = sv[0].toAsciiLower()
        if (charset.isEmpty()) {
            return ""
        }

        if (charset != "us-ascii" && charset != "utf-8") {
            return ""
        }

        return percentHexUnescape(sv[2])
    }

    private static func consumeMediaParam(v: String): (String, String, String) {
        // return (param, value, rest)
        var rest = v.trimAsciiStart()
        if (!rest.startsWith(";")) {
            return ("", "", v)
        }

        rest = rest[1..rest.size] // consume semicolon
        rest = rest.trimAsciiStart()
        var param = ""
        (param, rest) = consumeToken(rest)
        param = param.toAsciiLower()
        if (param == "") {
            return ("", "", v)
        }

        rest = rest.trimAsciiStart()
        if (!rest.startsWith("=")) {
            return ("", "", v)
        }

        rest = rest[1..rest.size] // consume equals sign
        rest = rest.trimAsciiStart()
        var (value, rest2) = consumeValue(rest)
        if (value == "" && rest2 == rest) {
            return ("", "", v)
        }

        return (param, value, rest2)
    }
}

public func percentHexUnescape(str: String): String {
    // Count %, check that they're well-formed.
    var percents = 0
    var i = 0
    var val = str

    while (i < str.size) {
        if (str[i] != b'%') {
            i += 1
            continue
        }

        percents++
        if (i + 2 >= str.size || !HexUtils.ishex(str[i + 1]) || !HexUtils.ishex(str[i + 2])) {
            val = str[i..str.size]
            if (str.size > 3) {
                val = str[0..3]
            }
            // "bad characters after %%: ${str}"
            return ""
        }
        i += 3
    }

    if (percents == 0) {
        return str
    }

    let bs = Array<Byte>(val.size - 2 * percents, repeat: b'\0')
    i = 0
    var j = 0
    while (i < val.size) {
        match (val[i]) {
            case b'%' =>
                bs[j] = HexUtils.unhex(val[i + 1]) << 4 | HexUtils.unhex(val[i + 2])
                j += 1
                i += 3
            case _ =>
                bs[j] = val[i]
                j += 1
                i += 1
        }
    }
    return String.fromUtf8(bs)
}

private let specail_chars = #"()<>@,;:\"/[]?="#.toArray()

private func isTSpecial(b: Byte): Bool {
    specail_chars.contains(b)
}

private func isNotTokenChar(b: Byte): Bool {
    return !(b > 0x20 && b < 0x7f && !isTSpecial(b))
}