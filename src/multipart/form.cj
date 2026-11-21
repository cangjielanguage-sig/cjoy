/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights reserved.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.multipart

import std.collection.HashMap
import stdx.net.http.HttpRequest
import cjoy.framework.{JoyContext, JoyHttpConsts}

/**
 * 多部分表单数据处理器
 *
 * JoyMultiPartForm 提供解析和处理多部分表单数据请求的功能。
 * 它支持部分的内存储存和基于磁盘的存储。
 */
public class JoyMultiPartForm <: JoyMultiPartHandler & Resource & Iterable<JoyMultiPart> {
    private let _handlers = HashMap<String, JoyMultiPartHandler>()
    private var _parser: ?JoyMultiPartParser = None
    private var _memoryHandler: ?JoyMemoryMultiPartHandler = None
    private var _diskHandler: ?JoyDiskMultiPartHandler = None
    private var _isClosed = false

    /**
     * 创建 MultiPartForm 来解析多部分请求
     *
     * @param ctx 上下文
     * @param config 多部分配置
     * @throws MultiPartParseException 如果解析多部分失败
     */
    public static func create(ctx: JoyContext, config: JoyMultiPartConfig): JoyMultiPartForm {
        create(ctx.httpContext.request, config)
    }

    /**
     * 创建 MultiPartForm 来解析多部分请求
     *
     * @param request HTTP 请求
     * @param config 多部分配置
     * @throws MultiPartParseException 如果解析多部分失败
     */
    public static func create(request: HttpRequest, config: JoyMultiPartConfig): JoyMultiPartForm {
        if (let Some(header) <- request.headers.getFirst(JoyHttpConsts.HEADER_CONTENT_TYPE)) {
            let prefix = "multipart/form-data"
            let lower = header.toAsciiLower()
            if (!lower.startsWith(prefix) ||
                (lower.size > prefix.size && lower[prefix.size] != b';' && lower[prefix.size] != b' ')) {
                return JoyMultiPartForm()
            }

            let mtype = JoyMediaType.parse(header)
            if (mtype.mediaType == "") {
                throw MultiPartParseException("invalid content-type header: ${header}")
            }

            if (let Some(boundary) <- mtype.params.get("boundary")) {
                return createForm(request, config, boundary)
            } else {
                throw MultiPartParseException("not found boundary in header: ${header}")
            }
        }
        return JoyMultiPartForm()
    }

    private static func createForm(request: HttpRequest, config: JoyMultiPartConfig, boundary: String): JoyMultiPartForm {
        let form = JoyMultiPartForm()
        form._parser = JoyMultiPartParser(config, form, request.body, boundary)
        form
    }

    /**
     * 解析多部分部分
     */
    public func parse(): Unit {
        _parser?.parseParts()
    }

    /**
     * 当 content-type 是 `multipart/form-data` 时返回 true
     */
    public prop isFormData: Bool {
        get() {
            _parser.isSome()
        }
    }

    /**
     * 根据名称获取多部分信息
     *
     * @param name 部分的名称
     * @return JoyMultiPart 实例，如果未找到则返回 None
     */
    public func getPart(name: String): ?JoyMultiPart {
        _parser?.getPart(name) ?? None
    }

    /**
     * 遍历多部分部分
     *
     * @return JoyMultiPart 的迭代器
     * @throws IllegalStateException 如果解析多部分失败
     */
    public func iterator(): Iterator<JoyMultiPart> {
        if (let Some(p) <- _parser) {
            return p.iterator()
        }
        throw IllegalStateException("parse multipart error, can't iterate the multi parts")
    }

    public func onPart(part: JoyMultiPart, data: Array<Byte>): Unit {
        // if the user registers a handler, prioritize calling the handler
        if (let Some(handler) <- _handlers.get(part.name)) {
            handler.onPart(part, data)
            return
        }

        if (part.fileName != "") {
            saveFile(part, data)
        } else {
            saveToMem(part, data)
        }
    }

    private func saveToMem(part: JoyMultiPart, data: Array<Byte>): Unit {
        if (_memoryHandler.isNone()) {
            let config = _parser.getOrThrow()._config
            _memoryHandler = JoyMemoryMultiPartHandler(config)
        }
        _memoryHandler?.onPart(part, data)
    }

    private func saveFile(part: JoyMultiPart, data: Array<Byte>) {
        // cache the file in cache dir
        let config = _parser.getOrThrow()._config
        if (_diskHandler.isNone() && config.fileCacheDir != "") {
            _diskHandler = JoyDiskMultiPartHandler(config)
        }

        if (config.fileCacheDir != "") {
            _diskHandler?.onPart(part, data)
        } else {
            saveToMem(part, data)
        }
    }

    /**
     * 注册一个处理器来保存 MultiPart 的主体
     *
     * @param name MultiPart 的名称
     * @param handler 主体的处理器
     */
    public func handlePart(name: String, handler: JoyMultiPartHandler) {
        _handlers.add(name, handler)
    }

    /**
     * 注册一个处理器来保存 MultiPart 的主体
     *
     * @param name MultiPart 的名称
     * @param handler 主体的处理器
     */
    public func handlePart(name: String, handler: (JoyMultiPart, Array<Byte>) -> Unit) {
        handlePart(name, JoyMultiPartFuncHandler(handler))
    }

    /**
     * 清除临时文件
     */
    public func close(): Unit {
        if (_isClosed) {
            return
        }
        _diskHandler?.close()
        _memoryHandler?.close()
        _isClosed = true
    }

    public func isClosed(): Bool {
        _isClosed
    }
}
