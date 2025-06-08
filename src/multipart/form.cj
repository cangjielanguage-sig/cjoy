/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.multipart

import std.collection.HashMap
import std.fs.File
import stdx.net.http.HttpRequest
import cjoy.JoyContext

public class JoyMultiPartForm <: JoyMultiPartHandler & Resource & Iterable<JoyMultiPart> {
    private static let INSTANCE: JoyMultiPartForm = JoyMultiPartForm()

    private let handlers = HashMap<String, JoyMultiPartHandler>()
    private var _parser: ?JoyMultiPartParser = None
    private var _memoryHandler: ?JoyMemoryMultiPartHandler = None
    private var _diskHandler: ?JoyDiskMultiPartHandler = None
    private var _isClosed = false

    /**
     * create the MultiPartForm to parsee the multipart
     *
     * @param ctx: the context
     * @param config: the multi part config
     */
    public static func create(ctx: JoyContext, config: JoyMultiPartConfig): JoyMultiPartForm {
        create(ctx.httpContext.request, config)
    }

    /**
     * create the MultiPartForm to parsee the multipart
     *
     * @param request: the http request
     * @param config: the multi part config
     */
    public static func create(request: HttpRequest, config: JoyMultiPartConfig): JoyMultiPartForm {
        if (let Some(header) <- request.headers.getFirst("Content-Type")) {
            if (!header.startsWith("multipart/form-data")) {
                return JoyMultiPartForm.INSTANCE
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
        return JoyMultiPartForm.INSTANCE
    }

    private static func createForm(request: HttpRequest, config: JoyMultiPartConfig, boundary: String): JoyMultiPartForm {
        let form = JoyMultiPartForm()
        form._parser = JoyMultiPartParser(config, form, request.body, boundary)
        form
    }

    /**
    * parse the multi parts
    */
    public func parse(): Unit {
        _parser?.parseParts()
    }

    /**
     * return true when content-type is `multipart/form-data`
     */
    public prop isFormData: Bool {
        get() {
            _parser.isSome()
        }
    }

    /**
     * return multi part info
     */
    public func getPart(name: String): ?JoyMultiPart {
        _parser?.getPart(name) ?? None
    }

    /**
     * iterate the multi part
     */
    public func iterator(): Iterator<JoyMultiPart> {
        if (let Some(p) <- _parser) {
            return p.iterator()
        }
        throw IllegalStateException("parse multipart error, can't iterate the multi parts")
    }

    public func onPart(part: JoyMultiPart, data: Array<Byte>): Unit {
        // if the user registers a handler, prioritize calling the handler
        if (let Some(handler) <- handlers.get(part.name)) {
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
     * register a handler to save the body of MultiPart
     *
     * @param name: the name of MultiPart
     * @param handler: the handler of body
     */
    public func handlePart(name: String, handler: JoyMultiPartHandler) {
        handlers.add(name, handler)
    }

    /**
     * register a handler to save the body of MultiPart
     *
     * @param name: the name of MultiPart
     * @param handler: the handler of body
     */
    public func handlePart(name: String, handler: (JoyMultiPart, Array<Byte>) -> Unit) {
        handlePart(name, JoyMultiPartFuncHandler(handler))
    }

    /**
     * clear the temp file
     */
    public func close() {
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
