/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.httpx

import std.collection.{Map, HashMap}
import std.io.{InputStream, StringReader, ByteBuffer}
import stdx.encoding.json.stream.{JsonDeserializable, JsonSerializable, JsonReader, JsonWriter}
import stdx.net.http.{HttpHeaders, HttpResponse, HttpRequestBuilder}
import cjoy.context.Context
import cjoy.framework.{JoyHttpConsts}

/*
 * the http reponse wrapper
 */
public class JoyHttpResponse {
    private let _response: HttpResponse

    public JoyHttpResponse(response: HttpResponse) {
        _response = response
    }

    public prop status: UInt16 {
        get() {
            _response.status
        }
    }

    public prop text: String {
        get() {
            _response.text
        }
    }

    public func json<T>(): ?T where T <: JsonDeserializable<T> {
        if (_response.bodySize.isSome() && _response.bodySize.getOrThrow() == 0) {
            return None
        }
        if (!contentType.startsWith(JoyHttpConsts.MIME_APP_JSON)) {
            return None
        }
        let reader = JsonReader(_response.body)
        T.fromJson(reader)
    }

    public prop data: InputStream {
        get() {
            _response.body
        }
    }

    public prop isJson: Bool {
        get() {
            contentType.startsWith(JoyHttpConsts.MIME_APP_JSON)
        }
    }

    public prop header: HttpHeaders {
        get() {
            _response.headers
        }
    }

    public prop contentType: String {
        get() {
            _response.headers.getFirst(JoyHttpConsts.HEADER_CONTENT_TYPE) ?? ""
        }
    }

    public prop eventStream: JoySSEventStream {
        get() {
            if (contentType != JoyHttpConsts.MIME_TEXT_EVENT_STREAM) {
                throw IllegalArgumentException("the reponse is not event stream")
            }
            JoySSEventStream(_response.stream)
        }
    }
}

extend HttpResponse {
    public prop text: String {
        get() {
            let reader = StringReader(this.body)
            reader.readToEnd()
        }
    }

    public prop stream: JoyHttpStream {
        get() {
            let httpStream = JoyHttpStream()
            if (this.status >= 300) {
                httpStream.markError(this.text)
            } else {
                spawn {
                    let buffer = Array<Byte>(1024 * 10, {_ => 0})
                    while (true) {
                        let length = this.body.read(buffer)
                        if (length == 0) {
                            httpStream.markEOF()
                            break
                        } else {
                            httpStream.put(buffer[..length])
                        }
                    }
                }
            }
            return httpStream
        }
    }
}
