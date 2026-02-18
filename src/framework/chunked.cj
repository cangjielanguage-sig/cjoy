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

import std.io.ByteBuffer
import stdx.net.http.{HttpContext, HttpResponseWriter, HttpStatusCode}
import stdx.encoding.json.stream.{JsonSerializable, JsonWriter}


/**
 * 分块 HTTP 响应写入器的基类
 *
 * 提供写入分块响应的功能，包括正确的 HTTP 头
 * 和结束状态管理。
 */
public open class ChunkedWriter {
    protected let _httpContext: HttpContext
    protected let _httpResponseWriter: HttpResponseWriter
    protected var _end: Bool = false

    /**
     * 创建新的 ChunkedWriter 实例
     *
     * @param httpContext HTTP 响应上下文
     */
    init(httpContext: HttpContext) {
        _httpContext = httpContext
        let responseBuilder = httpContext.responseBuilder
        responseBuilder.status(HttpStatusCode.STATUS_OK)
        responseBuilder.header(JoyHttpConsts.HEADER_TRANSFER_ENCODING, "chunked")
        responseBuilder.header(JoyHttpConsts.HEADER_CONNECTION, "keep-alive")
        _httpResponseWriter = HttpResponseWriter(httpContext)
    }

    /**
     * 向响应添加头信息
     *
     * @param name 头名称
     * @param value 头值
     */
    public func header(name: String, value: String): Unit {
        _httpContext.responseBuilder.header(name, value)
    }

    /**
     * 检查响应是否已结束
     *
     * @throws IllegalStateException 如果尝试在结束响应后发送数据
     */
    protected func checkEnd() {
        if (_end) {
            throw IllegalStateException("already end")
        }
    }

    /**
     * 结束分块响应
     */
    public func end(): Unit {
        _end = true
    }
}

/**
 * 用于写入分块 HTTP 响应的 ChunkedWriter 具体实现
 */
public class JoyChunkedWriter <: ChunkedWriter {
    /**
     * 创建新的 JoyChunkedWriter 实例
     *
     * @param httpContext HTTP 响应上下文
     */
    init(httpContext: HttpContext) {
        super(httpContext)
    }

    /**
     * 将字符串数据写入分块响应并立即发送
     *
     * @param data 要写入的字符串数据
     * @return 此 JoyChunkedWriter 实例，用于方法链式调用
     */
    public func write(data: String): JoyChunkedWriter {
        checkEnd()
        _httpResponseWriter.write(data.toArray())
        this
    }

    /**
     * 将二进制数据写入分块响应并立即发送
     *
     * @param data 要写入的二进制数据
     * @return 此 JoyChunkedWriter 实例，用于方法链式调用
     */
    public func write(data: Array<Byte>): JoyChunkedWriter {
        checkEnd()
        _httpResponseWriter.write(data)
        this
    }

    /**
     * 将 JSON 可序列化数据写入分块响应并立即发送
     *
     * @param data 要写入的 JSON 可序列化数据
     * @return 此 JoyChunkedWriter 实例，用于方法链式调用
     */
    public func writeJson<T>(data: T): JoyChunkedWriter where T <: JsonSerializable {
        let buffer = ByteBuffer()
        let writer = JsonWriter(buffer)
        writer.writeValue(data)
        writer.flush()
        write(buffer.bytes())
    }
}

