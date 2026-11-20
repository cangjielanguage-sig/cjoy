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
import stdx.net.http.{HttpContext, HttpResponseWriter}

/**
 * 服务器发送事件 (SSE) 构建器
 */
public class JoySseBuilder {
    private var _name: ?String = None
    private var _id: ?String = None
    private var _data: ?String = None
    private var _retry: ?UInt = None
    private var _comment: ?String = None

    /**
     * 设置事件名称
     *
     * @param event 事件名称
     * @return 此 JoySseBuilder 实例，用于方法链式调用
     */
    public func event(event: String): JoySseBuilder {
        _name = event
        this
    }

    /**
     * 设置事件 ID
     *
     * @param id 事件 ID
     * @return 此 JoySseBuilder 实例，用于方法链式调用
     */
    public func id(id: String): JoySseBuilder {
        _id = id
        this
    }

    /**
     * 设置事件数据
     *
     * @param data 事件数据
     * @return 此 JoySseBuilder 实例，用于方法链式调用
     */
    public func data(data: String): JoySseBuilder {
        _data = data
        this
    }

    /**
     * 设置重试时间
     *
     * @param retry 重试时间（毫秒）
     * @return 此 JoySseBuilder 实例，用于方法链式调用
     */
    public func retry(retry: UInt): JoySseBuilder {
        _retry = retry
        this
    }

    /**
     * 向事件添加注释
     *
     * @param comment 注释字符串
     * @return 此 JoySseBuilder 实例，用于方法链式调用
     */
    public func comment(comment: String): JoySseBuilder {
        _comment = comment
        this
    }

    /**
     * 构建服务器发送事件字符串
     *
     * @return SSE 格式化字符串
     */
    public func build(): Array<Byte> {
        let buffer: ByteBuffer = ByteBuffer()
        if (let Some(event) <- _name) {
            buffer.write("event: ".toArray())
            buffer.write(event.toArray())
            buffer.writeByte(b'\n')
        }

        if (let Some(id) <- _id) {
            buffer.write("id: ".toArray())
            buffer.write(id.toArray())
            buffer.writeByte(b'\n')
        }

        if (let Some(data) <- _data) {
            // SSE 规范要求多行数据的每一行都带 "data: " 前缀
            for (line in data.split("\n")) {
                buffer.write("data: ".toArray())
                buffer.write(line.trimEnd("\r").toArray())
                buffer.writeByte(b'\n')
            }
        }

        if (let Some(retry) <- _retry) {
            buffer.write("retry: ".toArray())
            buffer.write(retry.toString().toArray())
            buffer.writeByte(b'\n')
        }

        if (let Some(comment) <- _comment) {
            buffer.write(": ".toArray())
            buffer.write(comment.toArray())
            buffer.writeByte(b'\n')
        }

        if (buffer.length > 0) {
            buffer.writeByte(b'\n')
        }
        buffer.bytes()
    }
}

/**
 * 服务器发送事件 (SSE) 写入器
 */
public class JoySseEmitter <: ChunkedWriter {
    init(httpContext: HttpContext) {
        super(httpContext)
        let responseBuilder = httpContext.responseBuilder
        responseBuilder.header(JoyHttpConsts.HEADER_CONTENT_TYPE, JoyHttpConsts.MIME_TEXT_EVENT_STREAM)
        responseBuilder.header(JoyHttpConsts.HEADER_CACHE_CONTROL, "no-cache")
    }

    /**
     * 写入编码为 SSE 的数据
     *
     * @param data 事件
     * @return 此 JoySseEmitter 实例，用于方法链式调用
     */
    public func sendEvent(data: JoySseBuilder): JoySseEmitter {
        checkEnd()
        _httpResponseWriter.write(data.build())
        this
    }
}
