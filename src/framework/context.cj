/*
 * Copyright (c) lanlingx 2024-present. All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

package cjoy.framework

import std.collection.{HashMap, ArrayList}
import std.io.{InputStream, ByteBuffer, copy, StringReader}
import std.net.IPAddress
import log.Logger
import net.http.{HttpContext, RedirectHandler, NotFoundHandler, HttpStatusCode, HttpResponseBuilder, Cookie}
import encoding.json.stream.{JsonDeserializable, JsonSerializable, JsonReader, JsonWriter}

/**
 * the context which holds the engine config, params, context params and any you need.
 */
public class JoyContext {
    var _httpContext: HttpContext
    private let _config: JoyConfig
    private let _paramMap: HashMap<String, String>
    private let _ctxParamMap: HashMap<String, Any>
    private var _cookieCache: HashMap<String, String> = HashMap()

    // the index of executing handler chain
    var _handlerIndex: Int = 0

    init(httpContext: HttpContext, paramMap: HashMap<String, String>, config: JoyConfig,
        ctxParamMap: HashMap<String, Any>) {
        _httpContext = httpContext
        _config = config
        _paramMap = paramMap
        _ctxParamMap = ctxParamMap
    }

    func reset() {
        _paramMap.clear()
        _ctxParamMap.clear()
        _cookieCache.clear()
        _handlerIndex = 0
    }

    func copyParams(): HashMap<String, String> {
        _paramMap.clone()
    }

    func copyCtxParams(): HashMap<String, Any> {
        _ctxParamMap.clone()
    }

    /**
     * return the http context
     */
    public prop httpContext: HttpContext {
        get() {
            _httpContext
        }
    }

    /**
     * return the logger which is set by ServerBuilder
     */
    public prop logger: Logger {
        get() {
            _config.logger
        }
    }

    /**
     * return the engine config
     */
    public prop config: JoyConfig {
        get() {
            _config
        }
    }

    /**
     * set param in context
     *
     * @param key: the param key name
     * @param value: the param value
     *
     */
    public func setCtxParam(key: String, value: Any): Unit {
        _ctxParamMap.add(key, value)
    }

    /**
     * get param from context
     *
     * @param key: the param key name
     * @return the param value
     *
     */
    public func getCtxParm<T>(key: String): ?T {
        let val = _ctxParamMap.get(key)
        match (val) {
            case Some(v) => v as T
            case _ => None
        }
    }

    /**
     * get url path param from context
     *
     * @param name: the param name
     * @return the param value
     *
     */
    public func getParam(name: String): ?String {
        _paramMap.get(name)
    }

    /**
     * add url path param in context
     *
     * @param name: the param name
     * @param value: the param value
     *
     */
    public func addParam(name: String, value: String): Unit {
        _paramMap.add(name, value)
    }

    /**
     * get url query param from context
     *
     * @param name: the param name
     * @return the param value
     *
     */
    public func getQuery(name: String): ?String {
        _httpContext.request.url.queryForm.get(name)
    }

    /**
     * get url query param from context
     *
     * @param name: the param name
     * @param defaultValue: the default value when it not existed
     * @return the param value
     *
     */
    public func getQuery(name: String, defaultValue: String): String {
        let val = _httpContext.request.url.queryForm.get(name)
        val.getOrDefault({=> defaultValue})
    }

    /**
     * get url query param from context
     *
     * @param name: the param name
     * @return the param value list
     *
     */
    public func getQueryList(name: String): ArrayList<String> {
        _httpContext.request.url.queryForm.getAll(name)
    }

    /**
     * get post form param from context
     *
     * @param name: the param name
     * @return the param value
     *
     */
    public func getPostForm(name: String): ?String {
        _httpContext.request.form.get(name)
    }

    /**
     * get post form param from context
     *
     * @param name: the param name
     * @param defaultValue: the default value when it not existed
     * @return the param value
     *
     */
    public func getPostForm(name: String, defaultValue: String): String {
        let val = _httpContext.request.form.get(name)
        val.getOrDefault({=> defaultValue})
    }

    /**
     * get post form param from context
     *
     * @param name: the param name
     * @return the param value list
     *
     */
    public func getPostFormList(name: String): ArrayList<String> {
        _httpContext.request.form.getAll(name)
    }

    /**
     * read the request json body content then deserialize to T
     *
     * @return the object of T
     */
    public func readJson<T>(): ?T where T <: JsonDeserializable<T> {
        if (_httpContext.request.bodySize.isSome() && _httpContext.request.bodySize.getOrThrow() == 0) {
            return None
        }
        if (!getContentType().startsWith("application/json")) {
            return None
        }

        let buffer = ByteBuffer()
        let reader = JsonReader(_httpContext.request.body)
        T.fromJson(reader)
    }

    /**
     * read the request body content into byte array
     *
     * @return the object of byte array
     */
    public func readRawData(): Array<Byte> {
        let buffer = ByteBuffer()
        copy(_httpContext.request.body, to: buffer)
        buffer.bytes()
    }

    /**
     * read the request body content into string
     *
     * @return the object of string
     */
    public func readString(): String {
        let reader = StringReader(_httpContext.request.body)
        reader.readToEnd()
    }

    /**
     *
     * read the query form and bind to object
     *
     * @return the object of JoyBindable
     */
    public func bindQuery<T>(): ?T where T <: JoyBindable<T> {
        if (_httpContext.request.url.queryForm.isEmpty()) {
            return None
        }
        T.bind(_httpContext.request.url.queryForm)
    }

    /**
     *
     * bind the post form to a object of T
     *
     * @return the object of JoyBindable
     */
    public func bindPostForm<T>(): ?T where T <: JoyBindable<T> {
        if (_httpContext.request.form.isEmpty()) {
            return None
        }
        T.bind(_httpContext.request.form)
    }

    /**
     *
     * bind the header params to a object of T
     *
     * @return the object of JoyBindable
     */
    public func bindHeader<T>(): ?T where T <: JoyBindable<T> {
        if (_httpContext.request.headers.isEmpty()) {
            return None
        }
        T.bind(_httpContext.request.headers)
    }

    /**
     * bind the request json body content to a object of T
     *
     * @return the object of JsonDeserializable
     */
    public func bindJsonBody<T>(): ?T where T <: JsonDeserializable<T> {
        readJson<T>()
    }

    /**
     * reply response with serialized json body and status code
     *
     * @param status: the http status code
     * @param body: the object of T
     */
    public func json<T>(status: UInt16, body: T): Unit where T <: JsonSerializable {
        let buffer = ByteBuffer()
        let writer = JsonWriter(buffer)
        writer.writeValue(body)
        writer.flush()
        _httpContext
            .responseBuilder
            .status(status)
            .header("content-type", "application/json;charset=UTF-8")
            .body(buffer)
            .build()
    }

    /**
     * reply response with serialized json body and status code OK(200)
     *
     * @param body: the object of T
     */
    public func json<T>(body: T): Unit where T <: JsonSerializable {
        json(HttpStatusCode.STATUS_OK, body)
    }

    /**
     * reply response with json body and status code
     *
     * @param status: the http status code
     * @param body: the string body
     */
    public func json(status: UInt16, body: String): Unit {
        string(status, "application/json;charset=UTF-8", body)
    }

    /**
     * reply response with json body and and status code OK(200)
     *
     * @param status: the http status code
     * @param body: the string body
     */
    public func json(body: String): Unit {
        string(HttpStatusCode.STATUS_OK, "application/json;charset=UTF-8", body)
    }

    /**
     * reply response with the body of content type and status code
     *
     * @param contentType: the content type
     * @param status: the http status code
     * @param body: the string body
     */
    public func string(status: UInt16, contentType: String, body: String): Unit {
        _httpContext.responseBuilder.status(status).header("content-type", contentType).body(body).build()
    }

    /**
     * reply response with text plain body and status code
     *
     * @param status: the http status code
     * @param body: the string body
     */
    public func string(status: UInt16, body: String): Unit {
        string(status, "text/plain", body)
    }

    /**
     * reply response with text plain body and status code OK(200)
     *
     * @param status: the http status code
     * @param body: the string body
     */
    public func string(body: String): Unit {
        string(HttpStatusCode.STATUS_OK, "text/plain", body)
    }

    /**
     * reply response with the body of content type and status code
     *
     * @param contentType: the content type
     * @param status: the http status code
     * @param body: the bytes body
     */
    public func data(status: UInt16, contentType: String, body: Array<Byte>): Unit {
        _httpContext.responseBuilder.status(status).header("content-type", contentType).body(body).build()
    }

    /**
     * reply response with the body of content type and status code OK(200)
     *
     * @param contentType: the content type
     * @param body: the bytes body
     */
    public func data(contentType: String, body: Array<Byte>): Unit {
        data(HttpStatusCode.STATUS_OK, contentType, body)
    }

    /**
     * reply response with the body of content type and status code
     *
     * @param contentType: the content type
     * @param status: the http status code
     * @param body: the stream body
     */
    public func data(status: UInt16, contentType: String, body: InputStream): Unit {
        _httpContext.responseBuilder.status(status).header("content-type", contentType).body(body).build()
    }

    /**
     * reply response with the body of content type and status code OK(200)
     *
     * @param contentType: the content type
     * @param body: the stream body
     */
    public func data(contentType: String, body: InputStream): Unit {
        data(HttpStatusCode.STATUS_OK, contentType, body)
    }

    /**
     * get the real client ip
     *
     * @return the client ip
     */
    public func getClientIP(): String {
        for (x in _config.remoteIPHeaders) {
            let ip = readHeader(x).map({it => IPAddress.tryParse(it)}).map({it => it.toString()})
            if (ip.isSome()) {
                return ip.getOrThrow()
            }
        }
        getRemoteIP()
    }

    /**
     * get the connection remote ip
     *
     * @return the remote ip
     */
    public func getRemoteIP(): String {
        let remoteAddr = _httpContext.request.remoteAddr
        let ipPort = remoteAddr.split(":")
        if (ipPort.size >= 1) {
            return ipPort[0]
        }
        ""
    }

    /**
     * get the content type of body
     *
     * @return the content type
     */
    public func getContentType(): String {
        _httpContext.request.headers.getFirst("content-type").getOrDefault({=> ""})
    }

    /**
     * get the header first value
     *
     * @param name: the header name
     * @return the header value
     */
    public func readHeader(name: String): ?String {
        _httpContext.request.headers.getFirst(name)
    }

    /**
     * get the header values
     *
     * @param name: the header name
     * @return the header values
     */
    public func readHeaders(name: String): Collection<String> {
        _httpContext.request.headers.get(name)
    }

    /**
     * set the http code
     *
     * @param status: the the http code
     * @return the object of JoyContext
     */
    public func status(status: UInt16): JoyContext {
        _httpContext.responseBuilder.status(status)
        this
    }

    /**
     * reply OK(200) response
     */
    public func ok(): Unit {
        _httpContext.responseBuilder.status(HttpStatusCode.STATUS_OK).build()
    }

    /**
     * reply error response with status code
     *
     * @param status: the http status code
     *
     */
    public func error(status: UInt16): Unit {
        _httpContext.responseBuilder.status(status).build()
    }

    /**
     * reply success response with status code
     *
     * @param status: the http status code
     *
     */
    public func success(status: UInt16): Unit {
        _httpContext.responseBuilder.status(status).build()
    }

    /**
     * add a header to response
     *
     * @param name: the header name
     * @param value: the header value
     *
     */
    public func header(name: String, value: String): JoyContext {
        _httpContext.responseBuilder.header(name, value)
        this
    }

    /**
     * read a cookie value from request
     *
     * @param name: the header name
     * @return the cookie value
     *
     */
    public func readCookie(name: String): ?String {
        if (!_cookieCache.isEmpty()) {
            return _cookieCache.get(name)
        }

        let cookies = _httpContext.request.headers.get("cookie")
        for (c in cookies) {
            let arr = c.split(";")
            for (a in arr) {
                let kv = a.split("=")
                if (kv.size == 2) {
                    _cookieCache.add(kv[0].trimAscii(), kv[1].trimAscii())
                }
            }
        }
        _cookieCache.get(name)
    }

    /**
     * write a cookie value from request
     *
     * @param name: the header name
     * @return the cookie value
     *
     */
    public func cookie(cookie: Cookie): JoyContext {
        _httpContext.responseBuilder.header("Set-Cookie", cookie.toSetCookieString())
        this
    }

    /**
     * render the reponse body
     *
     * @param r: the render
     */
    public func render(r: JoyRender): Unit {
        r.render(_httpContext.responseBuilder)
    }

    /**
     * render the reponse body
     *
     * @param r: the render
     */
    public func render(r: (HttpResponseBuilder) -> Unit): Unit {
        this.render(JoyFuncRender(r))
    }

    /**
     * redirect to the new url with status code
     *
     * @param status: the http status code
     */
    public func redirect(status: UInt16, location: String): Unit {
        RedirectHandler(location, status).handle(_httpContext)
    }

    /**
     * reply response with status code 404
     *
     */
    public func notFound(): Unit {
        _config.notFoundHandler.handle(this)
    }

    /**
     * create a chunked writer
     */
    public func chunkedWriter(): JoyChunkedWriter {
        JoyChunkedWriter(_httpContext)
    }

    /**
     * create a SseEmitter
     */
    public func eventEmitter(): JoySseEmitter {
        JoySseEmitter(_httpContext)
    }
}
