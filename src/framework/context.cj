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

/**
 * 上下文，包含引擎配置、参数、上下文参数以及任何你需要的其他内容。
 */
public interface JoyContext <: Context {
    /**
     * 获取底层的 HTTP 上下文
     *
     * @return HTTP 上下文
     */
    prop httpContext: HttpContext

    /**
     * 获取引擎配置
     *
     * @return 引擎配置
     */
    prop config: JoyConfig

    /**
     * 获取从请求 URL 中提取的路径参数
     *
     * @return 路径参数
     */
    prop params: HashMap<String, String>

    /**
     * 获取请求中的 cookies
     *
     * @return cookies
     */
    prop cookies: HashMap<String, String>

    /**
     * 获取 HTTP 请求方法 (GET, POST 等)
     *
     * @return HTTP 请求方法
     */
    prop method: String

    /**
     * 获取 HTTP 响应状态码
     *
     * @return HTTP 响应状态码
     */
    prop respStatus: UInt16

    /**
     * 获取 HTTP 响应体
     *
     * @return HTTP 响应体
     */
    prop respBody: String

    /**
     * 获取 HTTP 请求路径
     *
     * @return HTTP 请求路径
     */
    prop path: String

    /**
     * 获取完整的 HTTP 请求 URL
     *
     * @return 完整的 HTTP 请求 URL
     */
    prop url: URL

    /**
     * 在上下文中设置参数
     *
     * @param key 参数键名
     * @param value 参数值
     */
    func setCtxParam(key: String, value: Any): Unit {
        set(key, value)
    }

    /**
     * 从上下文中获取参数
     *
     * @param key 参数键名
     * @return 参数值
     */
    func getCtxParam<T>(key: String): ?T {
        get(key)
    }

    /**
     * 从上下文中获取 URL 路径参数
     *
     * @param name 参数名
     * @return 参数值
     */
    func getParam(name: String): ?String

    /**
     * 向上下文中添加 URL 路径参数
     *
     * @param name 参数名
     * @param value 参数值
     */
    func addParam(name: String, value: String): Unit

    /**
     * 从上下文中获取 URL 查询参数
     *
     * @param name 参数名
     * @return 参数值
     */
    func getQuery(name: String): ?String

    /**
     * 从上下文中获取 URL 查询参数（带默认值）
     *
     * @param name 参数名
     * @param defaultValue 如果参数不存在时的默认值
     * @return 参数值
     */
    func getQuery(name: String, defaultValue: String): String

    /**
     * 从上下文中获取 URL 查询参数的所有值
     *
     * @param name 参数名
     * @return 参数值列表
     */
    func getQueryList(name: String): ArrayList<String>

    /**
     * 从上下文中获取 POST form 参数
     *
     * @param name 参数名
     * @return 参数值
     */
    func getPostForm(name: String): ?String

    /**
     * 从上下文中获取 POST form 参数（带默认值）
     *
     * @param name 参数名
     * @param defaultValue 如果参数不存在时的默认值
     * @return 参数值
     */
    func getPostForm(name: String, defaultValue: String): String

    /**
     * 从上下文中获取 POST form 参数的所有值
     *
     * @param name 参数名
     * @return 参数值列表
     */
    func getPostFormList(name: String): ArrayList<String>

    /**
     * 从 POST form 或 URL 查询参数中获取参数
     *
     * @param name 参数名
     * @return 参数值
     */
    func getForm(name: String): ?String {
        getPostForm(name) ?? getQuery(name)
    }

    /**
     * 从 POST 表单或 URL 查询参数中获取参数（带默认值）
     *
     * @param name 参数名
     * @param defaultValue 参数不存在时的默认值
     * @return 参数值
     */
    func getForm(name: String, defaultValue: String): String {
        getForm(name) ?? defaultValue
    }

    /**
     * 从 POST 表单或 URL 查询参数中获取参数的所有值
     *
     * @param name 参数名
     * @return 参数值列表
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
     * 读取请求 JSON 体内容并反序列化为类型 T
     *
     * @return 反序列化后的类型 T 对象，或 None（如果反序列化失败）
     */
    func readJson<T>(): ?T where T <: JsonDeserializable<T>

    /**
     * 读取请求体内容到字节数组
     *
     * @return 请求体作为字节数组
     */
    func readRawData(): Array<Byte>

    /**
     * 读取请求体内容到字符串
     *
     * @return 请求体作为字符串
     */
    func readString(): String

    /**
     * 读取并绑定请求体内容到字符串
     *
     * @return 请求体作为字符串，或 None（如果无请求体）
     */
    func bindStringBody(): ?String

    /**
     * 读取并绑定查询参数到类型 T 的对象
     *
     * @return 绑定后的类型 T 对象，或 None（如果无查询参数）
     */
    func bindQuery<T>(): ?T where T <: JoyBindable<T>

    /**
     * 读取并绑定 POST 表单参数到类型 T 的对象
     *
     * @return 绑定后的类型 T 对象，或 None（如果无表单参数）
     */
    func bindPostForm<T>(): ?T where T <: JoyBindable<T>

    /**
     * 读取并绑定请求头参数到类型 T 的对象
     *
     * @return 绑定后的类型 T 对象，或 None（如果无请求头参数）
     */
    func bindHeader<T>(): ?T where T <: JoyBindable<T>

    /**
     * 绑定请求 JSON 体内容到类型 T 的对象
     *
     * @return 绑定后的类型 T 对象，或 None（如果绑定失败）
     */
    func bindJsonBody<T>(): ?T where T <: JsonDeserializable<T>

    /**
     * 使用序列化的 JSON 正文和状态码进行回复
     *
     * @param body T 类型对象
     * @return 当前 JoyContext 实例，便于链式调用
     */
    func json<T>(body: T): JoyContext where T <: JsonSerializable

    /**
     * 使用 JSON 正文和状态码进行回复
     *
     * @param body 字符串正文
     * @return 当前 JoyContext 实例，便于链式调用
     */
    func json(body: String): JoyContext

    /**
     * 使用指定内容类型和正文进行回复
     *
     * @param contentType 内容类型
     * @param body 字符串正文
     * @return 当前 JoyContext 实例，便于链式调用
     */
    func string(contentType: String, body: String): JoyContext

    /**
     * 使用文本/纯文本正文和 OK(200) 状态码进行回复
     *
     * @param body 字符串正文
     * @return 当前 JoyContext 实例，便于链式调用
     */
    func string(body: String): JoyContext

    /**
     * 使用文本/纯文本正文和 OK(200) 状态码进行回复
     *
     * @param body 字符串正文
     * @return 当前 JoyContext 实例，便于链式调用
     */
    func text(body: String): JoyContext

    /**
     * 使用 HTML 正文和 OK(200) 状态码进行回复
     *
     * @param body HTML 正文字符串
     * @return 当前 JoyContext 实例，便于链式调用
     */
    func html(body: String): JoyContext

    /**
     * 使用字节数组作为响应主体并设置内容类型和状态码
     *
     * @param body 字节数组正文
     * @return 当前 JoyContext 实例，便于链式调用
     */
    func data(body: Array<Byte>): JoyContext

    /**
     * 使用输入流作为数据字节正文进行回复
     *
     * @param body 输入流正文
     * @return 当前 JoyContext 实例，便于链式调用
     */
    func data(body: InputStream): JoyContext

    /**
     * 使用文件数据字节作为响应主体进行回复
     *
     * @param filePath 文件路径
     * @return 当前 JoyContext 实例，便于链式调用
     */
    func file(filePath: String): JoyContext

    /**
     * 将文件数据作为附件进行回复
     *
     * @param filePath 文件路径
     * @return 当前 JoyContext 实例，便于链式调用
     */
    func attachment(filePath: String): JoyContext

    /**
     * 设置内容类型
     *
     * @param contentType 内容类型
     * @return 当前 JoyContext 实例，便于链式调用
     */
    func contentType(contentType: String): JoyContext

    /**
     * 获取真实客户端IP地址，如果配置了代理头则考虑代理头
     *
     * @return 真实客户端IP地址
     */
    func getClientIP(): String

    /**
     * 从连接中获取远程IP地址
     *
     * @return 远程IP地址
     */
    func getRemoteIP(): String

    /**
     * 获取请求体的内容类型
     *
     * @return 内容类型
     */
    func getContentType(): String

    /**
     * 获取指定请求头的第一个值
     *
     * @param name 请求头名称
     * @return 请求头值
     */
    func getHeader(name: String): ?String

    /**
     * 获取指定请求头的所有值
     *
     * @param name 请求头名称
     * @return 请求头值的集合
     */
    func getHeaderList(name: String): Collection<String>

    /**
     * 设置响应的HTTP状态码
     *
     * @param status HTTP 状态码
     * @return 当前 JoyContext 实例，便于链式调用
     */
    func status(status: UInt16): JoyContext

    /**
     * 返回 OK(200) 响应
     *
     * @return 当前 JoyContext 实例，便于链式调用
     */
    func ok(): JoyContext

    /**
     * 向响应添加头信息
     *
     * @param name 头名称
     * @param value 头值
     * @return 当前 JoyContext 实例，便于链式调用
     */
    func header(name: String, value: String): JoyContext

    /**
     * 从请求读取 Cookie 值
     *
     * @param name Cookie 名称
     * @return Cookie 值
     */
    func getCookie(name: String): ?String

    /**
     * 将 Cookie 写入响应
     *
     * @param cookie Cookie 对象
     * @return 当前 JoyContext 实例，便于链式调用
     */
    func cookie(cookie: Cookie): JoyContext

    /**
     * 重定向到带有指定状态码的新 URL
     *
     * @param status HTTP 状态码
     * @param location 重定向位置 URL
     */
    func redirect(status: UInt16, location: String): Unit

    /**
     * 返回 404 Not Found 响应
     */
    func notFound(): Unit

    /**
     * 为流式响应创建分块写入器
     *
     * @return 分块写入器实例
     */
    func chunkedWriter(): JoyChunkedWriter

    /**
     * 创建一个服务器发送事件（SSE）发射器
     *
     * @return SSE 发射器实例
     */
    func eventEmitter(): JoySseEmitter

    /**
     * 从请求获取基础认证信息
     *
     * @return 包含用户名和密码的元组，若未提供或无效则返回 None
     */
    func basicAuth(): ?(String, String)

    /**
     * 按类型和名称获取请求参数
     *
     * @param typ 参数类型
     * @param name 参数名
     * @return 参数值
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
     * 按类型和名称获取请求参数
     *
     * @param typ 参数类型
     * @param name 参数名
     * @return 参数值
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

    public func bindStringBody(): ?String {
        copyRequestBody()
        if (_requestBuffer.length == 0) {
            return None
        }
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
     * 使用文本/纯文本正文和 OK(200) 状态码进行回复
     *
     * @param body 字符串正文
     */
    public func text(body: String): JoyContext {
        _respBody = body
        string(JoyHttpConsts.MIME_TEXT_PLAIN_UTF8, body)
        this
    }

    /**
     * 使用 HTML 正文和 OK(200) 状态码进行回复
     *
     * @param body HTML 正文字符串
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
                return ip ?? throw Exception("parse ip address failed")
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
     * 通过名称从服务容器获取服务
     *
     * @param name 服务名称
     * @return 服务实例，未找到时返回 None
     */
    public func getService<T>(name: String): ?T {
        _services.getService<T>(name)
    }

    private func getJoyFileHandlerFactory(): JoyFileHandlerFactory {
        BeanFactoryManager.getApplicationContext().getBean<JoyFileHandlerFactory>().getOrThrow()
    }
}
