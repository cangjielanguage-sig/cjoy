package cjoy

import std.collection.*
import net.http.{HttpContext, RedirectHandler}
import encoding.json.stream.{JsonDeserializable, JsonSerializable}

public class JoyContext {
    public let httpContxt: HttpContext
    private let config: JoyConfig

    public init(httpContxt: HttpContext, config: JoyConfig) {
        this.httpContxt = httpContxt
        this.config = config
    }
    
    public func fullPath(): String {
        ""
    }

    public func setCtxParam(key: String, value: Any): Unit {

    }

    public func getCtxParm<T>(key: String): ?T {
        Option<T>.None
    } 

    public func getParam(key: String): ?String  {
        Option<String>.None
    }

    public func addParam(key: String, value: String): Unit {

    }

    public func getQuery(key: String): ?String {
        this.httpContxt.request.url.queryForm.get(key)
    }

    public func getQuery(key: String, defaultValue: String): String {
        let val = this.httpContxt.request.url.queryForm.get(key)
        val.getOrDefault({=> defaultValue})
    }

    public func getQueryList(key: String): ArrayList<String> {
        this.httpContxt.request.url.queryForm.getAll(key)
    }

    public func getPostForm(key: String): ?String {
        this.httpContxt.request.form.get(key)
    }

    public func getPostForm(key: String, defaultValue: String): String{
        let val = this.httpContxt.request.form.get(key)
        val.getOrDefault({=> defaultValue})
    }

    public func getPostFormList(key: String): ArrayList<String>  {
        this.httpContxt.request.form.getAll(key)
    }

    public func readJsonBody<T>(): ?T where T <: JsonDeserializable<T> {
        Option<T>.None
    }

    public func readRawData(): Array<UInt8> {
        Array<UInt8>()
    }

    public func writeJson<T>(status: UInt16, body: T): Unit where T <: JsonSerializable{

    }

    public func writeJson<T>(body: T): Unit where T <: JsonSerializable{

    }

    public func writeStr(status: UInt16, str: String): Unit {

    }
    
    public func writeStr(str: String): Unit {
        
    }

    public func getClientIP(): String {
        ""
    }

    public func getRemoteIP(): String {
        let remoteAddr = this.httpContxt.request.remoteAddr
        let ipPort = remoteAddr.split(":")
        if (ipPort.size >=1) {
            return ipPort[0]
        }
        ""
    }

    public func getContentType(): String {
        ""
    }

    public func readHeader(key: String): ?String {
        Option<String>.None
    }

    public func writeStatus(status: UInt16): Unit {

    }

    public func writeHeader(key: String, value: String): Unit {

    }

    public func readCookie(name: String): ?String {
        Option<String>.None
    }

    public func writeCookie(name: String, value: String, maxAge: Int32, 
        path: String, domain: String, secure: Bool, httpOnly: Bool): Unit {

    }

    public func render(render: JoyRender): Unit {
        render.render(this.httpContxt.responseBuilder)
    }

    public func redirect(statusCode: UInt16, location: String): Unit {
         RedirectHandler(location, statusCode).handle(this.httpContxt)
    }
}


