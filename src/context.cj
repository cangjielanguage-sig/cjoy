package cjoy

import std.collection.*
import std.io.{ByteBuffer, copy}
import std.net.IPAddress
import net.http.{HttpContext, RedirectHandler, HttpStatusCode, HttpResponseBuilder, Cookie}
import encoding.json.stream.{JsonDeserializable, JsonSerializable, JsonReader, JsonWriter}

public class JoyContext {
    private let _httpContxt: HttpContext
    private let _config: JoyConfig
    private let _paramMap: HashMap<String, String>
    private let _ctxParamMap: HashMap<String, Any> = HashMap()
    private var _cookieCache: ?HashMap<String, String> = None

    public init(httpContxt: HttpContext, paramMap: HashMap<String, String>, config: JoyConfig) {
        _httpContxt = httpContxt
        _config = config
        _paramMap = paramMap
    }

    public prop httpContext: HttpContext {
        get() { _httpContxt }
    }
    
    public func setCtxParam(key: String, value: Any): Unit {
        _ctxParamMap.put(key, value)
    }

    public func getCtxParm<T>(key: String): ?T {
        let val = _ctxParamMap.get(key)
        match (val) {
            case Some(v) => v as T
            case _ => None
        }
    } 

    public func getParam(key: String): ?String  {
        _paramMap.get(key)
    }

    public func addParam(key: String, value: String): Unit {
        _paramMap.put(key, value)
    }

    public func getQuery(key: String): ?String {
        _httpContxt.request.url.queryForm.get(key)
    }

    public func getQuery(key: String, defaultValue: String): String {
        let val = _httpContxt.request.url.queryForm.get(key)
        val.getOrDefault({=> defaultValue})
    }

    public func getQueryList(key: String): ArrayList<String> {
        _httpContxt.request.url.queryForm.getAll(key)
    }

    public func getPostForm(key: String): ?String {
        _httpContxt.request.form.get(key)
    }

    public func getPostForm(key: String, defaultValue: String): String{
        let val = _httpContxt.request.form.get(key)
        val.getOrDefault({=> defaultValue})
    }

    public func getPostFormList(key: String): ArrayList<String>  {
        _httpContxt.request.form.getAll(key)
    }

    public func readJsonBody<T>(): ?T where T <: JsonDeserializable<T> {
        if (_httpContxt.request.bodySize.isSome() && _httpContxt.request.bodySize.getOrThrow() == 0) {
            return None
        }
        if (!getContentType().startsWith("application/json")) {
            return None
        }

        let buffer = ByteBuffer()
        copy(_httpContxt.request.body, to: buffer)
        let reader = JsonReader(buffer)
        T.fromJson(reader)
    }

    public func readRawData(): Array<UInt8> {
        let buffer = ByteBuffer()
        copy(_httpContxt.request.body, to: buffer)
        buffer.bytes()
    }

    public func writeJson<T>(status: UInt16, body: T): Unit where T <: JsonSerializable {
        let buffer = ByteBuffer()
        let writer = JsonWriter(buffer)
        writer.writeValue(body)
        writer.flush()
        _httpContxt.responseBuilder.status(status).
            header("content-type", "application/json;charset=UTF-8").
            body(buffer).build()
    }

    public func writeJson<T>(body: T): Unit where T <: JsonSerializable{
        writeJson(HttpStatusCode.STATUS_OK, body)
    }

    public func writeStr(status: UInt16, contentType: String, str: String): Unit {
        _httpContxt.responseBuilder.status(status).
            header("content-type", contentType).
            body(str).build()
    }

    public func writeStr(status: UInt16, str: String): Unit {
        writeStr(status, "text/plain", str)
    }
    
    public func writeStr(str: String): Unit {
        writeStr(HttpStatusCode.STATUS_OK, "text/plain", str)
    }

    public func getClientIP(): String {
        for (x in _config.remoteIPHeaders) {
            let ip = readHeader(x).map({it => IPAddress.tryParse(it)}).map({it => it.toString()})
            if (ip.isSome()) {
                return ip.getOrThrow()
            }
        }
        getRemoteIP()
    }

    public func getRemoteIP(): String {
        let remoteAddr = _httpContxt.request.remoteAddr
        let ipPort = remoteAddr.split(":")
        if (ipPort.size >=1) {
            return ipPort[0]
        }
        ""
    }

    public func getContentType(): String {
        _httpContxt.request.headers.getFirst("content-type").getOrDefault({=> ""})
    }

    public func readHeader(name: String): ?String {
        _httpContxt.request.headers.getFirst(name)
    }

    public func readHeaders(name: String): Collection<String> {
        _httpContxt.request.headers.get(name)
    }

    public func writeStatus(status: UInt16): Unit {
        _httpContxt.responseBuilder.status(status)
    }

    public func writeHeader(name: String, value: String): Unit {
        _httpContxt.responseBuilder.header(name, value)
    }

    public func readCookie(name: String): ?String {
        if (_cookieCache.isSome()) {
            return _cookieCache.getOrThrow().get(name)
        }

        let cache = HashMap<String, String>()
        let cookies = _httpContxt.request.headers.get("cookie")
        for (c in cookies) {
            let arr = c.split(";")
            for (a in arr) {
                let kv = a.split("=")
                if (kv.size == 2) {
                    cache.put(kv[0].trimAscii(), kv[1].trimAscii())
                }
            }
        }
        _cookieCache = Some(cache)
        cache.get(name)
    }

    public func writeCookie(cookie: Cookie): Unit {
        _httpContxt.responseBuilder.header("Set-Cookie", cookie.toSetCookieString())
    }

    public func render(r: JoyRender): Unit {
        r.render(_httpContxt.responseBuilder)
    }

    public func render(r: (HttpResponseBuilder) -> Unit): Unit {
        this.render(JoyFuncRender(r))
    }

    public func redirect(statusCode: UInt16, location: String): Unit {
         RedirectHandler(location, statusCode).handle(_httpContxt)
    }
}


