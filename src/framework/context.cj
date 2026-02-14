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

import std.collection.{HashMap, ArrayList}
import std.io.{InputStream, ByteBuffer, copy, StringReader, BufferedInputStream, SeekPosition}
import std.fs.{canonicalize, exists, Path}
import std.net.IPAddress
import stdx.net.http.{HttpContext, RedirectHandler, HttpStatusCode, HttpResponseBuilder, Cookie}
import stdx.encoding.url.URL
import stdx.encoding.json.stream.{JsonDeserializable, JsonSerializable, JsonReader, JsonWriter}
import stdx.encoding.base64.fromBase64String
import cjoy.bind.JoyBindable
import cjoy.context.{Context, ServiceContainer}
import cjoy.ioc.BeanFactoryManager
import cjoy.log.macros.*

/**
 * Context which holds the engine config, params, context params and any you need.
 */
public interface JoyContext <: Context {
    /**
     * Gets the underlying HTTP context
     *
     * @return The HTTP context
     */
    prop httpContext: HttpContext

    /**
     * Gets the engine configuration
     *
     * @return The engine configuration
     */
    prop config: JoyConfig

    /**
     * Gets the path parameters extracted from the request URL
     *
     * @return The path parameters
     */
    prop params: HashMap<String, String>

    /**
     * Gets the cookies from the request
     *
     * @return The cookies
     */
    prop cookies: HashMap<String, String>

    /**
     * Gets the HTTP request method (GET, POST, etc.)
     *
     * @return The HTTP request method
     */
    prop method: String

    /**
     * Gets the HTTP response status code
     *
     * @return The HTTP response status code
     */
    prop respStatus: UInt16

    /**
     * Gets the HTTP response body
     *
     * @return The HTTP response body
     */
    prop respBody: String

    /**
     * Gets the HTTP request path
     *
     * @return The HTTP request path
     */
    prop path: String

    /**
     * Gets the full HTTP request URL
     *
     * @return The full HTTP request URL
     */
    prop url: URL

    /**
     * Sets a parameter in the context
     *
     * @param key The parameter key name
     * @param value The parameter value
     */
    func setCtxParam(key: String, value: Any): Unit {
        set(key, value)
    }

    /**
     * Gets a parameter from the context
     *
     * @param key The parameter key name
     * @return The parameter value
     */
    func getCtxParam<T>(key: String): ?T {
        get(key)
    }

    /**
     * Gets a URL path parameter from the context
     *
     * @param name The parameter name
     * @return The parameter value
     */
    func getParam(name: String): ?String

    /**
     * Adds a URL path parameter to the context
     *
     * @param name The parameter name
     * @param value The parameter value
     */
    func addParam(name: String, value: String): Unit

    /**
     * Gets a URL query parameter from the context
     *
     * @param name The parameter name
     * @return The parameter value
     */
    func getQuery(name: String): ?String

    /**
     * Gets a URL query parameter from the context with default value
     *
     * @param name The parameter name
     * @param defaultValue The default value if parameter not exists
     * @return The parameter value
     */
    func getQuery(name: String, defaultValue: String): String

    /**
     * Gets all values of a URL query parameter from the context
     *
     * @param name The parameter name
     * @return The parameter value list
     */
    func getQueryList(name: String): ArrayList<String>

    /**
     * Gets a POST form parameter from the context
     *
     * @param name The parameter name
     * @return The parameter value
     */
    func getPostForm(name: String): ?String

    /**
     * Gets a POST form parameter from the context with default value
     *
     * @param name The parameter name
     * @param defaultValue The default value if parameter not exists
     * @return The parameter value
     */
    func getPostForm(name: String, defaultValue: String): String

    /**
     * Gets all values of a POST form parameter from the context
     *
     * @param name The parameter name
     * @return The parameter value list
     */
    func getPostFormList(name: String): ArrayList<String>

    /**
     * Gets a parameter from either POST form or URL query parameters
     *
     * @param name The parameter name
     * @return The parameter value
     */
    func getForm(name: String): ?String {
        getPostForm(name) ?? getQuery(name)
    }

    /**
     * Gets a parameter from either POST form or URL query parameters with default value
     *
     * @param name The parameter name
     * @param defaultValue The default value if parameter not exists
     * @return The parameter value
     */
    func getForm(name: String, defaultValue: String): String {
        getForm(name) ?? defaultValue
    }

    /**
     * Gets all values of a parameter from either POST form or URL query parameters
     *
     * @param name The parameter name
     * @return The parameter value list
     */
    func getFormList(name: String): ArrayList<String> {
        var res = getPostFormList(name)
        if (res.isEmpty()) {
            getQueryList(name)
        } else {
            res
        }
    }

    /**
     * Reads the request JSON body content and deserializes it to type T
     *
     * @return The deserialized object of type T, or None if deserialization fails
     */
    func readJson<T>(): ?T where T <: JsonDeserializable<T>

    /**
     * Reads the request body content into a byte array
     *
     * @return The request body as a byte array
     */
    func readRawData(): Array<Byte>

    /**
     * Reads the request body content into a string
     *
     * @return The request body as a string
     */
    func readString(): String

    /**
     * Reads and binds query parameters to an object of type T
     *
     * @return The bound object of type T, or None if no query parameters
     */
    func bindQuery<T>(): ?T where T <: JoyBindable<T>

    /**
     * Reads and binds POST form parameters to an object of type T
     *
     * @return The bound object of type T, or None if no form parameters
     */
    func bindPostForm<T>(): ?T where T <: JoyBindable<T>

    /**
     * Reads and binds header parameters to an object of type T
     *
     * @return The bound object of type T, or None if no header parameters
     */
    func bindHeader<T>(): ?T where T <: JoyBindable<T>

    /**
     * Binds the request JSON body content to an object of type T
     *
     * @return The bound object of type T, or None if binding fails
     */
    func bindJsonBody<T>(): ?T where T <: JsonDeserializable<T>

    /**
     * reply response with serialized json body and status code
     *
     * @param body the object of T
     * @return the current context instance for method chaining
     */
    func json<T>(body: T): JoyContext where T <: JsonSerializable

    /**
     * reply response with json body and status code
     *
     * @param body the string body
     * @return the current context instance for method chaining
     */
    func json(body: String): JoyContext

    /**
     * reply response with the body of content type and status code
     *
     * @param contentType the content type
     * @param body the string body
     * @return the current context instance for method chaining
     */
    func string(contentType: String, body: String): JoyContext

    /**
     * reply response with text plain body and status code OK(200)
     *
     * @param body the string body
     * @return the current context instance for method chaining
     */
    func string(body: String): JoyContext

    /**
     * reply response with text plain body and status code OK(200)
     *
     * @param body string body
     * @return the current context instance for method chaining
     */
    func text(body: String): JoyContext

    /**
     * reply response with html body and status code OK(200)
     *
     * @param body string body
     * @return the current context instance for method chaining
     */
    func html(body: String): JoyContext

    /**
     * reply response with the body of content type and status code
     *
     * @param body the bytes body
     * @return the current context instance for method chaining
     */
    func data(body: Array<Byte>): JoyContext

    /**
     * reply response with data bytes body
     *
     * @param body the stream body
     * @return the current context instance for method chaining
     */
    func data(body: InputStream): JoyContext

    /**
     * reply response with file data bytes body
     *
     * @param filePath the file path
     * @return the current context instance for method chaining
     */
    func file(filePath: String): JoyContext

    /**
     * reply response with file data bytes attachment
     *
     * @param filePath the file path
     * @return the current context instance for method chaining
     */
    func attachment(filePath: String): JoyContext

    /**
     * set the content type
     *
     * @param contentType the content type
     * @return the current context instance for method chaining
     */
    func contentType(contentType: String): JoyContext

    /**
     * Gets the real client IP address, considering proxy headers if configured
     *
     * @return The real client IP address
     */
    func getClientIP(): String

    /**
     * Gets the remote IP address from the connection
     *
     * @return The remote IP address
     */
    func getRemoteIP(): String

    /**
     * Gets the content type of the request body
     *
     * @return The content type
     */
    func getContentType(): String

    /**
     * Gets the first value of the specified request header
     *
     * @param name The header name
     * @return The header value
     */
    func getHeader(name: String): ?String

    /**
     * Gets all values of the specified request header
     *
     * @param name The header name
     * @return The header values
     */
    func getHeaderList(name: String): Collection<String>

    /**
     * Sets the HTTP status code for the response
     *
     * @param status The HTTP status code
     * @return The current JoyContext instance for method chaining
     */
    func status(status: UInt16): JoyContext

    /**
     * Replies with an OK(200) response
     *
     * @return The current JoyContext instance for method chaining
     */
    func ok(): JoyContext

    /**
     * Adds a header to the response
     *
     * @param name The header name
     * @param value The header value
     * @return The current JoyContext instance for method chaining
     */
    func header(name: String, value: String): JoyContext

    /**
     * Reads a cookie value from the request
     *
     * @param name The cookie name
     * @return The cookie value
     */
    func getCookie(name: String): ?String

    /**
     * Writes a cookie to the response
     *
     * @param cookie The cookie object
     * @return The current JoyContext instance for method chaining
     */
    func cookie(cookie: Cookie): JoyContext

    /**
     * Redirects to a new URL with the specified status code
     *
     * @param status The HTTP status code
     * @param location The redirect location URL
     */
    func redirect(status: UInt16, location: String): Unit

    /**
     * Replies with a 404 Not Found response
     */
    func notFound(): Unit

    /**
     * Creates a chunked writer for streaming responses
     *
     * @return The chunked writer instance
     */
    func chunkedWriter(): JoyChunkedWriter

    /**
     * Creates an SSE (Server-Sent Events) emitter
     *
     * @return The SSE emitter instance
     */
    func eventEmitter(): JoySseEmitter

    /**
     * Gets basic authentication information from the request
     *
     * @return The username and password tuple, or None if basic auth is not provided or invalid
     */
    func basicAuth(): ?(String, String)

    /**
     * Gets the request parameter by type and name
     *
     * @param type The parameter type
     * @param name The parameter name
     * @return The parameter value
     */
    func getRequestParam(typ: String, name: String): ?String {
        match (typ) {
            case "param" => getParam(name)
            case "path" => getParam(name)
            case "query" => getQuery(name)
            case "form" => getForm(name)
            case "cookie" => getCookie(name)
            case "header" => getHeader(name)
            case _ => None
        }
    }

    /**
     * Gets the request parameter by type and name
     *
     * @param type The parameter type
     * @param name The parameter name
     * @return The parameter value
     */
    func getRequestParam(typ: String, name: String, defaultValue: String): String {
        match (typ) {
            case "param" => getParam(name) ?? defaultValue
            case "path" => getParam(name) ?? defaultValue
            case "query" => getQuery(name, defaultValue)
            case "form" => getForm(name, defaultValue)
            case "cookie" => getCookie(name) ?? defaultValue
            case "header" => getHeader(name) ?? defaultValue
            case _ => defaultValue
        }
    }
}

class JoyHttpContext <: JoyContext {
    let _httpContext: HttpContext
    let _services: ServiceContainer
    private let _config: JoyConfig
    private let _paramMap: HashMap<String, String>
    private let _ctxParamMap: HashMap<String, Any>
    private let _requestBuffer: ByteBuffer = ByteBuffer()
    private var _cookieCache: HashMap<String, String> = HashMap()
    private var _parsedCookie: Bool = false
    private var _status: ?UInt16 = None
    private var _respBody: Any = Option<Any>.None
    private var _respContentType: ?String = None

    // the index of executing handler chain
    var _handleIndex: Int = 0

    init(services: ServiceContainer, httpContext: HttpContext, paramMap: HashMap<String, String>, config: JoyConfig,
        ctxParamMap: HashMap<String, Any>) {
        _services = services
        _httpContext = httpContext
        _config = config
        _paramMap = paramMap
        _ctxParamMap = ctxParamMap
    }

    /**
     * reset the context state
     */
    func reset(): Unit {
        _paramMap.clear()
        _ctxParamMap.clear()
        _cookieCache.clear()
        _requestBuffer.clear()
        _handleIndex = 0
        _respBody = Option<Any>.None
        _respContentType = None
    }

    /**
     * reset the handler chain index
     */
    func resetHandleIndex(): Unit {
        _handleIndex = 0
    }

    /**
     * increment and return the handler chain index
     *
     * @return the new handler chain index
     */
    func addHandleIndex(): Int {
        _handleIndex += 1
        _handleIndex
    }

    prop handleIndex: Int {
        get() {
            _handleIndex
        }
    }

    /**
     * copy the path params
     *
     * @return the cloned path params map
     */
    func copyParams(): HashMap<String, String> {
        _paramMap.clone()
    }

    /**
     * copy the context params
     *
     * @return the cloned context params map
     */
    func copyCtxParams(): HashMap<String, Any> {
        _ctxParamMap.clone()
    }

    public prop httpContext: HttpContext {
        get() {
            _httpContext
        }
    }

    public prop config: JoyConfig {
        get() {
            _config
        }
    }

    public prop params: HashMap<String, String> {
        get() {
            _paramMap
        }
    }

    public prop cookies: HashMap<String, String> {
        get() {
            if (_parsedCookie) {
                return _cookieCache
            }
            let cookies = _httpContext.request.headers.get(JoyHttpConsts.HEADER_COOKIE)
            for (c in cookies) {
                let arr = c.split(";")
                for (a in arr) {
                    let firstEq = a.indexOf(b'=') ?? 0
                    if (firstEq > 0) {
                        let key = a[0..firstEq].trimAscii()
                        let value = a[firstEq + 1..].trimAscii()
                        _cookieCache.add(key, value)
                    }
                }
            }
            _parsedCookie = true
            _cookieCache
        }
    }

    public prop method: String {
        get() {
            _httpContext.request.method
        }
    }

    public prop respStatus: UInt16 {
        get() {
            match (_status) {
                case Some(s) => s
                case _ => HttpStatusCode.STATUS_OK
            }
        }
    }

    public prop respBody: String {
        get() {
            match (_respBody) {
                case str: String => str
                case bytes: Array<Byte> => String.fromUtf8(bytes)
                case _ => ""
            }
        }
    }

    public prop path: String {
        get() {
            _httpContext.request.url.path
        }
    }

    public prop url: URL {
        get() {
            _httpContext.request.url
        }
    }

    public func set(key: String, value: Any): Unit {
        _ctxParamMap.add(key, value)
    }

    public func get<T>(key: String): ?T {
        (_ctxParamMap.get(key) ?? Option<Any>.None) as T
    }

    public func remove(key: String): Unit {
        _ctxParamMap.remove(key)
    }

    public func getParam(name: String): ?String {
        _paramMap.get(name)
    }

    public func addParam(name: String, value: String): Unit {
        _paramMap.add(name, value)
    }

    public func getQuery(name: String): ?String {
        _httpContext.request.url.queryForm.get(name)
    }

    public func getQuery(name: String, defaultValue: String): String {
        let val = _httpContext.request.url.queryForm.get(name)
        val ?? defaultValue
    }

    public func getQueryList(name: String): ArrayList<String> {
        _httpContext.request.url.queryForm.getAll(name)
    }

    public func getPostForm(name: String): ?String {
        _httpContext.request.form.get(name)
    }

    public func getPostForm(name: String, defaultValue: String): String {
        let val = _httpContext.request.form.get(name)
        val ?? defaultValue
    }

    public func getPostFormList(name: String): ArrayList<String> {
        _httpContext.request.form.getAll(name)
    }

    private func copyRequestBody(): Unit {
        if (let Some(len) <- _httpContext.request.bodySize && len > 0 && _requestBuffer.length == 0) {
            copy(_httpContext.request.body, to: _requestBuffer)
        }
    }

    public func readJson<T>(): ?T where T <: JsonDeserializable<T> {
        copyRequestBody()
        if (_requestBuffer.length == 0) {
            return None
        }
        if (!getContentType().startsWith(JoyHttpConsts.MIME_APP_JSON)) {
            return None
        }
        let buffer = BufferedInputStream(_requestBuffer)
        let reader = JsonReader(buffer)
        let res = T.fromJson(reader)
        _requestBuffer.seek(SeekPosition.Begin(0))
        res
    }

    public func readRawData(): Array<Byte> {
        copyRequestBody()
        _requestBuffer.bytes()
    }

    public func readString(): String {
        copyRequestBody()
        let reader = StringReader(BufferedInputStream(_requestBuffer))
        let res = reader.readToEnd()
        _requestBuffer.seek(SeekPosition.Begin(0))
        res
    }

    public func bindQuery<T>(): ?T where T <: JoyBindable<T> {
        if (_httpContext.request.url.queryForm.isEmpty()) {
            return None
        }
        T.bind(_httpContext.request.url.queryForm, "", None, None)
    }

    public func bindPostForm<T>(): ?T where T <: JoyBindable<T> {
        if (_httpContext.request.form.isEmpty()) {
            return None
        }
        T.bind(_httpContext.request.form, "", None, None)
    }

    public func bindHeader<T>(): ?T where T <: JoyBindable<T> {
        if (_httpContext.request.headers.isEmpty()) {
            return None
        }
        T.bind(_httpContext.request.headers, "", None, None)
    }

    public func bindJsonBody<T>(): ?T where T <: JsonDeserializable<T> {
        readJson<T>()
    }

    public func json<T>(body: T): JoyContext where T <: JsonSerializable {
        let buffer = ByteBuffer()
        let writer = JsonWriter(buffer)
        writer.writeValue(body)
        writer.flush()
        _respBody = buffer.bytes()
        _httpContext.responseBuilder.body(buffer)
        contentType(JoyHttpConsts.MIME_APP_JSON_UTF8)
        this
    }

    public func json(body: String): JoyContext {
        _respBody = body
        string(JoyHttpConsts.MIME_APP_JSON_UTF8, body)
        this
    }

    public func string(contentType: String, body: String): JoyContext {
        _respBody = body
        _httpContext.responseBuilder.body(body)
        this.contentType(contentType)
        this
    }

    public func string(body: String): JoyContext {
        _respBody = body
        string(JoyHttpConsts.MIME_TEXT_PLAIN_UTF8, body)
        this
    }

    /**
     * reply response with text plain body and status code OK(200)
     *
     * @param body string body
     */
    public func text(body: String): JoyContext {
        _respBody = body
        string(JoyHttpConsts.MIME_TEXT_PLAIN_UTF8, body)
        this
    }

    /**
     * reply response with html body and status code OK(200)
     *
     * @param body string body
     */
    public func html(body: String): JoyContext {
        _respBody = body
        string("text/html; charset=utf-8", body)
        this
    }

    public func data(body: Array<Byte>): JoyContext {
        _respBody = body
        _httpContext.responseBuilder.body(body)
        this
    }

    public func data(body: InputStream): JoyContext {
        let buffer = ByteBuffer()
        copy(body, to: buffer)
        let bytes = buffer.bytes()

        _respBody = bytes
        _httpContext.responseBuilder.body(bytes)
        this
    }

    public func file(filePath: String): JoyContext {
        let fp = canonicalize(filePath)
        if (!exists(fp)) {
            notFound()
        } else {
            let factory = getJoyFileHandlerFactory()
            factory.serveFile(this, Path(filePath))
        }
        this
    }

    public func attachment(filePath: String): JoyContext {
        let fp = canonicalize(filePath)
        if (!exists(fp)) {
            notFound()
        } else {
            let factory = getJoyFileHandlerFactory()
            factory.downloadFile(this, Path(filePath))
        }
        this
    }

    public func contentType(contentType: String): JoyContext {
        if (_respContentType.isNone()) {
            _respContentType = contentType
            _httpContext.responseBuilder.header(JoyHttpConsts.HEADER_CONTENT_TYPE, contentType)
        }
        this
    }

    public func getClientIP(): String {
        for (x in _config.remoteIPHeaders) {
            let ip = getHeader(x).map({it => IPAddress.tryParse(it)}).map({it => it.toString()})
            if (ip.isSome()) {
                return ip.getOrThrow()
            }
        }
        getRemoteIP()
    }

    public func getRemoteIP(): String {
        let remoteAddr = _httpContext.request.remoteAddr
        let ipPort = remoteAddr.split(":")
        if (ipPort.size >= 1) {
            return ipPort[0]
        }
        ""
    }

    public func getContentType(): String {
        _httpContext.request.headers.getFirst(JoyHttpConsts.HEADER_CONTENT_TYPE) ?? ""
    }

    public func getHeader(name: String): ?String {
        _httpContext.request.headers.getFirst(name)
    }

    public func getHeaderList(name: String): Collection<String> {
        _httpContext.request.headers.get(name)
    }

    public func status(status: UInt16): JoyContext {
        _httpContext.responseBuilder.status(status)
        _status = status
        this
    }

    public func ok(): JoyContext {
        status(HttpStatusCode.STATUS_OK)
    }

    public func header(name: String, value: String): JoyContext {
        _httpContext.responseBuilder.header(name, value)
        this
    }

    public func getCookie(name: String): ?String {
        this.cookies.get(name)
    }

    public func cookie(cookie: Cookie): JoyContext {
        _httpContext.responseBuilder.header(JoyHttpConsts.HEADER_SET_COOKIE, cookie.toSetCookieString())
        this
    }

    public func redirect(status: UInt16, location: String): Unit {
        RedirectHandler(location, status).handle(_httpContext)
    }

    public func notFound(): Unit {
        _config.notFoundHandler.handle(this)
    }

    public func chunkedWriter(): JoyChunkedWriter {
        JoyChunkedWriter(_httpContext)
    }

    public func eventEmitter(): JoySseEmitter {
        JoySseEmitter(_httpContext)
    }

    public func basicAuth(): ?(String, String) {
        let auth = getHeader(JoyHttpConsts.HEADER_AUTHORIZATION)
        if (auth.isNone()) {
            return None
        }

        let b64 = auth.getOrThrow().split(" ")
        if (b64.size != 2 || b64[0].trimAscii() != 'Basic') {
            return None
        }

        let decode = fromBase64String(b64[1])
        if (decode.isNone()) {
            return None
        }

        let upStr = String.fromUtf8(decode.getOrThrow())
        let up = upStr.split(":")
        if (up.size != 2) {
            return None
        }
        (up[0], up[1])
    }

    /**
     * get service by name from service container
     *
     * @param name the service name
     * @return: the service instance or None if not found
     */
    public func getService<T>(name: String): ?T {
        _services.getService<T>(name)
    }

    private func getJoyFileHandlerFactory(): JoyFileHandlerFactory {
        BeanFactoryManager.getApplicationContext().getBean<JoyFileHandlerFactory>().getOrThrow()
    }
}
