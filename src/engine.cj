/*
 * Copyright (c) lanlingx 2024-2024. All rights resvered.
 */

package cjoy

import net.http.{Server, ServerBuilder}
import log.{LogLevel, Logger}
import logger.SimpleLogger
import std.console.Console

/**
 * joy config
 */
public class JoyConfig {
    public var remoteIPHeaders: Array<String> = []
    public var enableDebugLog: Bool = false
    public var caseInsensitive: Bool = false
    public var escapeAddedRoutes: Bool = false
    public var notFoundHandler: JoyRequestHandler = JoyNotFoundHandler()
    public var methodNotAllowedHandler: JoyRequestHandler = JoyMethodNotAllowedHandler()
    
    private var _logger: ?Logger = None

    mut prop logger: Logger {
        get() {
            if (_logger.isNone()) {
                _logger = Some(SimpleLogger(Console.stdOut))
            }
            return _logger.getOrThrow()
        }
        set(value) {
            _logger = Some(value)
        }
    }
}

/**
 * a wrapper for net.http.Server
 */
public class Joy {
    private var _server: ?Server = None
    private var _config: JoyConfig
    public let router: JoyRouters

    private init(config: JoyConfig) {
        _config = config
        router = JoyRouteGroup(config)
    }

    /**
     * create Joy engine instance by default config
     */
    public static func create(): Joy {
        create(JoyConfig())
    }

    /**
     * create Joy engine instance by config
     */
    public static func create(config: JoyConfig): Joy {
        Joy(config)
    }

    /**
     * run http server at address:port
     */
    public func run(addr: String, port: UInt16): Unit {
        run(ServerBuilder().addr(addr).port(port))
    }

    /**
     * run http server by ServerBuilder
     */
    public func run(serverBuidler: ServerBuilder): Unit {
        let server = serverBuidler.distributor(router.distributor).build()
        if (_config.enableDebugLog) {
            server.logger.level = LogLevel.DEBUG
        }
        _config.logger = server.logger
        _server = Some(server)
        _config.logger.debug("[Joy#run] route tree:\n${router.dump()}")
        server.serve()
    }

    /**
     * shutdown the server
     */
    public func shutdown(gracefully!: Bool = true) {
        if (let Some(server) <- _server) {
            if (gracefully) {
                server.closeGracefully()
            } else {
                server.close()
            }
        }
    }
}
