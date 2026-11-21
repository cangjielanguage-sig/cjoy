/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.httpx

import std.io.{InputStream, StringReader}
import stdx.encoding.json.stream.{JsonDeserializable, JsonReader}
import stdx.net.http.{HttpHeaders, HttpResponse}
import cjoy.framework.{JoyHttpConsts}

/**
 * HTTP 响应包装器
 */
public class JoyHttpResponse <: Resource {
    private let _response: HttpResponse
    private var _sseStream: ?JoySSEventStream = None
    private var _isClosed = false
    // 是否已将响应体作为流交给调用方，流式响应关闭时需要释放底层连接
    private var _streaming = false

    /**
     * 创建 HTTP 响应包装器
     *
     * @param response 底层的 HTTP 响应对象
     */
    public JoyHttpResponse(response: HttpResponse) {
        _response = response
    }

    ~init() {
        if (!_isClosed) {
            _response.close()
            _isClosed = true
        }
    }

    /**
     * HTTP 响应状态码
     */
    public prop status: UInt16 {
        get() {
            _response.status
        }
    }

    /**
     * 响应体的文本内容
     */
    public prop text: String {
        get() {
            _response.text
        }
    }

    /**
     * 将响应体解析为 JSON
     *
     * @return 反序列化的 JSON 对象，如果失败则返回 None
     */
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

    /**
     * 响应体的输入流
     */
    public prop data: InputStream {
        get() {
            // 只有长度未知的流式响应需要在关闭时释放连接
            _streaming = _response.bodySize.isNone()
            _response.body
        }
    }

    /**
     * 响应是否包含 JSON 内容
     */
    public prop isJson: Bool {
        get() {
            contentType.startsWith(JoyHttpConsts.MIME_APP_JSON)
        }
    }

    /**
     * 响应头
     */
    public prop headers: HttpHeaders {
        get() {
            _response.headers
        }
    }

    /**
     * 响应的内容类型
     */
    public prop contentType: String {
        get() {
            _response.headers.getFirst(JoyHttpConsts.HEADER_CONTENT_TYPE) ?? ""
        }
    }

    /**
     * 获取事件流
     *
     * @return SSE 事件流
     * @throws IllegalArgumentException 当响应不是事件流时
     */
    public prop eventStream: JoySSEventStream {
        get() {
            if (let Some(ss) <- _sseStream) {
                return ss
            } else {
                if (contentType != JoyHttpConsts.MIME_TEXT_EVENT_STREAM) {
                    throw IllegalArgumentException("the response is not event stream")
                }
                _streaming = true
                let stream = JoySSEventStream(_response.stream)
                _sseStream = stream
                stream
            }
        }
    }

    /**
     * 释放资源
     */
    public func close() {
        if (_isClosed) {
            return
        }
        if (_streaming) {
            // 流式响应由调用方控制读取进度，直接释放底层连接
            _response.close()
        } else {
            // stdx 的 HttpResponse.close() 会关闭连接，即使是已读完并归还连接池的响应。
            // 这里只将未读完的响应体读取到末尾，让 stdx 自动归还连接到连接池。
            try {
                let buffer = Array<Byte>(8192, {_ => 0})
                while (true) {
                    if (_response.body.read(buffer) <= 0) {
                        break
                    }
                }
            } catch (_: Exception) {
                _response.close()
            }
        }
        _isClosed = true
    }

    /**
     * 是否已关闭
     *
     * @return 如果关闭返回为true
     */
    public func isClosed(): Bool {
        _isClosed
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
