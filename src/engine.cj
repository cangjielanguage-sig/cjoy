package cjoy

import net.http.{Server, ServerBuilder}
import log.LogLevel

public struct JoyConfig {
    var redirectTrailingSlash: Bool = false
    var remoteIPHeaders: Array<String> = []
    var enableDebugLog: Bool = false
    var caseInsensitive: Bool = false
    var headCanUseGet: Bool = false
    var escapeAddedRoutes: Bool = false
}

public class Joy {
    private var _server: ?Server = None
    private let _config: JoyConfig
    public let router: JoyRouters

    init(config: JoyConfig) {
        _config = config
        router = JoyRouteGroup(config)
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
        let server = ServerBuilder().addr(addr).port(port).distributor(router.distributor).build()
        if (_config.enableDebugLog) {
            server.logger.enabled(LogLevel.DEBUG)
        }
        _server = Some(server)
        server.serve()
    }
}