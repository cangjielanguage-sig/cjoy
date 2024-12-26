/*
* Copyright (c) lanlingx 2024-2024. All rights resvered.
*/

package cjoy

import net.http.{Server, ServerBuilder}
import log.{LogLevel, Logger}
import logger.SimpleLogger
import std.console.Console

public class JoyConfig {
    public var redirectTrailingSlash: Bool = false
    public var remoteIPHeaders: Array<String> = []
    public var enableDebugLog: Bool = false
    public var caseInsensitive: Bool = false
    public var headCanUseGet: Bool = false
    public var escapeAddedRoutes: Bool = false
    private var _logger: ?Logger = None

    mut prop logger: Logger {
        get () {
            if (_logger.isNone()) {
                _logger = Some(SimpleLogger(Console.stdOut))
            }
            return _logger.getOrThrow()
        }
        set (value) {
            _logger = Some(value)
        }
    }
}

public class Joy {
    private var _server: ?Server = None
    private var _config: JoyConfig
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
            server.logger.level = LogLevel.DEBUG
        }
        _config.logger = server.logger
        _server = Some(server)
        server.serve()
    }
}