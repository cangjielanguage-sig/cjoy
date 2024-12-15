package cjoy

import net.http.{Server, ServerBuilder}
import log.LogLevel

public struct JoyConfig {
    var redirectTrailingSlash: Bool = false
    var remoteIPHeaders: Array<String> = []
    var enableDebugLog: Bool = false
}

public class Joy {
    private var server: ?Server = None
    private let config: JoyConfig
    
    public let router: JoyRouters = JoyRouteGroup()

    init(config: JoyConfig) {
        this.config = config
    }

    public static func create(): Joy {
        create(JoyConfig())
    }
    
    public static func create(config: JoyConfig): Joy {
        Joy(config)
    }

    /**
    * run http server at address:port
    */
    public func run(addr: String, port: UInt16): Unit {
        let sr = ServerBuilder().addr(addr).port(port).build()
        if (config.enableDebugLog) {
            sr.logger.enabled(LogLevel.DEBUG)
        }
        this.server = Some(sr)
        sr.serve()
    }

    public func run(server: Server): Unit {
        this.server = Some(server)
        if (config.enableDebugLog && server.logger.level < LogLevel.DEBUG) {
            server.logger.enabled(LogLevel.DEBUG)
        }
        server.serve()
    } 
}