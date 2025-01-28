/*
 * Copyright (c) lanlingx 2024-present. All rights resvered.
 */

package cjoy

import std.io.ByteBuffer
import net.http.{HttpContext, HttpResponseWriter, HttpStatusCode}
import encoding.json.stream.{JsonDeserializable, JsonSerializable, JsonReader, JsonWriter}

public class ServerEventBuilder {
    private let _sb: StringBuilder = StringBuilder()

    public func event(event: String): ServerEventBuilder {
        _sb.append("event:")
        _sb.append(event)
        _sb.append("\n")
        this
    }

    public func id(id: String): ServerEventBuilder {
        _sb.append("id:")
        _sb.append(id)
        _sb.append("\n")
        this
    }

    public func data(data: String): ServerEventBuilder {
        _sb.append("data: ")
        _sb.append(data)
        _sb.append("\n")
        this
    }

    public func retry(retry: UInt): ServerEventBuilder {
        _sb.append("retry: ")
        _sb.append(retry)
        _sb.append("\n")
        this
    }

    public func comment(comment: String): ServerEventBuilder {
        _sb.append(": ")
        _sb.append(comment)
        _sb.append("\n")
        this
    }

    public func build(): String {
        if (_sb.size > 0) {
            _sb.append("\n")
        }
        _sb.toString()
    }
}

public open class ChunkedWriter {
    protected let _httpContext: HttpContext
    protected let _httpResponseWriter: HttpResponseWriter
    protected var _end = false
    protected var _chunkedNum = 0

    init(httpContext: HttpContext) {
        _httpContext = httpContext
        let responseBuilder = httpContext.responseBuilder
        responseBuilder.status(HttpStatusCode.STATUS_OK)
        responseBuilder.header("Transfer-Encoding", "chunked")
        responseBuilder.header("Connection", "keep-alive")
        responseBuilder.header("Trailer", "chunked-num")
        _httpResponseWriter = HttpResponseWriter(httpContext)
    }

    protected func checkEnd() {
        if (_end) {
            throw IllegalStateException("already end")
        }
    }

    public func end(): Unit {
        _end = true
        _httpContext.responseBuilder.trailer("chunked-num", "${_chunkedNum}")
    }
}

public class JoyChunkedWriter <: ChunkedWriter {
    init(httpContext: HttpContext) {
        super(httpContext)
    }

    public func write(data: String): JoyChunkedWriter {
        checkEnd()
        _httpResponseWriter.write(data.toArray())
        _chunkedNum += 1
        this
    }

    public func write(data: Array<Byte>): JoyChunkedWriter {
        checkEnd()
        _httpResponseWriter.write(data)
        _chunkedNum += 1
        this
    }

    public func writeJson<T>(data: T): JoyChunkedWriter where T <: JsonSerializable {
        let buffer = ByteBuffer()
        let writer = JsonWriter(buffer)
        writer.writeValue(data)
        writer.flush()
        write(buffer.bytes())
    }
}

public class JoySseEmitter <: ChunkedWriter {
    init(httpContext: HttpContext) {
        super(httpContext)
        let responseBuilder = httpContext.responseBuilder
        responseBuilder.header("Content-Type", "text/event-stream")
        responseBuilder.header("Cache-Control", "no-cache")
    }

    public func sendEvent(data: ServerEventBuilder): JoySseEmitter {
        checkEnd()
        _httpResponseWriter.write(data.build().toArray())
        _chunkedNum += 1
        this
    }
}
